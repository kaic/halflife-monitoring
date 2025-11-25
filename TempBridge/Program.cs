using System.Globalization;
using System.Text;
using System.Diagnostics;
using LibreHardwareMonitor.Hardware;

namespace TempBridge;

internal static class Program
{
    private static readonly TimeSpan LoopDelay = TimeSpan.FromSeconds(1);
    private static bool _cpuDebugShown = false;

    public static async Task Main()
    {
        // Garante que o diretório de trabalho seja o do executável (fix para Task Scheduler)
        var exePath = AppDomain.CurrentDomain.BaseDirectory;
        Directory.SetCurrentDirectory(exePath);

        try
        {
            await Run();
        }
        catch (Exception ex)
        {
            var crashLog = Path.Combine(exePath, "crash.log");
            File.AppendAllText(crashLog, $"[{DateTime.Now}] FATAL ERROR: {ex}\n");
        }
    }

    private static async Task Run()
    {
        // Allow overriding Documents path (useful when running as SYSTEM via Task Scheduler)
        var overrideDocs = Environment.GetEnvironmentVariable("TEMPBRIDGE_DOCUMENTS");
        var documents = string.IsNullOrWhiteSpace(overrideDocs)
            ? Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
            : overrideDocs;
        var hwStatsPath = Path.Combine(
            documents,
            "Rainmeter",
            "Skins",
            "HalfLifeMonitoring",
            "@Resources",
            "hwstats.txt");

        var dir = Path.GetDirectoryName(hwStatsPath);
        if (!string.IsNullOrEmpty(dir))
            Directory.CreateDirectory(dir);

        var computer = new Computer
        {
            IsCpuEnabled = true,
            IsGpuEnabled = true,
            IsMemoryEnabled = false,
            IsMotherboardEnabled = true,  // Habilitado para ler temp da motherboard
            IsNetworkEnabled = false,
            IsStorageEnabled = true,  // Mantém habilitado (tentativa)
            IsControllerEnabled = false
        };

        // Performance Counters para Disco (fallback mais confiável)
        PerformanceCounter? diskReadCounter = null;
        PerformanceCounter? diskWriteCounter = null;

        try
        {
            diskReadCounter = new PerformanceCounter("PhysicalDisk", "Disk Read Bytes/sec", "_Total");
            diskWriteCounter = new PerformanceCounter("PhysicalDisk", "Disk Write Bytes/sec", "_Total");
            
            // Primeira leitura é sempre 0, então descartamos
            diskReadCounter.NextValue();
            diskWriteCounter.NextValue();
            
            Console.WriteLine("[OK] Performance Counters de disco inicializados");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WARN] Não foi possível inicializar Performance Counters: {ex.Message}");
            Console.WriteLine("[INFO] Disco será monitorado via LibreHardwareMonitor (pode não funcionar)");
        }

        try
        {
            computer.Open();

            Console.WriteLine("╔═══════════════════════════════════════╗");
            Console.WriteLine("║      TempBridge - HalfLife Monitor    ║");
            Console.WriteLine("╚═══════════════════════════════════════╝");
            Console.WriteLine();
            Console.WriteLine($"Escrevendo em: {hwStatsPath}");
            Console.WriteLine("Feche esta janela para encerrar.");
            Console.WriteLine();

            while (true)
            {
                try
                {
                    var readings = ReadSensors(computer);

                    // Se Performance Counters estiverem disponíveis, usa eles para disco
                    if (diskReadCounter != null && diskWriteCounter != null)
                    {
                        try
                        {
                            float diskReadBytes = diskReadCounter.NextValue();
                            float diskWriteBytes = diskWriteCounter.NextValue();
                            
                            // Converte para MB/s
                            readings.DiskRead = diskReadBytes / 1048576f;
                            readings.DiskWrite = diskWriteBytes / 1048576f;
                        }
                        catch
                        {
                            // Se falhar, mantém os valores do LibreHardwareMonitor (ou 0)
                        }
                    }

                    WriteHwStats(hwStatsPath, readings);

                    // Log a cada 10 segundos para não poluir o console
                    if (DateTime.Now.Second % 10 == 0)
                    {
                        Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] " +
                            $"CPU: {readings.CpuUsage:F1}% ({readings.CpuTemp:F1}°C) | " +
                            $"GPU: {readings.GpuUsage:F1}% ({readings.GpuTemp:F1}°C) | " +
                            $"Disk: R:{readings.DiskRead:F1} W:{readings.DiskWrite:F1} MB/s");
                    }
                }
                catch (Exception ex)
                {
                    // Não derruba o loop por causa de um erro
                    Console.Error.WriteLine($"[ERRO] {ex.Message}");
                }

