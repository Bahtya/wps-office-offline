foreach ($f in 'make-wps-offline.ps1','restore-wps.ps1') {
    $p = Join-Path 'C:\Users\1531\Documents\project\re-wps' $f
    $errs = $null
    [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Raw $p), [ref]$null, [ref]$errs) | Out-Null
    if ($errs.Count) { Write-Host ($f + ': LINE ' + $errs[0].Extent.StartLineNumber + ' ' + $errs[0].Message) }
    else { Write-Host ($f + ': PARSE OK') }
}
