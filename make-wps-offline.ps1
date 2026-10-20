# =====================================================================
# make-wps-offline.ps1 — WPS Office 离线精简脚本
# 目标版本: WPS 12.x (自动检测, 二进制补丁带版本校验)
# 依据: re-wps 项目逆向分析报告 (WPS离线精简方案.md)
#
# 用法:
#   powershell -ExecutionPolicy Bypass -File make-wps-offline.ps1            # 默认(不含CEF)
#   powershell -ExecutionPolicy Bypass -File make-wps-offline.ps1 -WhatIf    # 演练,不实际改动
#
# 需要管理员权限(服务/计划任务/防火墙/Program Files)。脚本会自动提权。
# 所有被删组件移动到 _quarantine 目录(同盘移动,可整体拖回即回滚)。
# =====================================================================
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Root = "$env:LOCALAPPDATA\Kingsoft\WPS Office"
)

# ---- 自动提权 -------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "需要管理员权限, 正在提权重启..." -ForegroundColor Yellow
    $argList = @('-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
    Start-Process powershell -Verb RunAs -ArgumentList $argList
    exit
}

$ver    = Get-ChildItem $Root -Directory | Where-Object Name -match '^\d+\.' | Select-Object -First 1
$office = Join-Path $ver.FullName 'office6'
$quar   = Join-Path $Root '_quarantine'
New-Item -ItemType Directory -Force -Path $quar | Out-Null
Write-Host "== WPS 离线精简: $($ver.Name) ==" -ForegroundColor Cyan
Write-Host "office6 : $office"
Write-Host "隔离区  : $quar`n"

function Move-ToQuarantine([string]$path) {
    if (Test-Path $path) {
        $dest = Join-Path $quar ($path -replace '[:\\]+', '_')
        if ($PSCmdlet.ShouldProcess($path, "移入隔离区")) {
            Move-Item -LiteralPath $path -Destination $dest -Force
            Write-Host "  [裁] $path" -ForegroundColor DarkGray
        }
    }
}

# ---- 1. 停进程 -------------------------------------------------------
Write-Host "`n[1/6] 停止 WPS 全部进程" -ForegroundColor Green
$procs = 'wps','et','wpp','wpspdf','wpsoffice','ksolaunch','wpscloudsvr','wpscloudlaunch',
         'kwpswnsserver','promecefpluginhost','wpscenter','wpslingxi','ksomisc','photolaunch',
         'Everything','wpsupdate','updateself','updatepolicy','ksocrashdumper','kcrashdumper','transerr'
Get-Process -ErrorAction SilentlyContinue | Where-Object { $procs -contains $_.Name } |
    ForEach-Object { if ($PSCmdlet.ShouldProcess($_.Name, "结束进程")) { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } }

# ---- 2. 服务 ---------------------------------------------------------
# !! 2026-10-20 终版实测: compatible_type=1 (步骤7的官方开关) 独立兜住登录态,
#    wpscloudsvr 服务/exe 全部移除后功能区依然全功能(色板/选色/编辑/保存实测通过)。
#    旧结论"服务必须保留"是在无开关时代得出的, 作废。
Write-Host "`n[2/6] 删除 wpscloudsvr 服务 + Everything 全盘索引器" -ForegroundColor Green
if (Get-Service wpscloudsvr -ErrorAction SilentlyContinue) {
    if ($PSCmdlet.ShouldProcess('wpscloudsvr', '停止并删除服务')) {
        Stop-Service wpscloudsvr -Force -ErrorAction SilentlyContinue
        sc.exe delete wpscloudsvr | Out-Null
        Write-Host "  已删除服务 wpscloudsvr"
    }
}
if (Get-Service Everything -ErrorAction SilentlyContinue) {
    if ($PSCmdlet.ShouldProcess('Everything', '停止并删除全盘索引服务')) {
        Stop-Service Everything -Force -ErrorAction SilentlyContinue
        sc.exe delete Everything | Out-Null
        Write-Host "  已删除服务 Everything (WPS 内置全盘索引器)"
    }
}
# Program Files 下的服务副本(注册路径指向这里)
Move-ToQuarantine 'C:\Program Files\Kingsoft\office6\wpscloudsvr.exe'
Move-ToQuarantine 'C:\Program Files (x86)\Kingsoft\office6\wpscloudsvr.exe'