                await Task.Delay(LoopDelay);
            }
        }
        finally
        {
            computer.Close();
        }
    }

    private static (float? CpuTemp, float? GpuTemp, float? CpuUsage, float? GpuUsage, float? DiskRead, float? DiskWrite)
        ReadSensors(Computer computer)
    {
        float? cpuTemp = null;
        float? gpuTemp = null;
        float? cpuUsage = null;
        float? gpuUsage = null;
        float? diskRead = null;
        float? diskWrite = null;

        foreach (var hardware in computer.Hardware)
        {
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
                    // Se não temos CPU temp, tenta usar motherboard temp
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

    private static (float? Temp, float? Usage) ReadCpu(
        IHardware cpu,
        float? existingTemp,
        float? existingUsage)
    {
        float? temp = existingTemp;
        float? usage = existingUsage;

        var tempValues = new List<float>();
        var loadValues = new List<float>();

        // Debug COMPLETO: mostra informações da CPU e tipos de sensores apenas na PRIMEIRA vez
        if (!_cpuDebugShown && existingTemp is null && existingUsage is null)
        {
            Console.WriteLine($"[DEBUG] CPU Hardware: {cpu.Name}");
            Console.WriteLine($"[DEBUG] Total sensors: {cpu.Sensors.Length}");
            
            // Mostra contagem por tipo
            var sensorTypes = cpu.Sensors
                .GroupBy(s => s.SensorType)
                .Select(g => $"{g.Key}: {g.Count()}")
                .ToList();
            
            Console.WriteLine($"[DEBUG] Sensor types: {string.Join(", ", sensorTypes)}");
            _cpuDebugShown = true; // Não repete mais
        }

        foreach (var sensor in cpu.Sensors)
        {
            if (sensor.Value is null) continue;

            switch (sensor.SensorType)
            {
                case SensorType.Temperature:
                    // Debug: mostra sensores de temperatura encontrados
                    if (!_cpuDebugShown)
                    {
                        Console.WriteLine($"[DEBUG] CPU Temp Sensor: {sensor.Name} = {sensor.Value:F1}°C");
                    }

                    // Preferência por ordem: Package > Tctl/Tdie (AMD) > Core Average > qualquer temperatura
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
                        tempValues.Add(sensor.Value.Value);
                    }
                    else
                    {
                        // Qualquer outro sensor de temperatura como último recurso
                        tempValues.Add(sensor.Value.Value);
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
                        loadValues.Add(sensor.Value.Value);
                    }
                    break;
            }
        }

        // Fallback para média se não encontrou um sensor preferido
        if (temp is null && tempValues.Count > 0)
        {
            temp = tempValues.Average();
            if (!_cpuDebugShown)
                Console.WriteLine($"[INFO] Usando média de {tempValues.Count} sensores: {temp:F1}°C");
        }
        else if (temp is null && !_cpuDebugShown)
        {
            Console.WriteLine("[WARN] Temperatura de CPU não disponível (sensor não exposto pelo hardware)");
        }

        if (usage is null && loadValues.Count > 0)
            usage = loadValues.Average();

        return (temp, usage);
    }

    private static (float? Temp, float? Usage) ReadGpu(
        IHardware gpu,
        float? existingTemp,
        float? existingUsage)
    {
        float? temp = existingTemp;
        float? usage = existingUsage;

        var tempValues = new List<float>();
        var loadValues = new List<float>();

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
                        tempValues.Add(sensor.Value.Value);
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
                        loadValues.Add(sensor.Value.Value);
                    }
                    break;
            }
        }

        // Fallback para média
        if (temp is null && tempValues.Count > 0)
            temp = tempValues.Average();

        if (usage is null && loadValues.Count > 0)
            usage = loadValues.Average();

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
                    // Converte de B/s para MB/s
                    read = (read ?? 0) + (sensor.Value.Value / 1048576f);
                }
                else if (sensor.Name.Contains("Write", StringComparison.OrdinalIgnoreCase))
                {
                    // Converte de B/s para MB/s
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
                // Tenta pegar temperatura do chipset ou sistema
                if (sensor.Name.Contains("System", StringComparison.OrdinalIgnoreCase) ||
                    sensor.Name.Contains("Motherboard", StringComparison.OrdinalIgnoreCase) ||
                    sensor.Name.Contains("Chipset", StringComparison.OrdinalIgnoreCase))
                {
                    Console.WriteLine($"[INFO] Usando temperatura da motherboard: {sensor.Name} = {sensor.Value:F1}°C");
                    return sensor.Value;
                }
            }
        }
        return null;
    }

    private static void WriteHwStats(string path,
        (float? CpuTemp, float? GpuTemp, float? CpuUsage, float? GpuUsage, float? DiskRead, float? DiskWrite) r)
    {
        // Se algum valor vier nulo, joga 0 para não quebrar a skin
        float cpuTemp = r.CpuTemp ?? 0;
        float gpuTemp = r.GpuTemp ?? 0;
        float cpuUsage = r.CpuUsage ?? 0;
        float gpuUsage = r.GpuUsage ?? 0;
        float diskRead = r.DiskRead ?? 0;
        float diskWrite = r.DiskWrite ?? 0;

        var sb = new StringBuilder();
        sb.AppendLine("CpuTemp=" + cpuTemp.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("GpuTemp=" + gpuTemp.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("CpuUsage=" + cpuUsage.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("GpuUsage=" + gpuUsage.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("DiskRead=" + diskRead.ToString("F1", CultureInfo.InvariantCulture));
        sb.AppendLine("DiskWrite=" + diskWrite.ToString("F1", CultureInfo.InvariantCulture));

        File.WriteAllText(path, sb.ToString(), Encoding.UTF8);
    }
}
