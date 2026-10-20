using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;

internal static class Setup
{
    private static int Main(string[] args)
    {
        bool checkOnly = args.Length == 1 && args[0] == "--check-only";
        if (args.Length != 0 && !checkOnly) return 2;
        Console.OutputEncoding = Encoding.UTF8;
        InstallerText text = null;
        string directory = null;
        var extracted = new List<string>();
        int result = 1;
        try
        {
            var assembly = Assembly.GetExecutingAssembly();
            text = new InstallerText(assembly, CultureInfo.CurrentUICulture);
            Console.WriteLine(text["SetupTitle"]);
            string[] names = assembly.GetManifestResourceNames();
            if (names.Length != 6) throw new InvalidDataException(text["UnexpectedResources"]);
            bool packageFound = false;
            foreach (string name in names)
            {
                if (Regex.IsMatch(name, @"\ABanpilot-\d+\.\d+\.\d+-x64\.msix\z"))
                {
                    if (packageFound) throw new InvalidDataException(text["MultiplePackages"]);
                    packageFound = true;
                }
                else if (name != "Install.ps1" && name != "build.json" && name != "Banpilot.cer" && name != "en-US.resw" && name != "ko-KR.resw")
                    throw new InvalidDataException(text["UnexpectedResources"]);
            }
            if (!packageFound) throw new InvalidDataException(text["MissingPackage"]);
            string candidate = Path.Combine(Path.GetTempPath(), "Banpilot-Setup-" + Guid.NewGuid().ToString("N"));
            if (Directory.Exists(candidate)) throw new IOException(text["TempExists"]);
            directory = candidate;
            Directory.CreateDirectory(directory);
            foreach (string name in names)
            {
                string destination = Path.Combine(directory, name);
                using (Stream source = assembly.GetManifestResourceStream(name))
                using (var target = new FileStream(destination, FileMode.CreateNew, FileAccess.Write))
                {
                    extracted.Add(destination);
                    source.CopyTo(target);
                }
            }
            Console.WriteLine(text[checkOnly ? "Checking" : "Installing"]);
            var start = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                    @"System32\WindowsPowerShell\v1.0\powershell.exe"),
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + Path.Combine(directory, "Install.ps1") +
                    "\" -ReleaseDirectory \"" + directory + "\"" + (checkOnly ? " -CheckOnly" : ""),
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };
            start.EnvironmentVariables["PSModulePath"] = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.Windows), @"System32\WindowsPowerShell\v1.0\Modules");
            using (Process process = Process.Start(start))
            {
                // Read both streams concurrently so a full error buffer cannot stall installation.
                var stdout = process.StandardOutput.ReadToEndAsync();
                var stderr = process.StandardError.ReadToEndAsync();
                process.WaitForExit();
                Console.Write(stdout.Result);
                Console.Error.Write(stderr.Result);
                result = process.ExitCode;
            }
            if (result == 0 && !checkOnly)
            {
                Console.WriteLine("\n" + text["Installed"]);
                Console.WriteLine("  " + text["NoOpDisplayName"]);
                Console.WriteLine("  " + text["WindowsKeyDisplayName"]);
                Console.WriteLine(text["RunOnce"]);
            }
            else if (result != 0) Console.Error.WriteLine(text["Failed"]);
        }
        catch (Exception error)
        {
            result = 1;
            Console.Error.WriteLine((text == null ? "Installation error: " : text["ErrorPrefix"]) + error.Message);
        }
        finally
        {
            // Delete only files created by this run, never recursively delete a temp tree.
            foreach (string file in extracted)
                try { File.Delete(file); } catch (IOException) { } catch (UnauthorizedAccessException) { }
            if (directory != null)
            {
                try { File.Delete(Path.Combine(directory, "certificate-trust.json")); }
                catch (IOException) { } catch (UnauthorizedAccessException) { }
                try { Directory.Delete(directory, false); }
                catch (IOException) { } catch (UnauthorizedAccessException) { }
            }
        }
        if (!checkOnly && !Console.IsInputRedirected)
        {
            Console.WriteLine("\n" + (text == null ? "Press Enter to close this window." : text["ClosePrompt"]));
            Console.ReadLine();
        }
        return result;
    }
}
