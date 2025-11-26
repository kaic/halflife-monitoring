using System.Collections.Concurrent;
using System.Diagnostics;
using Microsoft.Diagnostics.Tracing;
using Microsoft.Diagnostics.Tracing.Parsers;
using Microsoft.Diagnostics.Tracing.Session;

namespace TempBridge;

/// <summary>
/// Monitors FPS using ETW (Event Tracing for Windows) events from DXGI presentation.
/// Similar approach to Intel's PresentMon.
/// </summary>
public class FpsMonitor : IDisposable
{
    private TraceEventSession? _session;
    private Thread? _traceThread;
    private readonly ConcurrentDictionary<int, Queue<DateTime>> _processFrames = new();
    private readonly TimeSpan _fpsWindow = TimeSpan.FromSeconds(1);
    private volatile bool _isRunning;
    private readonly object _lockObj = new();

    public void Start()
    {
        if (_isRunning) return;

        _isRunning = true;
        _traceThread = new Thread(RunTrace)
        {
            Name = "FPS-ETW-Monitor",
            IsBackground = true,
            Priority = ThreadPriority.BelowNormal
        };
        _traceThread.Start();
    }

    public float? GetFps(int? targetProcessId = null)
    {
        if (!_isRunning) return null;

        // If no specific process, get FPS from the most active process in foreground
        if (targetProcessId == null)
        {
            var foregroundPid = GetForegroundProcessId();
            if (foregroundPid <= 0) return null;
            targetProcessId = foregroundPid;
        }

        if (!_processFrames.TryGetValue(targetProcessId.Value, out var frames))
            return null;

        lock (frames)
        {
            CleanOldFrames(frames);
            return frames.Count;
        }
    }

    private void RunTrace()
    {
        try
        {
            // Create ETW session (requires admin privileges)
            var sessionName = "TempBridge-FPS-Monitor";
            _session = new TraceEventSession(sessionName, TraceEventSessionOptions.Create);

            // Enable DXGI provider (this captures frame presentation events)
            _session.EnableProvider(
                "Microsoft-Windows-DXGI",
                TraceEventLevel.Informational,
                0x0000000000000001); // PresentStart keyword

            // Also enable DWM provider for additional frame data
            _session.EnableProvider(
                "Microsoft-Windows-Dwm-Core",
                TraceEventLevel.Verbose);

            _session.Source.Dynamic.All += data =>
            {
                if (!_isRunning) return;

                try
                {
                    // Look for Present events
                    if (data.ProviderName == "Microsoft-Windows-DXGI" &&
                        (data.EventName.Contains("Present") || data.OpcodeName == "Present"))
                    {
                        var processId = data.ProcessID;
                        if (processId <= 0) return;

                        var frames = _processFrames.GetOrAdd(processId, _ => new Queue<DateTime>());
                        
                        lock (frames)
                        {
                            frames.Enqueue(DateTime.UtcNow);
                            CleanOldFrames(frames);
                            
                            // Limit queue size to prevent memory issues
                            while (frames.Count > 500)
                                frames.Dequeue();
                        }
                    }
                }
                catch
                {
                    // Silently ignore parsing errors
                }
            };

            // Process events (blocking call)
            _session.Source.Process();
        }
        catch (UnauthorizedAccessException)
        {
            LogError("FPS Monitor requires administrator privileges to capture ETW events");
        }
        catch (Exception ex)
        {
            LogError($"FPS Monitor error: {ex.Message}");
        }
    }

    private void CleanOldFrames(Queue<DateTime> frames)
    {
        var cutoff = DateTime.UtcNow - _fpsWindow;
        while (frames.Count > 0 && frames.Peek() < cutoff)
        {
            frames.Dequeue();
        }
    }

    private static int GetForegroundProcessId()
    {
        try
        {
            var handle = GetForegroundWindow();
            if (handle == IntPtr.Zero) return -1;

            GetWindowThreadProcessId(handle, out var processId);
            return (int)processId;
        }
        catch
        {
            return -1;
        }
    }

    public void Dispose()
    {
        _isRunning = false;
        
        _session?.Dispose();
        _session = null;

        if (_traceThread != null && _traceThread.IsAlive)
        {
            _traceThread.Join(TimeSpan.FromSeconds(2));
        }
    }

    private static void LogError(string message)
    {
        try
        {
            var logPath = Path.Combine(AppContext.BaseDirectory, "tempbridge.log");
            File.AppendAllText(logPath, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] ERROR {message}\n");
        }
        catch
        {
            // Ignore logging errors
        }
    }

    #region Win32 Imports
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    #endregion
}