# ---- 3. 计划任务 -----------------------------------------------------
Write-Host "`n[3/6] 删除计划任务 (更新x2 + WNS推送唤醒)" -ForegroundColor Green
'WpsUpdateLogonTask_*','WpsUpdateTask_*','WpsWakeWnsLogonTask' | ForEach-Object {
    Get-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.TaskName, '删除计划任务')) {
            Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false
            Write-Host "  已删除任务 $($_.TaskName)"
        }
    }
}

# ---- 4. 组件剪裁 -----------------------------------------------------
# 策略(经 2026-10-19 二分定位+视觉验证): addons 采用白名单保留制。
# knetwork 是编辑器启动硬依赖, 缺失必现"无法恢复的错误"页; 其余全部可裁。
# (kmultcatalog/knewdoc/knewdocs/cef/everythingsearch 等均已在隔离集内实测通过)
Write-Host "`n[4/6] 剪裁 addons (白名单保留制, 移入隔离区)" -ForegroundColor Green
$keepAddons = @('knetwork')
$addonsRoot = Join-Path $office 'addons'
Get-ChildItem $addonsRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $keepAddons -notcontains $_.Name } |
    ForEach-Object { Move-ToQuarantine $_.FullName }

# office6 根下的独立可裁文件 (wpscloudsvr.exe 一并裁除, 依赖 compatible_type=1, 见步骤7)
@('wpscloudsvr.exe','wpscloudlaunch.exe','kwpswnsserver.exe','promecefpluginhost.exe',
  'wpslingxi.exe','photolaunch.exe','kcrashdumper.exe','kcrashdumper64.exe','transerr.exe',
  'qingnse.dll','qingnse64.dll','pintaskbar.exe','kwinappinstaller.exe') |
    ForEach-Object { Move-ToQuarantine (Join-Path $office $_) }
# 自动更新器 (整个 wtoolex)
Move-ToQuarantine (Join-Path $ver.FullName 'wtoolex')

# ---- 5. 防火墙(离线的保底线, 防止版本自愈/回传) ------------------------
Write-Host "`n[5/6] 添加防火墙出站阻断 (WPS 全部可执行文件)" -ForegroundColor Green
$exes = Get-ChildItem $Root -Recurse -Filter *.exe -ErrorAction SilentlyContinue |
        Where-Object FullName -notmatch '_quarantine'
$i = 0
foreach ($exe in $exes) {
    $name = "WPS-Offline-Block-$i"
    if (-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($exe.FullName, '防火墙阻断')) {
            New-NetFirewallRule -DisplayName $name -Direction Outbound -Program $exe.FullName `
                -Action Block | Out-Null
            New-NetFirewallRule -DisplayName "$name-In" -Direction Inbound -Program $exe.FullName `
                -Action Block | Out-Null
        }
    }
    $i++
}
Write-Host "  已为 $i 个可执行文件添加出入站阻断"

# ---- 6. 入口修正 -----------------------------------------------------
Write-Host "`n[6/6] 修正开始菜单快捷方式 (ksolaunch -> wps 编辑器)" -ForegroundColor Green
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\WPS Office.lnk"
if (Test-Path $lnk) {
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($lnk)
    if ($PSCmdlet.ShouldProcess($lnk, "改指向 wps.exe")) {
        $s.TargetPath = "$office\wps.exe"
        $s.Save()
        Write-Host "  WPS Office.lnk -> wps.exe"
    }
}

