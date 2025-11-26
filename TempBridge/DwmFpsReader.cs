using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using Vanara.PInvoke;

namespace TempBridge;

internal sealed class DwmFpsReader : IDisposable
{
    private readonly CancellationTokenSource _cts = new();
    private readonly Task _loopTask;
    private double _currentFps;
    private ulong _lastFrames;
    private ulong? _lastQpcFrame;

    private DwmFpsReader()
    {
        _loopTask = Task.Run(RunLoop);
    }

    public static DwmFpsReader? TryStart(Action<string> logInfo, Action<string> logWarn)
    {
        try
        {
            if (DwmApi.DwmIsCompositionEnabled(out var enabled).Failed || !enabled)
            {
                logWarn("DWM composition disabled; FPS readings unavailable.");
                return null;
            }

            var reader = new DwmFpsReader();
            logInfo("Using DwmGetCompositionTimingInfo for FPS readings.");
            return reader;
        }
        catch (DllNotFoundException ex)
        {
            logWarn($"DWM API not available: {ex.Message}");
            return null;
        }
        catch (Exception ex)
        {
            logWarn($"Failed to initialize DWM FPS reader: {ex.Message}");
            return null;
        }
    }

    public float? CurrentFps => (float)Volatile.Read(ref _currentFps);

    private async Task RunLoop()
    {
        var freq = Stopwatch.Frequency;

        while (!_cts.IsCancellationRequested)
        {
            try
            {
                var timing = DwmApi.DWM_TIMING_INFO.Default;
                if (DwmApi.DwmGetCompositionTimingInfo(IntPtr.Zero, ref timing).Succeeded)
                {
                    var frames = timing.cFramesDisplayed;
                    var qpcFrame = timing.qpcFrameDisplayed;

                    if (_lastQpcFrame.HasValue && qpcFrame > _lastQpcFrame.Value && frames > _lastFrames)
                    {
                        var seconds = (qpcFrame - _lastQpcFrame.Value) / (double)freq;
                        if (seconds > 0.01)
                        {
                            var fps = (frames - _lastFrames) / seconds;
                            Volatile.Write(ref _currentFps, fps);
                        }
                    }

                    _lastFrames = frames;
                    _lastQpcFrame = qpcFrame;
                }
            }
            catch
            {
                // ignored
            }

            try
            {
                await Task.Delay(500, _cts.Token).ConfigureAwait(false);
            }
            catch (TaskCanceledException)
            {
                break;
            }
        }
    }

    public void Dispose()
    {
        _cts.Cancel();
        try
        {
            _loopTask.Wait(1500);
        }
        catch
        {
            // ignore
        }
        _cts.Dispose();
    }
}
