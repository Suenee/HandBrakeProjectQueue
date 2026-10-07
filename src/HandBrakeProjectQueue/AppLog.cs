namespace HandBrakeProjectQueue;

internal sealed class AppLog : IDisposable
{
    private readonly string mode;
    private readonly string? path;
    private readonly object gate = new();

    public AppLog(string configuredMode)
    {
        mode = configuredMode.ToLowerInvariant();
        if (mode == "off") return;
        var dir = Path.Combine(AppContext.BaseDirectory, "logs");
        Directory.CreateDirectory(dir);
        path = Path.Combine(dir, mode == "all" ? "application.log" : "application-single.log");
        if (mode == "single") File.WriteAllText(path, "");
        Write("START", $"Application started; logging={mode}");
    }
    public void Write(string area, string message)
    {
        if (path is null) return;
        lock (gate) File.AppendAllText(path, $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} [{area}] {message}{Environment.NewLine}");
    }
    public void Dispose() => Write("STOP", "Application stopped");
}
