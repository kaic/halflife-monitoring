using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Text;
using LibreHardwareMonitor.Hardware;

namespace TempBridge;

internal static class Program
{
    private static readonly TimeSpan LoopDelay = TimeSpan.FromMilliseconds(300);
    private static readonly TimeSpan StatusLogInterval = TimeSpan.FromSeconds(10);
    private static readonly string BaseDirectory = AppContext.BaseDirectory;
    private static readonly string LogPath = Path.Combine(BaseDirectory, "tempbridge.log");
    private static readonly object LogSync = new();
    private static bool _cpuDebugShown = false;

    public static async Task Main()
    {
        Directory.SetCurrentDirectory(BaseDirectory);

        try
        {
            await Run().ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            var crashLog = Path.Combine(BaseDirectory, "crash.log");
            File.AppendAllText(crashLog, $"[{DateTime.Now}] FATAL ERROR: {ex}\n");
            LogError($"Fatal error: {ex}");
        }
    }

    private static async Task Run()
    {
        var overrideDocs = Environment.GetEnvironmentVariable("TEMPBRIDGE_DOCUMENTS");
        var documents = string.IsNullOrWhiteSpace(overrideDocs)
            ? Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
            : overrideDocs;
        var hwStatsPath = Path.Combine(documents, "Rainmeter", "Skins", "HalfLifeMonitoring", "@Resources", "hwstats.txt");

        var dir = Path.GetDirectoryName(hwStatsPath);
        if (!string.IsNullOrEmpty(dir))
            Directory.CreateDirectory(dir);

        PerformanceCounter? diskReadCounter = null;
        PerformanceCounter? diskWriteCounter = null;
        var useDiskCounters = false;

        try
        {
            diskReadCounter = new PerformanceCounter("PhysicalDisk", "Disk Read Bytes/sec", "_Total");
            diskWriteCounter = new PerformanceCounter("PhysicalDisk", "Disk Write Bytes/sec", "_Total");

            diskReadCounter.NextValue();
            diskWriteCounter.NextValue();

            useDiskCounters = true;
            LogInfo("Disk performance counters initialized.");
        }
        catch (Exception ex)
        {
            diskReadCounter?.Dispose();
            diskWriteCounter?.Dispose();
            diskReadCounter = null;
            diskWriteCounter = null;
            LogWarn($"Unable to initialize disk performance counters: {ex.Message}. Using LibreHardwareMonitor for disk throughput.");
        }

        var computer = new Computer
        {
            IsCpuEnabled = true,
            IsGpuEnabled = true,
            IsMemoryEnabled = false,
            IsMotherboardEnabled = true,
            IsNetworkEnabled = false,
            IsStorageEnabled = true,
            IsControllerEnabled = false
        };

        try
        {
            computer.Open();
            LogInfo($"TempBridge is writing metrics to {hwStatsPath}");

            var nextStatusLog = DateTime.UtcNow;

            while (true)
            {
                try
                {
                    var readings = ReadSensors(
                        computer,
                        includeStorageSensors: !useDiskCounters);

                    if (useDiskCounters && diskReadCounter != null && diskWriteCounter != null)
                    {
                        try
                        {
                            readings.DiskRead = diskReadCounter.NextValue() / 1048576f;
                            readings.DiskWrite = diskWriteCounter.NextValue() / 1048576f;
                        }
                        catch (Exception ex)
                        {
                            LogWarn($"Performance counters failed ({ex.Message}); switching to LibreHardwareMonitor.");
                            useDiskCounters = false;
                            diskReadCounter.Dispose();
                            diskWriteCounter.Dispose();
                            diskReadCounter = null;
                            diskWriteCounter = null;
                        }
                    }

                    WriteHwStats(hwStatsPath, readings);

                    if (DateTime.UtcNow >= nextStatusLog)
                    {
                        LogInfo(
                            $"CPU {readings.CpuUsage:F1}% ({readings.CpuTemp:F1}°C) | " +
                            $"GPU {readings.GpuUsage:F1}% ({readings.GpuTemp:F1}°C) | " +
                            $"Disk R:{readings.DiskRead:F1} W:{readings.DiskWrite:F1} MB/s");
                        nextStatusLog = DateTime.UtcNow + StatusLogInterval;
                    }
                }
                catch (Exception ex)
                {
                    LogError($"Read loop error: {ex.Message}");
                }

                await Task.Delay(LoopDelay).ConfigureAwait(false);
            }
        }
        finally
        {
            computer.Close();
            diskReadCounter?.Dispose();
            diskWriteCounter?.Dispose();
        }
    }

