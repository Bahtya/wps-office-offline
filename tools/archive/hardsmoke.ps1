# 本地硬证据冒烟测试: 不依赖视觉服务
# 1) 记录启动前 backup/CrashDumps 基线
# 2) 启动 wps.exe 打开文档, 等待
# 3) 截取 WPS 主窗口区域 -> PNG + 像素统计(非白像素比例)
# 4) 复查 backup/CrashDumps 是否新增(= 崩溃守卫触发)
param(
    [string]$Doc = "C:\Users\1531\Desktop\照片\照片处理工具说明.docx",
    [string]$Tag = "t",
    [int]$WaitSec = 30
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    public struct RECT { public int L, T, R, B; }
}
"@

$backupDir = "$env:APPDATA\Kingsoft\office6\backup"
$dumpDir   = "$env:LOCALAPPDATA\CrashDumps"
$before = @{}
if (Test-Path $backupDir) { Get-ChildItem $backupDir -Recurse -File | ForEach-Object { $before[$_.FullName] = $_.Length } }
$beforeDumps = @()
if (Test-Path $dumpDir) { $beforeDumps = Get-ChildItem $dumpDir -Filter *.dmp -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name }

# ---- 启动 ----
Get-Process wps,et,wpp,wpsoffice -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1
$p = Start-Process "$env:LOCALAPPDATA\Kingsoft\WPS Office\12.1.0.29158\office6\wps.exe" -ArgumentList "`"$Doc`"" -PassThru
Start-Sleep -Seconds $WaitSec
$p = Get-Process wps -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1

$out = "C:\Users\1531\Documents\project\re-wps\tools\hard_$Tag.png"
if ($p) {
    [Win32]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
    Start-Sleep 1
    $r = New-Object Win32+RECT
    [Win32]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
    $w = $r.R - $r.L; $h = $r.B - $r.T
    if ($w -gt 0 -and $h -gt 0) {
        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size($w, $h)))
        $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose()
        # 像素统计: 中央画布区(避开功能区和滚动条)
        $x0 = [int]($w * 0.30); $x1 = [int]($w * 0.85)
        $y0 = [int]($h * 0.35); $y1 = [int]($h * 0.90)
        $total = 0; $nonwhite = 0; $dark = 0
        for ($y = $y0; $y -lt $y1; $y += 4) {
            for ($x = $x0; $x -lt $x1; $x += 4) {
                $c = $bmp.GetPixel($x, $y)
                $total++
                if (-not ($c.R -gt 240 -and $c.G -gt 240 -and $c.B -gt 240)) { $nonwhite++ }
                if ($c.R -lt 120 -and $c.G -lt 120 -and $c.B -lt 120) { $dark++ }
            }
        }
        $bmp.Dispose()
        Write-Host ("WINRECT ${w}x${h}  canvas-sample=$total  nonwhite={0:P1}  dark(text)={1:P2}" -f ($nonwhite/$total), ($dark/$total))
        Write-Host ("PNG: $out  SHA1: " + (Get-FileHash $out -Algorithm SHA1).Hash.Substring(0,12))
        if ($dark/$total -lt 0.001) { Write-Host "VERDICT: CANVAS-LIKELY-BLANK (无文字暗像素)" -ForegroundColor Red }
        else { Write-Host "VERDICT: CANVAS-HAS-CONTENT (检测到文字暗像素)" -ForegroundColor Green }
    } else { Write-Host "window rect invalid" -ForegroundColor Red }
} else { Write-Host "no wps window" -ForegroundColor Red }

# ---- 崩溃取证 ----
$newBackups = @()
if (Test-Path $backupDir) {
    $newBackups = Get-ChildItem $backupDir -Recurse -File | Where-Object { -not $before.ContainsKey($_.FullName) }
}
$newDumps = @()
if (Test-Path $dumpDir) {
    $newDumps = Get-ChildItem $dumpDir -Filter *.dmp -ErrorAction SilentlyContinue | Where-Object { $beforeDumps -notcontains $_.Name }
}
Write-Host ("NEW-BACKUP-FILES: " + $newBackups.Count)
$newBackups | Select-Object -First 3 | ForEach-Object { Write-Host ("  + " + $_.Name + " (" + $_.Length + "B)") }
Write-Host ("NEW-CRASHDUMPS: " + $newDumps.Count)
