Add-Type -AssemblyName System.Drawing
foreach ($f in 'ribbonA_cmp.png','ribbonB_cmp.png') {
    $bmp = [System.Drawing.Bitmap]::FromFile("C:\Users\1531\Documents\project\re-wps\tools\$f")
    $hh = $bmp.Height; $ww = $bmp.Width
    $total = 0; $dark = 0; $mid = 0
    $y0 = [int]($hh * 0.035); $y1 = [int]($hh * 0.075)
    for ($y = $y0; $y -lt $y1; $y += 2) {
        for ($x = [int]($ww * 0.03); $x -lt [int]($ww * 0.97); $x += 2) {
            $c = $bmp.GetPixel($x, $y)
            $mn = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
            $total++
            if ($mn -lt 110) { $dark++ }
            elseif ($mn -lt 190) { $mid++ }
        }
    }
    $bmp.Dispose()
    Write-Host ('{0}: dark={1} ({2:P1}) mid={3} ({4:P1})' -f $f, $dark, ($dark/$total), $mid, ($mid/$total))
}
