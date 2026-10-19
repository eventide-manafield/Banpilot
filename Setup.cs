using System;
using System.Collections.Generic;
using System.Diagnostics;
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
        Console.WriteLine("Eventide's Banpilot 설치 프로그램");
        string directory = null;
        var extracted = new List<string>();
        int result = 1;
        try
        {
            var assembly = Assembly.GetExecutingAssembly();
            string[] names = assembly.GetManifestResourceNames();
            if (names.Length != 4) throw new InvalidDataException("Unexpected installer resources.");
            bool packageFound = false;
            foreach (string name in names)
            {
                if (Regex.IsMatch(name, @"\ABanpilot-\d+\.\d+\.\d+-x64\.msix\z"))
                {
                    if (packageFound) throw new InvalidDataException("Multiple app packages.");
                    packageFound = true;
                }
                else if (name != "Install.ps1" && name != "build.json" && name != "Banpilot.cer")
                    throw new InvalidDataException("Unexpected installer resource.");
            }
            if (!packageFound) throw new InvalidDataException("Missing app package.");
            directory = Path.Combine(Path.GetTempPath(), "Banpilot-Setup-" + Guid.NewGuid().ToString("N"));
            if (Directory.Exists(directory)) throw new IOException("Temporary directory already exists.");
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
            Console.WriteLine(checkOnly ? "설치 파일을 검사하고 있어요. 앱을 설치하지 않습니다." :
                "설치 중입니다. 처음 설치할 때 인증서 등록을 위한 관리자 권한 요청이 나타날 수 있어요.");
            var start = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                    @"System32\WindowsPowerShell\v1.0\powershell.exe"),
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + Path.Combine(directory, "Install.ps1") +
                    "\" -ReleaseDirectory \"" + directory + "\"" + (checkOnly ? " -CheckOnly" : ""),
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
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
                Console.WriteLine("\n설치 완료! Windows 설정에서 'Copilot 키'를 검색한 뒤 원하는 앱을 선택해 주세요.");
                Console.WriteLine("  Eventide's Banpilot - 아무 동작 안 함");
                Console.WriteLine("  Eventide's Banpilot - Windows 키 한 번 누르기");
                Console.WriteLine("설치 프로그램은 매번 실행할 필요가 없습니다.");
            }
            else if (result != 0) Console.Error.WriteLine("설치를 완료하지 못했습니다. 위 오류를 확인해 주세요.");
        }
        catch (Exception error)
        {
            Console.Error.WriteLine("설치 오류: " + error.Message);
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
            Console.WriteLine("\nEnter를 누르면 창을 닫습니다.");
            Console.ReadLine();
        }
        return result;
    }
}
