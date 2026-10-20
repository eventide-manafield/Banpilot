using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Xml;

internal sealed class InstallerText
{
    private readonly Dictionary<string, string> values = new Dictionary<string, string>();

    internal static string LanguageFor(CultureInfo culture)
    {
        return culture.TwoLetterISOLanguageName == "ko" ? "ko-KR" : "en-US";
    }

    internal InstallerText(Assembly assembly, CultureInfo culture)
    {
        using (Stream stream = assembly.GetManifestResourceStream(LanguageFor(culture) + ".resw"))
        {
            if (stream == null) throw new InvalidDataException("Installer language resources are missing.");
            var document = new XmlDocument { XmlResolver = null };
            document.Load(stream);
            foreach (XmlElement item in document.SelectNodes("/root/data"))
                values.Add(item.GetAttribute("name"), item["value"].InnerText);
        }
    }

    internal string this[string key] { get { return values[key]; } }
}
