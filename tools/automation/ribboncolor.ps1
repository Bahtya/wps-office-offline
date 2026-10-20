param(
    [string]$Tag = "t",
    [int]$WaitSec = 15
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W3 {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    public struct RECT { public int L, T, R, B; }
}
"@
[W3]::SetProcessDPIAware() | Out-Null

$p = Start-Process "$env:LOCALAPPDATA\Kingsoft\WPS Office\12.1.0.29158\office6\wps.exe" `
    -ArgumentList '"C:\Users\1531\Desktop\照片\照片处理工具说明.docx"' -PassThru
Start-Sleep -Seconds $WaitSec
$w = Get-Process -Id $p.Id -EA SilentlyContinue
if (-not $w -or $w.MainWindowHandle -eq 0) {
    $w = Get-Process wps -EA SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}
[W3]::SetForegroundWindow($w.MainWindowHandle) | Out-Null
Start-Sleep -Seconds 2
$r = New-Object W3+RECT
[W3]::GetWindowRect($w.MainWindowHandle, [ref]$r) | Out-Null
$ww = $r.R - $r.L; $hh = $r.B - $r.T
Write-Host "WINRECT ${ww}x${hh}"

function Snap($png) {
    $b = New-Object System.Drawing.Bitmap($ww, $hh)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size($ww, $hh)))
    $b.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $b.Dispose()
}
function Ribbon-Color($png) {
    $bmp = [System.Drawing.Bitmap]::FromFile($png)
    $y0 = [int]($hh * 0.08); $y1 = [int]($hh * 0.22)
    $total = 0; $colorful = 0
    for ($y = $y0; $y -lt $y1; $y += 3) {
        for ($x = [int]($ww * 0.05); $x -lt [int]($ww * 0.95); $x += 3) {
            $c = $bmp.GetPixel($x, $y)
            $total++
            $mx = [Math]::Max($c.R, [Math]::Max($c.G, $c.B))
            $mn = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
            if (($mx - $mn) -gt 40) { $colorful++ }
        }
    }
    $bmp.Dispose()
    Write-Host ("  [{0}] sampled={1} colorful={2} ({3:P1})" -f (Split-Path $png -Leaf), $total, $colorful, ($colorful / $total))
}

$tools = "C:\Users\1531\Documents\project\re-wps\tools"
$p1 = Join-Path $tools "ribbonA_$Tag.png"
$p2 = Join-Path $tools "ribbonB_$Tag.png"

Snap $p1
Ribbon-Color $p1

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class C3 {
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
}
"@
[C3]::SetCursorPos($r.L + [int]($ww/2), $r.T + [int]($hh/2)) | Out-Null
[C3]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
[C3]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Seconds 2

Snap $p2
Ribbon-Color $p2
