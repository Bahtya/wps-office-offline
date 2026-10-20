param(
    [string]$Exe = "$env:LOCALAPPDATA\Kingsoft\WPS Office\12.1.0.29158\office6\wps.exe",
    [string]$Arg,
    [string]$OutPng = "$env:TEMP\wps_smoke.png",
    [int]$WaitSec = 8
)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$p = Start-Process -FilePath $Exe -ArgumentList $Arg -PassThru
Start-Sleep -Seconds $WaitSec
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($b.Width, $b.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(wps|et|wpp|wpsoffice|promecef|wpscloud)' } |
    Select-Object Id, Name, MainWindowTitle | Format-Table -AutoSize | Out-String
Write-Host "saved: $OutPng"
