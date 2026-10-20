# Elevated: remove all wpscloudsvr binaries and kill process
$log = 'C:\Users\1531\Documents\project\re-wps\tools\del_svc.txt'
Add-Content $log "=== remove all binaries $(Get-Date) ==="
Stop-Process -Name wpscloudsvr -Force -ErrorAction SilentlyContinue
Start-Sleep 1
foreach ($f in @(
    'C:\Program Files\Kingsoft\office6\wpscloudsvr.exe',
    'C:\Program Files (x86)\Kingsoft\office6\wpscloudsvr.exe'
)) {
    if (Test-Path $f) {
        Remove-Item $f -Force
        Add-Content $log "removed: $f"
    }
}
$still = Get-Process wpscloudsvr -ErrorAction SilentlyContinue
Add-Content $log ("proc alive: " + [bool]$still)
Add-Content $log ("pf exists: " + (Test-Path 'C:\Program Files\Kingsoft\office6\wpscloudsvr.exe'))
