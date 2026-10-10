param([string]$Out, [int]$W = 1600, [int]$H = 900, [int]$WaitSeconds = 20, [string]$Exclude = "KickTheEgg.rbxl")
# DEV ONLY. Captures ONLY the preview Studio window's own pixels (PrintWindow, PW_RENDERFULLCONTENT): never
# the screen, so nothing else that is open gets recorded, and focus is not changed. Then crops to the
# preview stage, found by its 12x12 magenta corner marker (tools/preview/UiPreview.server.lua).
Add-Type -ReferencedAssemblies System.Drawing @"
using System; using System.Text; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public class Cap {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  public struct RECT { public int L, T, R, B; }
  public static IntPtr Find(string ex) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => { var sb = new StringBuilder(512); GetWindowText(h, sb, 512); var t = sb.ToString();
      if (IsWindowVisible(h) && t.Contains("Roblox Studio") && t.Contains(".rbxl") && !t.Contains(ex)) { found = h; return false; } return true; }, IntPtr.Zero);
    return found;
  }
  public static Bitmap Grab(IntPtr h) {
    RECT r; GetWindowRect(h, out r);
    var bmp = new Bitmap(r.R - r.L, r.B - r.T);
    using (var g = Graphics.FromImage(bmp)) { var dc = g.GetHdc(); PrintWindow(h, dc, 2); g.ReleaseHdc(dc); }
    return bmp;
  }
  public static Point Marker(Bitmap b) {
    for (int y = 0; y < Math.Min(b.Height, 900); y++)
      for (int x = 0; x < Math.Min(b.Width, 1200); x++) {
        var c = b.GetPixel(x, y);
        if (c.R > 245 && c.G < 10 && c.B > 245) return new Point(x, y);
      }
    return new Point(-1, -1);
  }
}
"@
[Cap]::SetProcessDPIAware() | Out-Null
$deadline = (Get-Date).AddSeconds(150)
$hwnd = [IntPtr]::Zero
while ($hwnd -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline) { $hwnd = [Cap]::Find($Exclude); if ($hwnd -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 500 } }
if ($hwnd -eq [IntPtr]::Zero) { "no preview window"; exit 1 }
Start-Sleep -Seconds $WaitSeconds
$full = [Cap]::Grab($hwnd)
$p = [Cap]::Marker($full)
if ($p.X -lt 0) { $full.Save($Out); "marker not found; saved full window $Out"; exit 0 }
$crop = $full.Clone((New-Object System.Drawing.Rectangle $p.X, $p.Y, ([Math]::Min($W, $full.Width - $p.X)), ([Math]::Min($H, $full.Height - $p.Y))), $full.PixelFormat)
$crop.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"saved $Out ($($crop.Width)x$($crop.Height)) from window origin $($p.X),$($p.Y)"
