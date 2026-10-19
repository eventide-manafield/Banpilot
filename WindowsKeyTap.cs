using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

// Invoked on demand; no hook, startup entry, file logging, or network access.
internal static class WindowsKeyTap
{
    internal const int TimeoutMs = 15000;
    internal const int QuietMs = 100;

    internal interface IHost
    {
        long ElapsedMs { get; }
        bool DesktopAvailable();
        bool SourceOrModifierDown();
        void Pause();
        uint Send(Native.Input[] inputs);
    }

    // Exit codes: 0 success/dry run, 1 timeout, 2 desktop unavailable,
    // 3 injection failed, 4 overlapping invocation, 5 invalid args/runtime error.
    internal static int Run(IHost host, bool dryRun)
    {
        long releasedSince = -1;
        while (host.ElapsedMs < TimeoutMs)
        {
            if (!host.DesktopAvailable()) return 2;
            if (host.SourceOrModifierDown()) releasedSince = -1;
            else
            {
                if (releasedSince < 0) releasedSince = host.ElapsedMs;
                if (host.ElapsedMs - releasedSince >= QuietMs)
                {
                    // Recheck immediately before emitting the pair.
                    if (!host.DesktopAvailable()) return 2;
                    if (host.SourceOrModifierDown()) { releasedSince = -1; host.Pause(); continue; }
                    if (dryRun) return 0;
                    uint sent = host.Send(Native.Tap());
                    if (sent == 2) return 0;
                    // If only DOWN was accepted, best-effort release of our RWin.
                    // Never release the physical source's Win/Shift keys.
                    if (sent == 1) host.Send(new[] { Native.Key(true) });
                    return 3;
                }
            }
            host.Pause();
        }
        return 1;
    }

    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length > 1 || (args.Length == 1 && args[0] != "--dry-run")) return 5;
        try
        {
            using (var gate = new Mutex(false, @"Local\Eventide.Banpilot.WindowsKey"))
            {
                bool owned;
                try { owned = gate.WaitOne(0); }
                catch (AbandonedMutexException) { owned = true; }
                if (!owned) return 4;
                try { return Run(new WindowsHost(), args.Length == 1); }
                finally { gate.ReleaseMutex(); }
            }
        }
        catch { return 5; }
    }

    private sealed class WindowsHost : IHost
    {
        private readonly Stopwatch clock = Stopwatch.StartNew();
        // L/R Win, Shift, Ctrl, Alt, F23; C also covers activation via Win+C.
        private static readonly int[] keys = { 0x5B, 0x5C, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0x86, 0x43 };
        public long ElapsedMs { get { return clock.ElapsedMilliseconds; } }
        public bool SourceOrModifierDown()
        {
            foreach (int key in keys)
                if ((Native.GetAsyncKeyState(key) & 0x8000) != 0) return true;
            return false;
        }
        public bool DesktopAvailable()
        {
            IntPtr desktop = Native.OpenInputDesktop(0, false, 1); // DESKTOP_READOBJECTS
            if (desktop == IntPtr.Zero) return false;
            try
            {
                var name = new StringBuilder(256);
                int needed;
                return Native.GetUserObjectInformation(desktop, 2, name, name.Capacity * 2, out needed)
                    && string.Equals(name.ToString(), "Default", StringComparison.OrdinalIgnoreCase)
                    && Native.GetForegroundWindow() != IntPtr.Zero;
            }
            finally { Native.CloseDesktop(desktop); }
        }
        public void Pause() { Thread.Sleep(10); }
        public uint Send(Native.Input[] inputs)
        {
            return Native.SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(Native.Input)));
        }
    }

    internal static class Native
    {
        // Include the full union: INPUT is 40 bytes on x64, not the size of KEYBDINPUT.
        [StructLayout(LayoutKind.Sequential)] internal struct Input { internal uint type; internal InputUnion data; }
        [StructLayout(LayoutKind.Explicit)] internal struct InputUnion
        {
            [FieldOffset(0)] internal Keyboard keyboard;
            [FieldOffset(0)] internal Mouse mouse;
        }
        [StructLayout(LayoutKind.Sequential)] internal struct Keyboard
        {
            internal ushort vk, scan;
            internal uint flags, time;
            internal UIntPtr extra;
        }
        [StructLayout(LayoutKind.Sequential)] internal struct Mouse
        {
            internal int x, y;
            internal uint mouseData, flags, time;
            internal UIntPtr extra;
        }
        internal static Input Key(bool up)
        {
            return new Input { type = 1, data = new InputUnion { keyboard = new Keyboard {
                vk = 0x5C, flags = 0x0001U | (up ? 0x0002U : 0U), extra = new UIntPtr(0x42504C54U)
            } } };
        }
        internal static Input[] Tap() { return new[] { Key(false), Key(true) }; }
        [DllImport("user32.dll")] internal static extern short GetAsyncKeyState(int key);
        [DllImport("user32.dll", SetLastError = true)] internal static extern uint SendInput(uint count, Input[] inputs, int size);
        [DllImport("user32.dll", SetLastError = true)] internal static extern IntPtr OpenInputDesktop(uint flags, [MarshalAs(UnmanagedType.Bool)] bool inherit, uint access);
        [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool CloseDesktop(IntPtr desktop);
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool GetUserObjectInformation(IntPtr obj, int index, StringBuilder value, int length, out int needed);
        [DllImport("user32.dll")] internal static extern IntPtr GetForegroundWindow();
    }
}
