using System.Diagnostics;

namespace HandBrakeProjectQueue;

internal sealed class HandBrakeService(AppSettings settings, AppLog log)
{
    public static string FindExecutable()
    {
        var candidates=new[]{Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),"HandBrake","HandBrake.exe"),Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),"HandBrake","HandBrake.exe"),Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Programs","HandBrake","HandBrake.exe")};
        return candidates.FirstOrDefault(File.Exists) ?? "";
    }
    public void OpenSources(IEnumerable<string> sources)
    {
        var exe=string.IsNullOrWhiteSpace(settings.HandBrakePath)?FindExecutable():settings.HandBrakePath;
        if(!File.Exists(exe)) throw new FileNotFoundException(Strings.Get("HandBrakeNotFound"),exe);
        foreach(var source in sources)
        {
            log.Write("HANDBRAKE",$"Open source: {source}");
            Process.Start(new ProcessStartInfo(exe){UseShellExecute=true,ArgumentList={source}});
        }
    }
}
