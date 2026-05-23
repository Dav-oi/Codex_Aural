param([Parameter(Mandatory)]$Path)

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class MciPlayer {
    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    static extern int mciSendString(string cmd, StringBuilder buf, int sz, IntPtr cb);
    
    public static void Play(string filePath) {
        var sb = new StringBuilder(256);
        string cmd = "open \"" + filePath + "\" alias ttsp";
        int r = mciSendString(cmd, sb, 256, IntPtr.Zero);
        if (r != 0) {
            Console.Error.WriteLine("MCI open failed: " + sb);
            return;
        }
        mciSendString("play ttsp wait", null, 0, IntPtr.Zero);
        mciSendString("close ttsp", null, 0, IntPtr.Zero);
    }
}
"@

[MciPlayer]::Play($Path)
