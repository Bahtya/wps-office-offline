param(
    [string]$Png = "C:\Users\1531\Documents\project\re-wps\tools\hard2_plain.png",
    [int]$Cols = 150,
    [string]$Out = "C:\Users\1531\Documents\project\re-wps\tools\ascii_out.txt"
)
Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile($Png)
$w = $bmp.Width; $h = $bmp.Height
$rows = [int]($Cols * $h / $w / 2.1)
$chars = " .:-=+*#%@"
$sb = New-Object System.Text.StringBuilder
for ($j = 0; $j -lt $rows; $j++) {
    $line = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $Cols; $i++) {
        $px = [int]($i * $w / $Cols); $py = [int]($j * $h / $rows)
        $c = $bmp.GetPixel($px, $py)
        $lum = ($c.R * 0.3 + $c.G * 0.59 + $c.B * 0.11) / 255
        $idx = [int]((1 - $lum) * ($chars.Length - 1))
        [void]$line.Append($chars[$idx])
    }
    [void]$sb.AppendLine($line.ToString())
}
$bmp.Dispose()
Set-Content -Path $Out -Value $sb.ToString()
Write-Host ("written: " + $Out + " (" + $rows + " rows)")