# ---- 7. 官方离线未登录兼容开关 (核心步骤, 必须保留) ----------------------
# !! 实测教训: 旧版 kshell.dll 横幅补丁(31C0C3)只遮横幅, 且会把功能区打入 disabled
#    (命令启用状态机依赖同一批判定), 是"工具栏灰死"的直接元凶, 已废弃。
# 正解 = WPS 官方配置工具(ksomisc.exe)里的
#   「其他选项 → 离线特殊兼容 → 兼容离线状态下的未登录使用方式」
# 落点: HKCU\Software\Kingsoft\Office\6.0\Common : compatible_type = 1 (dword)
# 效果(终版实测, 含删除 wpscloudsvr 服务+exe 的组合): 横幅降级为普通推荐条,
#   功能区命令激活, 色板/选色/编辑/保存全部正常 —— 此开关独立兜住登录态。
Write-Host "`n[7] 官方离线未登录兼容开关 (compatible_type=1)" -ForegroundColor Green
$commonKey = 'HKCU:\Software\Kingsoft\Office\6.0\Common'
if ($PSCmdlet.ShouldProcess($commonKey, '设置 compatible_type=1')) {
    New-Item -ItemType Directory -Force -Path $commonKey | Out-Null
    New-ItemProperty -Path $commonKey -Name 'compatible_type' -Value 1 `
        -PropertyType DWord -Force | Out-Null
    Write-Host "  compatible_type=1 已写入 (重启 WPS 生效)"
}

# 7b. 功能定制开关 (通用方案: UIA 自动化驱动 ksomisc, 无需人工操作)
# 逆向定位: 13 项开关写入 kic\switch\user (AES-ECB 加密, 密钥在二进制内)。
# 通用解法 = 用 Windows UIA 自动驱动 ksomisc.exe 界面完成勾选,
# ksomisc 在自己进程内做加密, 不依赖任何机器特定 blob。
$ksomiscAuto = Join-Path $PSScriptRoot "tools\patches\ksomisc_auto.ps1"
if (Test-Path $ksomiscAuto) {
    Write-Host "  [通用] 通过 UIA 自动化驱动 ksomisc 完成功能定制..."
    if ($PSCmdlet.ShouldProcess('ksomisc UIA automation', '自动化功能定制')) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $ksomiscAuto
        Write-Host "  功能定制完成 (关闭推荐/隐藏菜单/关自动更新)"
    }
} else {
    Write-Host "  [提示] ksomisc_auto.ps1 不存在, 跳过功能定制"
    Write-Host "  可手动运行 ksomisc.exe 勾选, 或确认 tools\patches\ksomisc_auto.ps1 存在"
}

# ---- 8. 云端下发插件池 + 死插件声明 ------------------------------------
Write-Host "`n[8] 清空云端插件池 + 精简插件注册声明" -ForegroundColor Green
# 云端按需下载的插件落点(实测曾沉淀38个: kpubaigcbox/kwpsaigc/kpromeaccountpanel 等)
$pool = "$env:APPDATA\Kingsoft\wps\addons\pool"
if (Test-Path $pool) {
    $dst = Join-Path $quar (($pool -replace '[:\\]+','_'))
    if (-not (Test-Path $dst)) {
        if ($PSCmdlet.ShouldProcess($pool, '移入隔离区')) {
            New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
            Move-Item $pool $dst -Force
            New-Item -ItemType Directory -Force -Path "$pool\win-x64" | Out-Null
            Write-Host "  插件池已清空(重建空目录防下载器报错)"
        }
    }
}
# setupplugin.plg: 移除指向已裁 addon 的声明(实测安全, 窗口结构不变)
$plg = Join-Path $office 'setupplugincfg\setupplugin.plg'
if (Test-Path $plg) {
    if (-not (Test-Path "$plg.korig")) { Copy-Item $plg "$plg.korig" }
    $xml = [xml](Get-Content $plg -Raw -Encoding UTF8)
    $addonsHere = @(Get-ChildItem (Join-Path $office 'addons') -Directory | Select-Object -ExpandProperty Name)
    $removed = 0
    foreach ($node in @($xml.plugins.'#text')) {}
    # 逐 plugin 节点过滤
    $allPlugins = @($xml.SelectNodes('//plugin'))
    foreach ($p in $allPlugins) {
        $nm = $p.GetAttribute('name')
        if ($nm -and ($addonsHere -notcontains $nm)) {
            [void]$p.ParentNode.RemoveChild($p); $removed++
        }
    }
    $xml.Save($plg)
    Write-Host "  setupplugin.plg: 移除 $removed 条死插件声明(备份 .korig)"
}

# ---- 9. WPS云盘 命名空间(此电脑/桌面残留挂载) -------------------------
Write-Host "`n[9] 移除 WPS云盘 资源管理器命名空间" -ForegroundColor Green
$nsKeys = @(
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{EEEEFCF7-867B-4FA2-9ABD-884CF531B600}',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{EEEEFCF7-867B-4FA2-9ABD-884CF531B602}'
)
foreach ($k in $nsKeys) {
    if (Test-Path $k) {
        if ($PSCmdlet.ShouldProcess($k, '删除命名空间键')) {
            Remove-Item $k -Recurse -Force
            Write-Host "  已删除 $k"
        }
    }
}
Write-Host "  (重启资源管理器后生效: Stop-Process -Name explorer -Force)"

# ---- 10. 界面纯净补丁: 去掉 会员专享 / WPS AI / 稻壳AI模板 三个内置标签 ----
# 逆向定位(2026-10-20, 全部实测验证):
#   会员专享 = wpsongmani.kui 的 <KRbControlCommand id="CT_WorkSpace" idKey="CommonVipTab">, 删除元素即消失
#   WPS AI   = 各 ongmani 的 <KRbTabProxyCommand id="CT_Copilot">, 同上删除即消失
#   稻壳AI模板 = kprometheus.dll!KPromeDocerTabButtonCtrl::createDocerTabButton (RVA 0x58AC80)
#              函数入口写 31 C0 C3 (xor eax,eax; ret = 恒"未创建", 是程序合法返回路径)
#   附带: officenav.kui 删除 newfromtemplate/AI 入口(首页纯净)
#   注: 改 kuip 后必须清 %APPDATA%\Kingsoft\office6\cache (编译缓存), 否则不生效
Write-Host "`n[10] 界面纯净补丁 (去三个内置推广标签)" -ForegroundColor Green
$patchTool = Join-Path $env:TEMP "wps_tab_patch.py"
@'
import os, re, shutil, sys
BASE = os.environ['WPS_OFFICE6']
def patch_file(path, transforms):
    if not os.path.exists(path):
        return
    src = open(path, encoding='utf-8', errors='replace').read()
    orig = src
    for f in transforms:
        src = f(src)
    if src != orig:
        bak = path + '.korig'
        if not os.path.exists(bak):
            shutil.copyfile(path, bak)
        open(path, 'w', encoding='utf-8').write(src)
        print("  kuip patched:", os.path.basename(path))

res = os.path.join(BASE, 'res')
for fn in ["wpsongmani.kui", "etongmani.kui", "wppongmani.kui", "ufdongmani.kui"]:
    patch_file(os.path.join(res, fn), [
        lambda s: re.sub(r'<KRbControlCommand[^>]*id="CT_WorkSpace"[^>]*/>\s*', '', s),
        lambda s: re.sub(r'<KRbTabProxyCommand[^>]*id="CT_Copilot"[^>]*/>\s*', '', s),
    ])
nav = os.path.join(BASE, r'addons\kstartpage\res\kuip\officenav.kui')
patch_file(nav, [
    lambda s: re.sub(r'<KTemplatePageEntry[^>]*id="newfromtemplate"[^>]*/>\s*', '', s),
    lambda s: re.sub(r'<KAIAssistantEntry[^>]*/>\s*', '', s),
    lambda s: re.sub(r'<KAIPPTEntry[^>]*/>\s*', '', s),
    lambda s: re.sub(r'<KAINoteEntry[^>]*/>\s*', '', s),
    lambda s: re.sub(r'<KAcademicAIEntry[^>]*/>\s*', '', s),
    lambda s: re.sub(r'<KCmdPolicyUrlEntry[^>]*id="digitalemployee"[^>]*/>\s*', '', s),
])
print("  kuip patches done")
'@ | Set-Content -Path $patchTool -Encoding UTF8
$env:WPS_OFFICE6 = $office
python $patchTool

# kprometheus.dll 二进制补丁 (版本感知, 验证 prologue 后才写)
$kprom = Join-Path $office 'kprometheus.dll'
if (Test-Path $kprom) {
    # 补丁表: file_offset -> @{head=expected_hex; name=description}
    # 偏移表基于 12.1.0.29158; 其他版本自动跳过不匹配项
        $patches = @(
        @{off=0x58A080; head=0x48; name='createDocerTabButton (稻壳AI模板)'}
        @{off=0x1CF650; head=0x48; name='ensureCrossTerminalButton (WPS随行)'}
        @{off=0x2FEF00; head=0xE9; name='isCrossTerminalEntryVisible (WPS随行兜底)'}
        @{off=0x1D3B00; head=0x48; name='ensureAppMarketButton (应用市场)'}
        @{off=0x1E1D60; head=0x48; name='ensureMobileButton (手机同步)'}
        @{off=0x1E4D00; head=0x48; name='ensureStandardWhatsNewButton'}
        @{off=0x1EBFF0; head=0x48; name='ensureTemplateMarketButton'}
        @{off=0x1EF030; head=0x48; name='ensureWhatsNewButton'}
        @{off=0x1878D0; head=0x48; name='initCrossTerminalBtn'}
        @{off=0x18EBD0; head=0x48; name='CrossTerminalBtn ref1'}
        @{off=0x19D090; head=0x48; name='CrossTerminalBtn ref2'}
        @{off=0x1AC380; head=0x48; name='CrossTerminalBtn ref3'}
    )
    if ($PSCmdlet.ShouldProcess($kprom, '补丁 kprometheus 界面按钮')) {
        $fs = [System.IO.File]::Open($kprom, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
        $patched = 0; $skipped = 0
        try {
            foreach ($p in $patches) {
                $fs.Position = $p.off
                $head = $fs.ReadByte()
                $fs.Position = $p.off
                if ($head -eq 0x31) {
                    Write-Host "    [已补丁] $($p.name)" -ForegroundColor DarkGray
                } elseif ($head -eq $p.head) {
                    if (-not (Test-Path "$kprom.korig")) { Copy-Item $kprom "$kprom.korig" }
                    $fs.Write([byte[]](0x31, 0xC0, 0xC3), 0, 3)
                    Write-Host "    [补丁] $($p.name)" -ForegroundColor Yellow
                    $patched++
                } else {
                    Write-Host "    [跳过-版本不匹配] $($p.name) head=0x$('{0:x}' -f $head) (expect 0x$('{0:x}' -f $p.head))" -ForegroundColor DarkYellow
                    $skipped++
                }
            }
        } finally { $fs.Close() }
        Write-Host "  kprometheus: $patched 补丁 / $skipped 版本不匹配跳过 (备份 .korig)"
        if ($skipped -gt 0) {
            Write-Host "  [提示] 版本不匹配的补丁已跳过(安全)。如需支持新版本:" -ForegroundColor Cyan
            Write-Host "         运行 tools/patches/kprometheus_patch_map.py 重新定位偏移"
        }
    }
}
# 清 kuip 编译缓存
$kuipCache = "$env:APPDATA\Kingsoft\office6\cache"
if (Test-Path $kuipCache) {
    if ($PSCmdlet.ShouldProcess($kuipCache, '清除 kuip 编译缓存')) {
        Remove-Item $kuipCache -Recurse -Force
        Write-Host "  kuip 编译缓存已清(下次启动按新 kuip 重建)"
    }
}

Write-Host @"

=====================================================================
完成。验证方法:
  1. 双击 docx/xlsx/pptx/pdf 确认正常打开、编辑、保存、另存、打印
  2. 确认功能区(工具栏)可点击: 选中文字 -> 字体颜色 -> 色板能弹出
  3. 资源监视器/ netstat -b 确认 WPS 进程无外连(防火墙阻断兜底)
关键机制(2026-10-20 终版实测定型):
  - 登录门禁 = HKCU\Software\Kingsoft\Office\6.0\Common : compatible_type=1
    (即官方 配置和修复工具-其他选项-兼容离线状态下的未登录使用方式)
    此开关独立兜住登录态: 删除 wpscloudsvr 服务/exe 后功能区依然全功能。
  - wpscloudsvr 服务与 exe 已彻底移除(见步骤2/4), 离线由防火墙规则兜底。
回滚: 把 $quar 下所有条目拖回原位(目录名即原路径);
      防火墙规则: Remove-NetFirewallRule -DisplayName "WPS-Offline-Block*"
      开关还原: reg delete "HKCU\Software\Kingsoft\Office\6.0\Common" /v compatible_type /f
=====================================================================
"@ -ForegroundColor Cyan
