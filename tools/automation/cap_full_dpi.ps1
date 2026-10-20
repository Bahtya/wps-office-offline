# DPI-aware full physical screen capture
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DPI{[DllImport("user32.dll")]public static extern bool SetProcessDPIAware();}
'@
[void][DPI]::SetProcessDPIAware()
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
$b = [System.Windows.Forms.SystemInformation]::VirtualScreen
Write-Host ("physical virtual screen: {0},{1} {2}x{3}" -f $b.X, $b.Y, $b.Width, $b.Height)
$bmp = New-Object System.Drawing.Bitmap($b.Width, $b.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
$out = 'C:\Users\1531\Documents\project\re-wps\tools\fullscreen_phys.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "saved $out"