    private static (float? CpuTemp, float? GpuTemp, float? CpuUsage, float? GpuUsage, float? DiskRead, float? DiskWrite)
        ReadSensors(Computer computer, bool includeStorageSensors)
    {
        float? cpuTemp = null;
        float? gpuTemp = null;
        float? cpuUsage = null;
        float? gpuUsage = null;
        float? diskRead = null;
        float? diskWrite = null;

        foreach (var hardware in computer.Hardware)
        {
            if (!ShouldProcessHardware(hardware.HardwareType, includeStorageSensors))
                continue;

            hardware.Update();

            switch (hardware.HardwareType)
            {
                case HardwareType.Cpu:
                    (cpuTemp, cpuUsage) = ReadCpu(hardware, cpuTemp, cpuUsage);
                    break;

                case HardwareType.GpuNvidia:
                case HardwareType.GpuAmd:
                case HardwareType.GpuIntel:
                    (gpuTemp, gpuUsage) = ReadGpu(hardware, gpuTemp, gpuUsage);
                    break;

                case HardwareType.Storage:
                    (diskRead, diskWrite) = ReadDisk(hardware, diskRead, diskWrite);
                    break;

                case HardwareType.Motherboard:
                    if (cpuTemp is null)
                        cpuTemp = ReadMotherboardTemp(hardware);
                    break;
            }

            foreach (var sub in hardware.SubHardware)
            {
                sub.Update();
            }
        }

        return (cpuTemp, gpuTemp, cpuUsage, gpuUsage, diskRead, diskWrite);
    }

    private static bool ShouldProcessHardware(HardwareType type, bool includeStorageSensors) => type switch
    {
        HardwareType.Cpu => true,
        HardwareType.GpuNvidia => true,
        HardwareType.GpuAmd => true,
        HardwareType.GpuIntel => true,
        HardwareType.Motherboard => true,
        HardwareType.Storage => includeStorageSensors,
        _ => false
    };

    private static (float? Temp, float? Usage) ReadCpu(
        IHardware cpu,
        float? existingTemp,
        float? existingUsage)
    {
        float? temp = existingTemp;
        float? usage = existingUsage;

        float tempSum = 0f;
        int tempCount = 0;
        float loadSum = 0f;
        int loadCount = 0;

        if (!_cpuDebugShown && existingTemp is null && existingUsage is null)
        {
            LogInfo($"CPU Hardware: {cpu.Name}");
            LogInfo($"Total sensors: {cpu.Sensors.Length}");

            var sensorTypes = cpu.Sensors
                .GroupBy(s => s.SensorType)
                .Select(g => $"{g.Key}: {g.Count()}")
                .ToList();

            LogInfo($"Sensor types: {string.Join(", ", sensorTypes)}");
            _cpuDebugShown = true;
        }

        foreach (var sensor in cpu.Sensors)
        {
            if (sensor.Value is null) continue;

            switch (sensor.SensorType)
            {
                case SensorType.Temperature:
                    if (!_cpuDebugShown)
                    {
                        LogInfo($"CPU Temp Sensor: {sensor.Name} = {sensor.Value:F1}°C");
                    }

                    if (sensor.Name.Contains("Package", StringComparison.OrdinalIgnoreCase))
                    {
                        temp = sensor.Value;
                    }
                    else if (sensor.Name.Contains("Tctl", StringComparison.OrdinalIgnoreCase) ||
                             sensor.Name.Contains("Tdie", StringComparison.OrdinalIgnoreCase))
                    {
                        temp = sensor.Value;
                    }
                    else if (sensor.Name.Contains("Average", StringComparison.OrdinalIgnoreCase))
                    {
                        if (temp is null)
                            temp = sensor.Value;
                    }
                    else if (sensor.Name.Contains("Core", StringComparison.OrdinalIgnoreCase) ||
                             sensor.Name.Contains("CPU", StringComparison.OrdinalIgnoreCase))
                    {
                        tempSum += sensor.Value.Value;
                        tempCount++;
                    }
                    else
                    {
                        tempSum += sensor.Value.Value;
                        tempCount++;
                    }
                    break;

                case SensorType.Load:
                    if (sensor.Name.Contains("Total", StringComparison.OrdinalIgnoreCase) ||
                        sensor.Name.Contains("CPU Total", StringComparison.OrdinalIgnoreCase))
                    {
                        usage = sensor.Value;
                    }
                    else if (sensor.Name.Contains("Core", StringComparison.OrdinalIgnoreCase))
                    {
                        loadSum += sensor.Value.Value;
                        loadCount++;
                    }
                    break;
            }
        }

        if (temp is null && tempCount > 0)
        {
            temp = tempSum / tempCount;
            if (!_cpuDebugShown)
                LogInfo($"Using the average of {tempCount} sensors: {temp:F1}°C");
        }
        else if (temp is null && !_cpuDebugShown)
        {
            LogWarn("CPU temperature unavailable (sensor not exposed by the hardware)");
        }

        if (usage is null && loadCount > 0)
            usage = loadSum / loadCount;

        return (temp, usage);
    }

