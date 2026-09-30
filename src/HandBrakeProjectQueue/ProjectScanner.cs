namespace HandBrakeProjectQueue;

internal sealed class ProjectScanner(AppSettings settings)
{
    public string ResolveEditingRoot()
    {
        if (!settings.EditingRoot.StartsWith("*:", StringComparison.Ordinal))
            return Directory.Exists(settings.EditingRoot) ? Path.GetFullPath(settings.EditingRoot) : throw new DirectoryNotFoundException(settings.EditingRoot);

        var tail = settings.EditingRoot[3..];
        foreach (var drive in DriveInfo.GetDrives())
        {
            try
            {
                if (!drive.IsReady) continue;
                var candidate = Path.Combine(drive.RootDirectory.FullName, tail);
                if (Directory.Exists(candidate)) return Path.GetFullPath(candidate);
            }
            catch { }
        }
        throw new DirectoryNotFoundException(settings.EditingRoot);
    }

    public async Task<List<ProjectItem>> ScanAsync(IProgress<(int done, int total, string name)> progress, CancellationToken token)
    {
        var root = ResolveEditingRoot();
        var dirs = Directory.GetDirectories(root);
        var result = new List<ProjectItem>();
        var extensions = settings.VideoExtensions.ToHashSet(StringComparer.OrdinalIgnoreCase);

        for (var i = 0; i < dirs.Length; i++)
        {
            token.ThrowIfCancellationRequested();
            var dir = dirs[i];
            var name = Path.GetFileName(dir);
            progress.Report((i, dirs.Length, name));
            var delivery = Path.Combine(dir, settings.DeliveryFolder);
            if (!Directory.Exists(delivery)) continue;

            var files = await Task.Run(() => Directory.EnumerateFiles(delivery)
                .Where(f => extensions.Contains(Path.GetExtension(f)) && !Path.GetFileName(f).EndsWith(settings.ConvertedSuffix, StringComparison.OrdinalIgnoreCase))
                .OrderBy(Path.GetFileName, StringComparer.CurrentCultureIgnoreCase)
                .Select(f =>
                {
                    var output = Path.Combine(delivery, Path.GetFileNameWithoutExtension(f) + settings.ConvertedSuffix);
                    return new VideoItem(Path.GetFileName(f), f, File.Exists(output));
                }).ToList(), token);

            result.Add(new ProjectItem(name, dir, files));
        }
        progress.Report((dirs.Length, dirs.Length, ""));
        return result.OrderByDescending(x => x.Name, StringComparer.CurrentCultureIgnoreCase).ToList();
    }
}
