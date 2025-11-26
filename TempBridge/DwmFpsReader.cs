using System.Diagnostics;
using System.Globalization;
using System.Text;

namespace TempBridge;

internal sealed class DwmFpsReader : IDisposable
{
    private static readonly string[] CategoryCandidates =
    {
        "Desktop Window Manager",
        "Gerenciador de Janelas da Área de Trabalho"
    };

    private static readonly string[] CounterCandidates =
    {
        "Composed Frames/sec",
        "Rendered Frames/sec",
        "Displayed Frames/sec",
        "Quadros compostos/seg",
        "Quadros renderizados/seg",
        "Quadros exibidos/seg"
    };

    private readonly PerformanceCounter _counter;

    private DwmFpsReader(PerformanceCounter counter)
    {
        _counter = counter;
    }

    public static DwmFpsReader? TryStart(Action<string> logInfo, Action<string> logWarn)
    {
        var counter = TryCreateCounter(logWarn);
        if (counter is null)
        {
            logWarn("No Desktop Window Manager FPS counter available on this system.");
            return null;
        }

        logInfo($"Using {counter.CategoryName}/{counter.CounterName} for FPS readings.");
        return new DwmFpsReader(counter);
    }

    public float? CurrentFps
    {
        get
        {
            try
            {
                var value = _counter.NextValue();
                if (float.IsFinite(value) && value >= 0)
                    return value;
            }
            catch
            {
                // ignore transient counter issues
            }
            return null;
        }
    }

    public void Dispose()
    {
        _counter.Dispose();
    }

    private static PerformanceCounter? TryCreateCounter(Action<string> logWarn)
    {
        foreach (var category in CategoryCandidates)
        foreach (var counter in CounterCandidates)
        {
            var pc = CreateCounter(category, counter, null, logWarn);
            if (pc != null)
                return pc;
        }

        try
        {
            foreach (var category in PerformanceCounterCategory.GetCategories())
            {
                if (!CategoryMatches(category.CategoryName))
                    continue;

                if (category.CategoryType == PerformanceCounterCategoryType.MultiInstance)
                {
                    var instances = category.GetInstanceNames();
                    foreach (var instance in instances)
                    {
                        var counters = category.GetCounters(instance);
                        foreach (var counter in counters)
                        {
                            if (!CounterMatches(counter.CounterName))
                                continue;

                            var pc = CreateCounter(category.CategoryName, counter.CounterName, instance, logWarn);
                            if (pc != null)
                                return pc;
                        }
                    }
                }
                else
                {
                    var counters = category.GetCounters();
                    foreach (var counter in counters)
                    {
                        if (!CounterMatches(counter.CounterName))
                            continue;

                        var pc = CreateCounter(category.CategoryName, counter.CounterName, null, logWarn);
                        if (pc != null)
                            return pc;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            logWarn($"Failed to enumerate performance counters: {ex.Message}");
        }

        return null;
    }

    private static PerformanceCounter? CreateCounter(string category, string counter, string? instance, Action<string> logWarn)
    {
        try
        {
            return instance is null
                ? new PerformanceCounter(category, counter, true)
                : new PerformanceCounter(category, counter, instance, true);
        }
        catch (Exception ex)
        {
            logWarn($"Failed to access counter {category}/{counter}: {ex.Message}");
            return null;
        }
    }

    private static bool CategoryMatches(string categoryName)
    {
        var normalized = Normalize(categoryName);
        return normalized.Contains("DESKTOPWINDOWMANAGER") ||
               (normalized.Contains("GERENCIADOR") && normalized.Contains("JANEL")) ||
               normalized.Contains("DWM");
    }

    private static bool CounterMatches(string counterName)
    {
        var normalized = Normalize(counterName);
        var hasFrame = normalized.Contains("FRAME") || normalized.Contains("QUADR");
        var hasPerSecond = normalized.Contains("SEC") || normalized.Contains("SEG");
        return hasFrame && hasPerSecond;
    }

    private static string Normalize(string value)
    {
        var formD = value.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder(formD.Length);
        foreach (var ch in formD)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(ch);
            if (category == UnicodeCategory.NonSpacingMark)
                continue;
            if (char.IsLetterOrDigit(ch))
                sb.Append(char.ToUpperInvariant(ch));
        }
        return sb.ToString();
    }
}
