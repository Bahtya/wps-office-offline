Add-Type -AssemblyName System.Drawing
foreach ($f in 'ribbonA_cmp.png','ribbonB_cmp.png') {
    $bmp = [System.Drawing.Bitmap]::FromFile("C:\Users\1531\Documents\project\re-wps\tools\$f")
    $hh = $bmp.Height; $ww = $bmp.Width
    $total = 0; $dark = 0
    $y0 = [int]($hh * 0.08); $y1 = [int]($hh * 0.22)
    for ($y = $y0; $y -lt $y1; $y += 3) {
        for ($x = [int]($ww * 0.05); $x -lt [int]($ww * 0.95); $x += 3) {
            $c = $bmp.GetPixel($x, $y)
            $mn = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
            $total++
            if ($mn -lt 110) { $dark++ }
        }
    }
    $bmp.Dispose()
    Write-Host ('{0}: dark-pixels {1} ({2:P1})' -f $f, $dark, ($dark/$total))
}
