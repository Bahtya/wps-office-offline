# Capture the ksomisc window region to PNG
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$bounds = [System.Drawing.Rectangle]::FromLTRB(352, 159, 921, 590)
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$out = 'C:\Users\1531\Documents\project\re-wps\tools\ksomisc_shot.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "saved $out"
