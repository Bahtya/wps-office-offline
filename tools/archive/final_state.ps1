$q = "$env:LOCALAPPDATA\Kingsoft\WPS Office\_quarantine"
Write-Host ('隔离区        : ' + (Get-ChildItem $q).Count + ' 项')
Write-Host ('knetwork 在位 : ' + (Test-Path "$env:LOCALAPPDATA\Kingsoft\WPS Office\12.1.0.29158\office6\addons\knetwork\"))
$b = [System.IO.File]::ReadAllBytes("$env:LOCALAPPDATA\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll")
Write-Host ('kshell 登录补丁: ' + ($b[0x77f0f0] -eq 0x31))
$pool = "$env:APPDATA\Kingsoft\wps\addons\pool\win-x64"
Write-Host ('插件池        : ' + (@(Get-ChildItem $pool -EA SilentlyContinue).Count) + ' 项(应为0)')
Write-Host ('服务/任务/防火墙: ' + (@(Get-Service wpscloudsvr,Everything -EA SilentlyContinue).Count) + ' / ' + (@(Get-ScheduledTask -EA SilentlyContinue | Where-Object TaskName -match 'Wps').Count) + ' / ' + (@(Get-NetFirewallRule -DisplayName 'WPS-Offline-Block*' -EA SilentlyContinue).Count) + ' 条')
$p = @(Get-Process | Where-Object { $_.Name -match '^(wps|et|wpp|wpsoffice|ksolaunch|promecef|Everything|wpscloud)' })
Write-Host ('WPS 进程      : ' + $p.Count)
