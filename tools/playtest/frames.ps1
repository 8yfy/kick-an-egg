param([string]$Dir, [int]$Every = 3, [int]$Seconds = 240, [string]$Exclude = "KickTheEgg.rbxl")
# DEV ONLY. Saves the play-test Studio window every $Every seconds (PrintWindow, that window's own pixels only:
# never the screen). Stops when the window closes or after $Seconds.
Add-Type -ReferencedAssemblies System.Drawing @"
using System; using System.Text; using System.Drawing; using System.Runtime.InteropServices;
public class Frames {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  public struct RECT { public int L, T, R, B; }
  public static IntPtr Find(string ex) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => { var sb = new StringBuilder(512); GetWindowText(h, sb, 512); var t = sb.ToString();
      if (IsWindowVisible(h) && t.Contains("Roblox Studio") && t.Contains("run-in-roblox") && !t.Contains(ex)) { found = h; return false; } return true; }, IntPtr.Zero);
    return found;
  }
  public static Bitmap Grab(IntPtr h) {
    RECT r; GetWindowRect(h, out r);
    if (r.R - r.L < 10) return null;
    var bmp = new Bitmap(r.R - r.L, r.B - r.T);
    using (var g = Graphics.FromImage(bmp)) { var dc = g.GetHdc(); PrintWindow(h, dc, 2); g.ReleaseHdc(dc); }
    return bmp;
  }
}
"@
[Frames]::SetProcessDPIAware() | Out-Null
$deadline = (Get-Date).AddSeconds(150)
$hwnd = [IntPtr]::Zero
while ($hwnd -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline) { $hwnd = [Frames]::Find($Exclude); if ($hwnd -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 500 } }
if ($hwnd -eq [IntPtr]::Zero) { "no play-test window"; exit 1 }
$end = (Get-Date).AddSeconds($Seconds)
$i = 0
while ((Get-Date) -lt $end -and [Frames]::IsWindow($hwnd)) {
  $bmp = [Frames]::Grab($hwnd)
  if ($bmp -ne $null) { $bmp.Save((Join-Path $Dir ("frame_{0:D3}.png" -f $i)), [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose(); $i++ }
  Start-Sleep -Seconds $Every
}
"saved $i frames"
