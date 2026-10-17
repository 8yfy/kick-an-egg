param([string]$Out, [string]$Title = "KTE-anim", [double]$Seconds = 4, [int]$Fps = 30, [double]$Delay = 0, [int]$Crop = 0, [string]$Rect = "")
# DEV ONLY. Records one Studio window (PrintWindow: that window's own pixels, never the screen) at about $Fps for
# $Seconds into $Out\f_0000.png ... plus times.txt (ms since start per frame). tools/anim/encode.py turns the frames
# into an mp4 and a contact sheet. $Crop trims that many pixels off every edge (Studio chrome); $Rect "x,y,w,h"
# keeps just that part of the window (the game viewport), which also keeps long recordings small in memory.
Add-Type -ReferencedAssemblies System.Drawing @"
using System; using System.Text; using System.Drawing; using System.Runtime.InteropServices;
public class AnimCap {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  public struct RECT { public int L, T, R, B; }
  public static IntPtr Find(string part) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => { var sb = new StringBuilder(512); GetWindowText(h, sb, 512); var t = sb.ToString();
      if (IsWindowVisible(h) && t.Contains("Roblox Studio") && t.Contains(part)) { found = h; return false; } return true; }, IntPtr.Zero);
    return found;
  }
  public static Bitmap Grab(IntPtr h, int crop, int rx, int ry, int rw, int rh) {
    RECT r; GetWindowRect(h, out r);
    int w = r.R - r.L, ht = r.B - r.T;
    if (w < 10) return null;
    var full = new Bitmap(w, ht);
    using (var g = Graphics.FromImage(full)) { var dc = g.GetHdc(); PrintWindow(h, dc, 2); g.ReleaseHdc(dc); }
    Rectangle rect;
    if (rw > 0) rect = new Rectangle(rx, ry, Math.Min(rw, w - rx), Math.Min(rh, ht - ry));
    else if (crop > 0) rect = new Rectangle(crop, crop, w - 2 * crop, ht - 2 * crop);
    else return full;
    var cut = full.Clone(rect, full.PixelFormat); full.Dispose(); return cut;
  }
}
"@
[AnimCap]::SetProcessDPIAware() | Out-Null
$hwnd = [AnimCap]::Find($Title)
if ($hwnd -eq [IntPtr]::Zero) { "no Studio window with '$Title' in its title"; exit 1 }
New-Item -ItemType Directory -Force $Out | Out-Null
if ($Delay -gt 0) { Start-Sleep -Milliseconds ([int]($Delay * 1000)) }
$rx, $ry, $rw, $rh = 0, 0, 0, 0
if ($Rect -ne "") { $p = $Rect.Split(","); $rx, $ry, $rw, $rh = [int]$p[0], [int]$p[1], [int]$p[2], [int]$p[3] }
$sw = [Diagnostics.Stopwatch]::StartNew()
$frameMs = 1000.0 / $Fps
$i = 0
$times = New-Object System.Collections.Generic.List[string]
$frames = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
  $due = $i * $frameMs
  $wait = $due - $sw.Elapsed.TotalMilliseconds
  if ($wait -gt 1) { Start-Sleep -Milliseconds ([int]$wait) }
  $t = $sw.Elapsed.TotalMilliseconds
  $bmp = [AnimCap]::Grab($hwnd, $Crop, $rx, $ry, $rw, $rh)
  if ($bmp -ne $null) { $frames.Add($bmp); $times.Add([string][int]$t); $i++ }
}
$elapsed = $sw.Elapsed.TotalSeconds
# saved after the recording so disk writes never slow the frame rate
for ($k = 0; $k -lt $frames.Count; $k++) {
  $frames[$k].Save((Join-Path $Out ("f_{0:D4}.png" -f $k)), [System.Drawing.Imaging.ImageFormat]::Png); $frames[$k].Dispose()
}
$times | Set-Content -Encoding ascii (Join-Path $Out "times.txt")
"saved $i frames in $([math]::Round($elapsed, 2)) s"
