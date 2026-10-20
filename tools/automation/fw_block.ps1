# Elevated: firewall blocks + clear cache/pool
$log = 'C:\Users\1531\Documents\project\re-wps\tools\fw_log.txt'
Set-Content $log "=== $(Get-Date) ==="

Stop-Process -Name wps -Force -ErrorAction SilentlyContinue
Start-Sleep 3

$root = 'C:\Users\1531\AppData\Local\Kingsoft\WPS Office'
$i = 0
Get-ChildItem $root -Recurse -Filter *.exe -ErrorAction SilentlyContinue |
    Where-Object FullName -notmatch '_quarantine' | ForEach-Object {
    $n = 'WPS-Offline-Block-' + $i
    if (-not (Get-NetFirewallRule -DisplayName $n -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $n -Direction Outbound -Program $_.FullName -Action Block | Out-Null
        New-NetFirewallRule -DisplayName "$n-In" -Direction Inbound -Program $_.FullName -Action Block | Out-Null
    }
    $i++
}
Add-Content $log "firewall rules for $i exes"

$ra = 'C:\Users\1531\AppData\Roaming\Kingsoft'
$q = 'C:\Users\1531\AppData\Local\Kingsoft\WPS Office\_quarantine\cloud_refetch'
if (Test-Path "$ra\office6\cache") {
    Remove-Item "$ra\office6\cache" -Recurse -Force
    Add-Content $log 'cache cleared'
}
$pool = "$ra\wps\addons\pool\win-x64"
if (Test-Path $pool) {
    Get-ChildItem $pool -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Move-Item $_.FullName (Join-Path $q ('pool3_' + $_.Name)) -Force
    }
    Add-Content $log 'pool cleared'
}
Add-Content $log '=== done ==='
