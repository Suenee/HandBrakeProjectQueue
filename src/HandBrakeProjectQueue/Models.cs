using System.Text.Json;

namespace HandBrakeProjectQueue;

internal sealed class AppSettings
{
    public string EditingRoot { get; set; } = @"*:\WORK\Sueneé Universe\EDITING";
    public string DeliveryFolder { get; set; } = "DELIVERY";
    public string ConvertedSuffix { get; set; } = "-conv.mp4";
    public string[] VideoExtensions { get; set; } = [".mp4", ".mov", ".mkv", ".m4v", ".avi", ".webm"];
    public string HandBrakePath { get; set; } = "";
    public string Language { get; set; } = "cs";
    public string Logging { get; set; } = "single";

    public static string ConfigPath => Path.Combine(AppContext.BaseDirectory, "config.local.json");

    public static AppSettings Load()
    {
        if (!File.Exists(ConfigPath)) return new AppSettings();
        return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(ConfigPath), JsonOptions()) ?? new AppSettings();
    }

    public void Save() => File.WriteAllText(ConfigPath, JsonSerializer.Serialize(this, JsonOptions()));
    private static JsonSerializerOptions JsonOptions() => new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase, WriteIndented = true };
}

internal sealed record VideoItem(string Name, string FullPath, bool Converted);
internal sealed record ProjectItem(string Name, string Path, IReadOnlyList<VideoItem> Files)
{
    public int PendingCount => Files.Count(x => !x.Converted);
}
