$q = "$env:LOCALAPPDATA\Kingsoft\WPS Office\_quarantine"
$bad = 0; $n = 0
Get-ChildItem $q | ForEach-Object {
    $n++
    $dst = ($_.Name -replace '^([A-Za-z])_', '$1:\') -replace '_', '\'
    if ($dst -notmatch '^[A-Za-z]:\\') { $bad++; Write-Host ("BAD " + $_.Name) }
    $parent = Split-Path $dst -Parent
    if (-not (Test-Path $parent)) { Write-Host ("PARENT-MISSING " + $dst) }
}
Write-Host ("entries: $n, malformed: $bad")
Get-ChildItem $q | Select-Object -First 3 | ForEach-Object {
    Write-Host (($_.Name -replace '^([A-Za-z])_', '$1:\') -replace '_', '\')
}