    private static (float? Temp, float? Usage) ReadGpu(
        IHardware gpu,
        float? existingTemp,
        float? existingUsage)
    {
        float? temp = existingTemp;
        float? usage = existingUsage;

        float tempSum = 0f;
        int tempCount = 0;
        float loadSum = 0f;
        int loadCount = 0;

        foreach (var sensor in gpu.Sensors)
        {
            if (sensor.Value is null) continue;

            switch (sensor.SensorType)
            {
                case SensorType.Temperature:
                    if (sensor.Name.Contains("Core", StringComparison.OrdinalIgnoreCase) ||
                        sensor.Name.Contains("GPU", StringComparison.OrdinalIgnoreCase))
                    {
                        temp = sensor.Value;
                    }
                    else
                    {
                        tempSum += sensor.Value.Value;
                        tempCount++;
                    }
                    break;

                case SensorType.Load:
                    if (sensor.Name.Contains("Core", StringComparison.OrdinalIgnoreCase) ||
                        sensor.Name.Contains("GPU", StringComparison.OrdinalIgnoreCase) ||
                        sensor.Name.Contains("D3D", StringComparison.OrdinalIgnoreCase))
                    {
                        usage = sensor.Value;
                    }
                    else
                    {
                        loadSum += sensor.Value.Value;
                        loadCount++;
                    }
                    break;

            }
        }

        if (temp is null && tempCount > 0)
            temp = tempSum / tempCount;

        if (usage is null && loadCount > 0)
            usage = loadSum / loadCount;

        return (temp, usage);
    }

    private static (float? Read, float? Write) ReadDisk(
        IHardware storage,
        float? existingRead,
        float? existingWrite)
    {
        float? read = existingRead;
        float? write = existingWrite;

        foreach (var sensor in storage.Sensors)
        {
            if (sensor.Value is null) continue;

            if (sensor.SensorType == SensorType.Throughput)
            {
                if (sensor.Name.Contains("Read", StringComparison.OrdinalIgnoreCase))
                {
                    read = (read ?? 0) + (sensor.Value.Value / 1048576f);
                }
                else if (sensor.Name.Contains("Write", StringComparison.OrdinalIgnoreCase))
                {
                    write = (write ?? 0) + (sensor.Value.Value / 1048576f);
                }
            }
        }

        return (read, write);
    }

    private static float? ReadMotherboardTemp(IHardware motherboard)
    {
        foreach (var sensor in motherboard.Sensors)
        {
            if (sensor.Value is null) continue;

            if (sensor.SensorType == SensorType.Temperature)
            {
                if (sensor.Name.Contains("System", StringComparison.OrdinalIgnoreCase) ||
                    sensor.Name.Contains("Motherboard", StringComparison.OrdinalIgnoreCase) ||
                    sensor.Name.Contains("Chipset", StringComparison.OrdinalIgnoreCase))
                {
                    LogInfo($"Using motherboard temperature: {sensor.Name} = {sensor.Value:F1}°C");
                    return sensor.Value;
                }
            }
        }
        return null;
    }

    private static void WriteHwStats(string path,
        (float? CpuTemp, float? GpuTemp, float? CpuUsage, float? GpuUsage, float? DiskRead, float? DiskWrite) r)
    {
        float cpuTemp = r.CpuTemp ?? 0;
        float gpuTemp = r.GpuTemp ?? 0;
        float cpuUsage = r.CpuUsage ?? 0;
        float gpuUsage = r.GpuUsage ?? 0;
        float diskRead = r.DiskRead ?? 0;
        float diskWrite = r.DiskWrite ?? 0;

        var sb = new StringBuilder(128);
        sb.AppendLine("CpuTemp=" + cpuTemp.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("GpuTemp=" + gpuTemp.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("CpuUsage=" + cpuUsage.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("GpuUsage=" + gpuUsage.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("DiskRead=" + diskRead.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("DiskWrite=" + diskWrite.ToString("F1", CultureInfo.InvariantCulture));

        File.WriteAllText(path, sb.ToString(), Encoding.UTF8);
    }

    private static void LogInfo(string message) => Log("INFO", message);

    private static void LogWarn(string message) => Log("WARN", message);

    private static void LogError(string message) => Log("ERROR", message);

    private static void Log(string level, string message)
    {
        try
        {
            var line = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {level} {message}";
            lock (LogSync)
            {
                File.AppendAllText(LogPath, line + Environment.NewLine, Encoding.UTF8);
            }
        }
        catch
        {
            // Logging should never crash the bridge
        }
    }
}
