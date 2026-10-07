using System.Globalization;
using System.Resources;

namespace HandBrakeProjectQueue;

internal static class Strings
{
    private static readonly ResourceManager R = new("HandBrakeProjectQueue.Resources.Strings", typeof(Strings).Assembly);
    public static string Get(string key) => R.GetString(key, CultureInfo.CurrentUICulture) ?? key;
    public static void ApplyCulture(string language)
    {
        var culture = new CultureInfo(language);
        CultureInfo.CurrentUICulture = culture;
        CultureInfo.CurrentCulture = culture;
    }
}
