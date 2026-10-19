using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

internal static class WindowsKeyTapTests
{
    private sealed class FakeHost : WindowsKeyTap.IHost
    {
        internal long now;
        internal Func<long, bool> down = time => false;
        internal Func<long, bool> desktop = time => true;
        internal uint sendResult = 2;
        internal readonly List<WindowsKeyTap.Native.Input[]> sent = new List<WindowsKeyTap.Native.Input[]>();
        public long ElapsedMs { get { return now; } }
        public bool DesktopAvailable() { return desktop(now); }
        public bool SourceOrModifierDown() { return down(now); }
        public void Pause() { now += 10; }
        public uint Send(WindowsKeyTap.Native.Input[] inputs) { sent.Add(inputs); return sendResult; }
    }
    private static int passed;
    private static void Check(bool value, string message) { if (!value) throw new Exception(message); }
    private static void Test(string name, Action test) { test(); passed++; Console.WriteLine("PASS " + name); }
    private static int Main()
    {
        try
        {
            Test("x64 INPUT layout and RWin DOWN/UP packet", delegate {
                Check(IntPtr.Size == 8 && Marshal.SizeOf(typeof(WindowsKeyTap.Native.Input)) == 40, "Wrong x64 INPUT size");
                Check(Marshal.OffsetOf(typeof(WindowsKeyTap.Native.Input), "data").ToInt32() == 8, "Wrong union offset");
                var pair = WindowsKeyTap.Native.Tap();
                Check(pair.Length == 2 && pair[0].type == 1 && pair[1].type == 1, "Not a keyboard pair");
                Check(pair[0].data.keyboard.vk == 0x5C && pair[1].data.keyboard.vk == 0x5C, "Not RWin");
                Check(pair[0].data.keyboard.flags == 1 && pair[1].data.keyboard.flags == 3, "Wrong extended/up flags");
            });
            Test("idle emits exactly one pair after quiet interval", delegate {
                var h = new FakeHost();
                Check(WindowsKeyTap.Run(h, false) == 0 && h.now == 100 && h.sent.Count == 1, "Unexpected idle behavior");
            });
            Test("held source emits nothing until released", delegate {
                var h = new FakeHost { down = time => time < 2000 };
                Check(WindowsKeyTap.Run(h, false) == 0 && h.now == 2100 && h.sent.Count == 1, "Emitted before release");
            });
            Test("new press resets quiet interval", delegate {
                var h = new FakeHost { down = time => time < 100 || (time >= 150 && time < 200) };
                Check(WindowsKeyTap.Run(h, false) == 0 && h.now == 300, "Quiet interval not reset");
            });
            Test("held key times out without input", delegate {
                var h = new FakeHost { down = time => true };
                Check(WindowsKeyTap.Run(h, false) == 1 && h.now == 15000 && h.sent.Count == 0, "Timeout emitted input");
            });
            Test("unavailable desktop exits immediately", delegate {
                var h = new FakeHost { desktop = time => false };
                Check(WindowsKeyTap.Run(h, false) == 2 && h.now == 0 && h.sent.Count == 0, "Locked desktop not rejected");
            });
            Test("desktop change while waiting cancels input", delegate {
                var h = new FakeHost { desktop = time => time < 50 };
                Check(WindowsKeyTap.Run(h, false) == 2 && h.sent.Count == 0, "Desktop change not rejected");
            });
            Test("last-moment modifier press is rechecked", delegate {
                int callsAt100 = 0;
                var h = new FakeHost { down = time => time == 100 && ++callsAt100 == 2 };
                Check(WindowsKeyTap.Run(h, false) == 0 && h.now == 210 && h.sent.Count == 1, "Final modifier check missing");
            });
            Test("dry run never emits input", delegate {
                var h = new FakeHost();
                Check(WindowsKeyTap.Run(h, true) == 0 && h.sent.Count == 0, "Dry run emitted input");
            });
            Test("blocked injection does not retry DOWN", delegate {
                var h = new FakeHost { sendResult = 0 };
                Check(WindowsKeyTap.Run(h, false) == 3 && h.sent.Count == 1, "Blocked injection retried");
            });
            Test("partial injection attempts only RWin UP cleanup", delegate {
                var h = new FakeHost { sendResult = 1 };
                Check(WindowsKeyTap.Run(h, false) == 3 && h.sent.Count == 2, "Partial injection not handled");
                Check(h.sent[1].Length == 1 && h.sent[1][0].data.keyboard.vk == 0x5C && h.sent[1][0].data.keyboard.flags == 3, "Cleanup emitted wrong key");
            });
            Console.WriteLine(passed + " tests passed. No Windows input APIs were called.");
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex.Message); return 1; }
    }
}
