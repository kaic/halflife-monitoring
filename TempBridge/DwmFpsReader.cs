using System.Diagnostics;

namespace TempBridge;

internal sealed class DwmFpsReader : IDisposable
{
    private static readonly string[] CounterCandidates = new[]
    {
        "Composed Frames/sec",
        "Rendered Frames/sec",
        "Displayed Frames/sec"
    };

    private readonly PerformanceCounter? _counter;

    private DwmFpsReader(PerformanceCounter counter)
    {
        _counter = counter;
    }

    public static DwmFpsReader? TryStart(Action<string> logInfo, Action<string> logWarn)
    {
        foreach (var counterName in CounterCandidates)
        {
            try
            {
                var counter = new PerformanceCounter("Desktop Window Manager", counterName, readOnly: true)
                {
                    MachineName = "."
                };

                // Prime counter
                _ = counter.NextValue();
                logInfo($"Using Desktop Window Manager/{counterName} for FPS readings.");
                return new DwmFpsReader(counter);
            }
            catch (Exception ex)
            {
                logWarn($"Failed to access DWM counter '{counterName}': {ex.Message}");
            }
        }

        logWarn("No Desktop Window Manager FPS counter available on this system.");
        return null;
    }

    public float? CurrentFps
    {
        get
        {
            if (_counter is null) return null;
            try
            {
                var value = _counter.NextValue();
                if (float.IsFinite(value) && value >= 0)
                    return value;
            }
            catch
            {
                // ignore
            }
            return null;
        }
    }

    public void Dispose()
    {
        _counter?.Dispose();
    }
}
