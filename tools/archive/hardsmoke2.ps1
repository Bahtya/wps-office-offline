# 硬证据冒烟 v2: DPI感知 + 窗口标题校验 + 纹理分析
param(
    [string]$Doc = "C:\Users\1531\Desktop\照片\照片处理工具说明.docx",
    [string]$Tag = "t",
    [int]$WaitSec = 30,
    [switch]$UseAssoc   # 用文件关联方式启动(/prometheus /wps) 并设 CWD 为文档目录
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32b {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
    public struct RECT { public int L, T, R, B; }
}
"@
[W32b]::SetProcessDPIAware() | Out-Null

$backupDir = "$env:APPDATA\Kingsoft\office6\backup"
$before = @{}
if (Test-Path $backupDir) { Get-ChildItem $backupDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $before[$_.FullName] = 1 } }

Get-Process wps,et,wpp,wpsoffice -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1
$exe = "$env:LOCALAPPDATA\Kingsoft\WPS Office\12.1.0.29158\office6\wps.exe"
if ($UseAssoc) {
    $cwd = Split-Path $Doc
    $p = Start-Process $exe -ArgumentList "/prometheus", "/wps", "`"$Doc`"" -WorkingDirectory $cwd -PassThru
} else {
    $p = Start-Process $exe -ArgumentList "`"$Doc`"" -PassThru
}
Start-Sleep -Seconds $WaitSec
$w = Get-Process -Id $p.Id -ErrorAction SilentlyContinue
if (-not $w -or $w.MainWindowHandle -eq 0) { $w = Get-Process wps -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 }
if (-not $w) { Write-Host "NO-WPS-WINDOW (进程可能已退出!)"; exit 2 }

$sb = New-Object System.Text.StringBuilder 256
[W32b]::GetWindowText($w.MainWindowHandle, $sb, 256) | Out-Null
Write-Host ("WINTITLE: " + $sb.ToString())

[W32b]::SetForegroundWindow($w.MainWindowHandle) | Out-Null
Start-Sleep 1
$r = New-Object W32b+RECT
[W32b]::GetWindowRect($w.MainWindowHandle, [ref]$r) | Out-Null
$ww = $r.R - $r.L; $hh = $r.B - $r.T
if ($ww -le 0 -or $hh -le 0) { Write-Host "BAD-RECT"; exit 2 }
$out = "C:\Users\1531\Documents\project\re-wps\tools\hard2_$Tag.png"
$bmp = New-Object System.Drawing.Bitmap($ww, $hh)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size($ww, $hh)))
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()

# 画布区纹理分析: 30%~85% 宽, 35%~90% 高
$x0 = [int]($ww * 0.30); $x1 = [int]($ww * 0.85)
$y0 = [int]($hh * 0.35); $y1 = [int]($hh * 0.90)
$total = 0; $white = 0; $dark = 0
$rowDark = @{}   # 每行暗像素计数
for ($y = $y0; $y -lt $y1; $y += 3) {
    $rowDark[$y] = 0
    for ($x = $x0; $x -lt $x1; $x += 3) {
        $c = $bmp.GetPixel($x, $y); $total++
        if ($c.R -gt 235 -and $c.G -gt 235 -and $c.B -gt 235) { $white++ }
        elseif ($c.R -lt 120 -and $c.G -lt 120 -and $c.B -lt 120) { $dark++; $rowDark[$y]++ }
    }
}
# 文字页面特征: 行暗计数呈条纹分布(有行有暗>0, 有行=0) + 白占比高
$bandRows = 0; $emptyRows = 0
foreach ($y in $rowDark.Keys) { if ($rowDark[$y] -gt 3) { $bandRows++ } elseif ($rowDark[$y] -eq 0) { $emptyRows++ } }
Write-Host ("WINRECT ${ww}x${hh}  white={0:P1} dark={1:P2} rowsDark=$bandRows rowsEmpty=$emptyRows" -f ($white/$total), ($dark/$total))
Write-Host ("PNG: $out SHA1=" + (Get-FileHash $out -Algorithm SHA1).Hash.Substring(0,12))
if (($white/$total) -gt 0.30 -and $bandRows -gt 8) { Write-Host "VERDICT: DOCUMENT-RENDERED (白纸+文字条纹)" -ForegroundColor Green }
elseif ($bandRows -gt 8) { Write-Host "VERDICT: TEXT-CONTENT-NO-PAPER (有文字无白纸, 可能深色主题)" -ForegroundColor Yellow }
else { Write-Host "VERDICT: NO-TEXT-TEXTURE (无文字条纹 => 白屏/错误页/截图错位)" -ForegroundColor Red }
$bmp.Dispose()

$newB = @()
if (Test-Path $backupDir) { $newB = Get-ChildItem $backupDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { -not $before.ContainsKey($_.FullName) } }
Write-Host ("NEW-BACKUP-FILES: " + $newB.Count)
$newB | Select-Object -First 3 | ForEach-Object { Write-Host ("  + " + $_.Name) }
