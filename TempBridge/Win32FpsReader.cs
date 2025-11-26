using System.Management;

namespace TempBridge;

internal sealed class Win32FpsReader : IDisposable
{
    private const string Query = "SELECT FramesPerSecond FROM Win32_PerfFormattedData_DxgKrnl_GraphicsSubsystem";
    private readonly ManagementObjectSearcher _searcher;
    private readonly object _sync = new();
    private bool _disposed;

    private Win32FpsReader()
    {
        _searcher = new ManagementObjectSearcher("root\\CIMV2", Query);
    }

    public static Win32FpsReader? TryCreate(Action<string> logInfo, Action<string> logWarn)
    {
        try
        {
            var reader = new Win32FpsReader();
            var warmup = reader.ReadFps();
            if (warmup is null)
                logWarn("Windows graphics performance counters returned no FPS data (start a 3D app to activate).");
            else
                logInfo("Using Win32_PerfFormattedData_DxgKrnl_GraphicsSubsystem for FPS readings.");
            return reader;
        }
        catch (Exception ex)
        {
            logWarn($"FPS counter unavailable via Windows performance counters: {ex.Message}");
            return null;
        }
    }

    public float? ReadFps()
    {
        if (_disposed)
            return null;

        lock (_sync)
        {
            using var collection = _searcher.Get();
            foreach (ManagementObject obj in collection)
            {
                var raw = obj?["FramesPerSecond"];
                if (raw is null) continue;

                return raw switch
                {
                    uint u => u,
                    ulong ul => (float)ul,
                    int i => i,
                    long l => l,
                    double d => (float)d,
                    float f => f,
                    _ => null
                };
            }
        }

        return null;
    }

    public void Dispose()
    {
        if (_disposed)
            return;

        _disposed = true;
        _searcher.Dispose();
    }
}
