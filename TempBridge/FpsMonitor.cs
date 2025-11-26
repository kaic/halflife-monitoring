using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Diagnostics.Tracing;
using Microsoft.Diagnostics.Tracing.Session;

namespace TempBridge;

internal sealed class FpsMonitor : IDisposable
{
    private static readonly Guid DxgKrnlProvider = new("802ec45a-1e99-4b83-9920-87c98277ba9d");

    private readonly CancellationTokenSource _cts = new();
    private readonly object _sync = new();
    private readonly Queue<double> _timestamps = new();
    private readonly Action<string> _logInfo;
    private readonly Action<string> _logWarn;
    private TraceEventSession? _session;
    private Task? _processingTask;
    private float _currentFps;
    private long _lastSampleTicks;

    private FpsMonitor(Action<string> logInfo, Action<string> logWarn)
    {
        _logInfo = logInfo;
        _logWarn = logWarn;
    }

    public static FpsMonitor? TryStart(Action<string> logInfo, Action<string> logWarn)
    {
        try
        {
            if (TraceEventSession.IsElevated() == false)
            {
                logWarn("FPS monitor requires elevated privileges; skipping.");
                return null;
            }

            var monitor = new FpsMonitor(logInfo, logWarn);
            monitor.Start();
            logInfo("FPS monitor initialized (DXGKrnl ETW).");
            return monitor;
        }
        catch (Exception ex)
        {
            logWarn($"Failed to start FPS monitor: {ex.Message}");
            return null;
        }
    }

    public float CurrentFps
    {
        get
        {
            var lastTicks = Interlocked.Read(ref _lastSampleTicks);
            if (lastTicks == 0)
                return 0f;

            var elapsed = TimeSpan.FromTicks(DateTime.UtcNow.Ticks - lastTicks);
            if (elapsed.TotalSeconds > 1.0)
                return 0f;

            return Volatile.Read(ref _currentFps);
        }
    }

    private void Start()
    {
        _processingTask = Task.Run(RunLoop);
    }

    private void RunLoop()
    {
        try
        {
            var sessionName = $"TempBridgeFps_{Process.GetCurrentProcess().Id}_{Guid.NewGuid():N}";
            using var session = new TraceEventSession(sessionName)
            {
                StopOnDispose = true
            };

            _session = session;
            session.EnableProvider(DxgKrnlProvider, TraceEventLevel.Informational, ulong.MaxValue);
            session.Source.AllEvents += OnTraceEvent;

            session.Source.Process();
        }
        catch (Exception ex)
        {
            if (!_cts.IsCancellationRequested)
                _logWarn($"FPS monitor stopped: {ex.Message}");
        }
    }

    private void OnTraceEvent(TraceEvent data)
    {
        if (_cts.IsCancellationRequested)
            return;

        if (!data.ProviderName.Equals("Microsoft-Windows-DxgKrnl", StringComparison.OrdinalIgnoreCase))
            return;

        if (!data.EventName.Equals("Present", StringComparison.OrdinalIgnoreCase))
            return;

        var now = data.TimeStampRelativeMSec;
        lock (_sync)
        {
            _timestamps.Enqueue(now);
            while (_timestamps.Count > 0 && now - _timestamps.Peek() > 1000d)
                _timestamps.Dequeue();

            _currentFps = _timestamps.Count;
            Interlocked.Exchange(ref _lastSampleTicks, DateTime.UtcNow.Ticks);
        }
    }

    public void Dispose()
    {
        _cts.Cancel();
        try
        {
            _session?.Dispose();
        }
        catch
        {
            // ignore
        }

        try
        {
            _processingTask?.Wait(2000);
        }
        catch
        {
            // ignore
        }
    }
}
