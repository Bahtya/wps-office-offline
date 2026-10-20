# UIA 取证: 读取 WPS 窗口控件树的真实内容
param(
    [string]$Doc = "C:\Users\1531\Desktop\照片\照片处理工具说明.docx",
    [int]$WaitSec = 30,
    [switch]$UseAssoc
)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

Get-Process wps,et,wpp,wpsoffice -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1
$exe = "$env:LOCALAPPDATA\Kingsoft\WPS Office\12.1.0.29158\office6\wps.exe"
if ($UseAssoc) {
    $p = Start-Process $exe -ArgumentList "/prometheus", "/wps", "`"$Doc`"" -WorkingDirectory (Split-Path $Doc) -PassThru
} else {
    $p = Start-Process $exe -ArgumentList "`"$Doc`"" -PassThru
}
Start-Sleep -Seconds $WaitSec
$w = Get-Process -Id $p.Id -ErrorAction SilentlyContinue
if (-not $w -or $w.MainWindowHandle -eq 0) {
    $w = Get-Process wps -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}
if (-not $w) { Write-Host "NO-WPS-WINDOW"; exit 2 }

$root = [System.Windows.Automation.AutomationElement]::FromHandle($w.MainWindowHandle)
Write-Host ("UIA-ROOT: " + $root.Current.Name + " | type=" + $root.Current.ControlType.ProgrammaticName)

$cond = [System.Windows.Automation.Condition]::TrueCondition
$sw = New-Object System.IO.StringWriter
$count = 0
function Walk($el, $depth, $sw) {
    if ($depth -gt 8 -or $script:count -gt 1200) { return }
    $script:count++
    try {
        $name = $el.Current.Name
        $ct = $el.Current.ControlType.ProgrammaticName
        if ($name) {
            $t = $name -replace "\s+", " "
            if ($t.Length -gt 90) { $t = $t.Substring(0, 90) + "..." }
            if ($t.Trim().Length -gt 0) { $sw.WriteLine(("  " * $depth + $ct + " | " + $t)) }
        }
        $kids = $el.FindAll([System.Windows.Automation.TreeScope]::Children, $true)
        foreach ($k in $kids) { Walk $k ($depth + 1) $sw }
    } catch {}
}
Walk $root 0 $sw
$out = $sw.ToString()
Set-Content -Path "C:\Users\1531\Documents\project\re-wps\tools\uia_dump.txt" -Value $out -Encoding UTF8
Write-Host ("controls=" + $count + " -> uia_dump.txt")
# 关键词判定
$hits = @()
foreach ($kw in '无法恢复的错误','重新载入','如何解决','自动保存到备份','杀毒软件','误杀','照片处理工具') {
    if ($out -match [regex]::Escape($kw)) { $hits += $kw }
}
Write-Host ("KEYWORD-HITS: " + ($hits -join ', '))
Set-Content -Path "C:\Users\1531\Documents\project\re-wps\tools\uia_hits.txt" -Value ($hits -join "`n") -Encoding UTF8
