using System;
using System.Globalization;
using System.Reflection;

internal static class LocalizationTests
{
    private static int Main()
    {
        var assembly = Assembly.GetExecutingAssembly();
        foreach (string language in new[] { "ko-KR", "ko", "en-US", "en-GB", "ja-JP", "de-DE", "fr-FR", "zh-CN" })
        {
            var culture = CultureInfo.GetCultureInfo(language);
            var text = new InstallerText(assembly, culture);
            bool korean = language.StartsWith("ko");
            string expected = korean ? "Eventide's Banpilot - 아무 동작 안 함" : "Eventide's Banpilot - Do nothing";
            if (text["NoOpDisplayName"] != expected) throw new Exception("Wrong fallback for " + language);
            string failure = korean ? "앱 패키지의 해시가 일치하지 않습니다." : "Package hash mismatch.";
            if (text["HashMismatch"] != failure) throw new Exception("Wrong error language for " + language);
            Console.WriteLine("PASS installer language: " + language + " -> " + InstallerText.LanguageFor(culture));
        }
        // UI language must not follow the user's regional number/date formatting.
        CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("ko-KR");
        if (new InstallerText(assembly, CultureInfo.GetCultureInfo("en-US"))["SetupTitle"] != "Eventide's Banpilot Installer")
            throw new Exception("Regional culture changed UI language.");
        Console.WriteLine("PASS regional format is independent of UI language");
        return 0;
    }
}
