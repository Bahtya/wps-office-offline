# =====================================================================
# restore-wps.ps1 — WPS Office 一键还原（撤销 make-wps-offline.ps1 的全部改动）
#
# 用法: powershell -ExecutionPolicy Bypass -File restore-wps.ps1
# 需要管理员权限(服务/计划任务/防火墙/Program Files), 脚本自动提权。
#
# 还原内容:
#   1. _quarantine 中全部组件移回原位(目录名即原路径)
#   2. 重建 wpscloudsvr 服务 (LocalSystem)
#   3. 重建 Everything 索引服务(尽力还原; 精确参数以 WPS 自身注册为准)
#   4. 重建 3 个计划任务(登录更新/定时更新/WNS唤醒; 定时任务的原始触发
#      时间未留存, 统一还原为每日 10:00, 偏差仅影响更新检查时刻)
#   5. 删除全部 WPS-Offline-Block* 防火墙规则
#   6. 开始菜单 WPS Office.lnk 改回 ksolaunch.exe
#   7. 重建"WPS云盘"资源管理器命名空间注册
# =====================================================================
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Root = "$env:LOCALAPPDATA\Kingsoft\WPS Office"
)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "需要管理员权限, 正在提权重启..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File', $PSCommandPath)
    exit
}

$quar   = Join-Path $Root '_quarantine'
$ver    = Get-ChildItem $Root -Directory | Where-Object Name -match '^\d+\.' | Select-Object -First 1
$office = Join-Path $ver.FullName 'office6'
Write-Host "== WPS 还原: $($ver.Name) ==" -ForegroundColor Cyan
if (-not (Test-Path $quar)) { Write-Host "隔离区不存在, 无需还原。"; exit }

# ---- 1. 文件回位 -----------------------------------------------------
Write-Host "`n[1/7] 隔离区组件回位" -ForegroundColor Green
$restored = 0
Get-ChildItem $quar | ForEach-Object {
    $dst = ($_.Name -replace '^([A-Za-z])_', '$1:\') -replace '_', '\'
    if ($PSCmdlet.ShouldProcess($dst, '还原')) {
        $parent = Split-Path $dst -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        if (Test-Path $dst) { Write-Host "  [跳过] 目标已存在: $dst" -ForegroundColor DarkYellow }
        else { Move-Item -LiteralPath $_.FullName -Destination $dst -Force; $restored++ }
    }
}
Write-Host "  已还原 $restored 个条目"

# ---- 1.5 登录补丁还原 (kshell.dll) ------------------------------------
Write-Host "`n[1.5] 还原 kshell.dll 登录补丁" -ForegroundColor Green
$kshell = Join-Path $office 'kshell.dll'
$korig  = "$kshell.korig"
if (Test-Path $korig) {
    Copy-Item $korig $kshell -Force
    Remove-Item $korig -Force
    Write-Host "  kshell.dll 已从 .korig 还原"
} else { Write-Host "  无补丁备份, 跳过" }

# ---- 2. wpscloudsvr 服务 --------------------------------------------
Write-Host "`n[2/7] 重建 wpscloudsvr 服务" -ForegroundColor Green
if (-not (Get-Service wpscloudsvr -ErrorAction SilentlyContinue)) {
    sc.exe create wpscloudsvr binpath= "\"C:\Program Files\Kingsoft\office6\wpscloudsvr.exe\" LocalService" start= demand | Out-Null
    sc.exe description wpscloudsvr "WPS Office Cloud Service" | Out-Null
    Write-Host "  已重建 (DEMAND_START)"
}

# ---- 3. Everything 索引服务(尽力) -----------------------------------
Write-Host "`n[3/7] 重建 Everything 服务(尽力还原)" -ForegroundColor Green
$everything = Join-Path $office 'addons\everythingsearch\everythingbinary\Everything.exe'
if ($everything -and (Test-Path $everything) -and -not (Get-Service Everything -ErrorAction SilentlyContinue)) {
    sc.exe create Everything binpath= "\"$everything\" -service" start= auto | Out-Null
    Write-Host "  已重建 (AUTO_START)"
}

# ---- 4. 计划任务 -----------------------------------------------------
Write-Host "`n[4/7] 重建计划任务" -ForegroundColor Green
$ksolaunch = Join-Path $Root 'ksolaunch.exe'
$action = New-ScheduledTaskAction -Execute $ksolaunch -Argument '/wpsupdate -from=task -source=task'
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
$triggerDaily = New-ScheduledTaskTrigger -Daily -At 10:00
foreach ($name in "WpsUpdateLogonTask_$env:USERNAME", "WpsUpdateTask_$env:USERNAME") {
    if (-not (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue)) {
        Register-ScheduledTask -TaskName $name -Action $action `
            -Trigger $(if ($name -like '*Logon*') { $triggerLogon } else { $triggerDaily }) -Force | Out-Null
        Write-Host "  已重建 $name"
    }
}
$wnsAction = New-ScheduledTaskAction -Execute "`"$ksolaunch`"" `
    -Argument "Run addons/kpluginwrapper/kpluginwrapper.dll run_plugin -plugin_name=kmessagepushcenter -dll_name=kmessagepushcenter wake_wns"
if (-not (Get-ScheduledTask -TaskName 'WpsWakeWnsLogonTask' -ErrorAction SilentlyContinue)) {
    Register-ScheduledTask -TaskName 'WpsWakeWnsLogonTask' -Action $wnsAction -Trigger $triggerLogon -Force | Out-Null
    Write-Host "  已重建 WpsWakeWnsLogonTask"
}

# ---- 5. 防火墙 -------------------------------------------------------
Write-Host "`n[5/7] 移除 WPS-Offline-Block* 防火墙规则" -ForegroundColor Green
$rules = Get-NetFirewallRule -DisplayName 'WPS-Offline-Block*' -ErrorAction SilentlyContinue
if ($rules) { $rules | Remove-NetFirewallRule; Write-Host "  已移除 $($rules.Count) 条" }

# ---- 6. 快捷方式 -----------------------------------------------------
Write-Host "`n[6/7] 开始菜单快捷方式改回 ksolaunch" -ForegroundColor Green
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\WPS Office.lnk"
if (Test-Path $lnk) {
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($lnk)
    if ($PSCmdlet.ShouldProcess($lnk, '改回 ksolaunch.exe')) {
        $s.TargetPath = $ksolaunch; $s.Save(); Write-Host "  WPS Office.lnk -> ksolaunch.exe"
    }
}

# ---- 7. WPS云盘命名空间 ----------------------------------------------
Write-Host "`n[7/7] 重建 WPS云盘 资源管理器命名空间" -ForegroundColor Green
$ns1 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{EEEEFCF7-867B-4FA2-9ABD-884CF531B600}'
$ns2 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{EEEEFCF7-867B-4FA2-9ABD-884CF531B602}'
foreach ($k in @($ns1, $ns2)) {
    if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
}
Write-Host "  已重建(重启资源管理器后生效)"

Write-Host @"

=====================================================================
还原完成。建议重启一次 WPS/资源管理器使命名空间刷新。
注: 计划任务 WpsUpdateTask 的每日触发时间未留存, 统一设为 10:00;
    Everything 服务参数为标准形态, 如有偏差 WPS 更新时会自行纠正。
=====================================================================
"@ -ForegroundColor Cyan
