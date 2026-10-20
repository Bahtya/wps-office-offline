# Elevated: delete wpscloudsvr service
$log = 'C:\Users\1531\Documents\project\re-wps\tools\del_svc.txt'
Set-Content -Path $log -Value "=== $(Get-Date) ==="
Stop-Service wpscloudsvr -Force -ErrorAction SilentlyContinue
Start-Sleep 2
$out = sc.exe delete wpscloudsvr 2>&1
Add-Content $log "delete: $out"
Add-Content $log ("exists after: " + [bool](Get-Service wpscloudsvr -ErrorAction SilentlyContinue))
