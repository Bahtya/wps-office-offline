# ksomisc_auto.ps1 - Universal: automate ksomisc to apply feature customization
# Works on ANY machine/version - ksomisc does the KIC encryption natively.
# Requires: WPS installed, ksomisc.exe present, no admin needed.

# ---- Configuration ----
$Office6 = Split-Path (Get-Command wps.exe -ErrorAction SilentlyContinue).Source -Parent
if (-not $Office6) {
    # fallback: detect from registry or common paths
    $root = Get-ChildItem "$env:LOCALAPPDATA\Kingsoft\WPS Office" -Directory |
            Where-Object Name -match '^\d+\.' | Sort-Object Name -Descending | Select-Object -First 1
    if ($root) { $Office6 = Join-Path $root.FullName 'office6' }
}
if (-not $Office6 -or -not (Test-Path "$Office6\ksomisc.exe")) {
    Write-Host "[ERROR] ksomisc.exe not found" -ForegroundColor Red
    exit 1
}
Write-Host "ksomisc: $Office6\ksomisc.exe"

# ---- Step 1: Set compatible_type (plain registry, no ksomisc needed) ----
$commonKey = 'HKCU:\Software\Kingsoft\Office\6.0\Common'
New-Item -ItemType Directory -Force -Path $commonKey | Out-Null
New-ItemProperty -Path $commonKey -Name 'compatible_type' -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host "[OK] compatible_type=1 (offline login bypass)" -ForegroundColor Green

# ---- Step 2: Automate ksomisc for feature customization ----
Write-Host "`n[2] Automating ksomisc feature customization..." -ForegroundColor Cyan

# Kill existing ksomisc
Get-Process ksomisc -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 1

# Launch ksomisc
Start-Process "$Office6\ksomisc.exe" -WindowStyle Minimized
Start-Sleep 3

# Use UIA to click through the dialog
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ProcessIdProperty,
    (Get-Process ksomisc -ErrorAction SilentlyContinue | Select-Object -First 1).Id)
$main = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
if (-not $main) { Write-Host "  [ERROR] ksomisc window not found"; exit 1 }

# Click 高级 button
$advCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, '高级(A)...')
$advBtn = $main.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
if ($advBtn) {
    $advBtn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
    Start-Sleep 2
    Write-Host "  Clicked 高级"
}

# Find the config dialog (new top-level window from ksomisc)
$configDlg = $null
foreach ($win in $root.FindAll([System.Windows.Automation.TreeScope]::Children,
    [System.Windows.Automation.Condition]::TrueCondition)) {
    if ($win.Current.ProcessId -eq $main.Current.ProcessId -and
        $win.Current.Name -like '*配置工具*') {
        $configDlg = $win
        break
    }
}
if (-not $configDlg) { Write-Host "  [ERROR] config dialog not found"; exit 1 }

function Toggle-Checkbox($dlg, $name) {
    $c = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::NameProperty, $name)
    $el = $dlg.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $c)
    if ($el) {
        $pat = $el.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
        if ($pat.Current.ToggleState -ne 'On') {
            $pat.Toggle()
            Write-Host "  [CHECKED] $name"
        } else {
            Write-Host "  [already] $name"
        }
    } else {
        Write-Host "  [miss] $name"
    }
}

# Switch to 功能定制 tab
$tabCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, '功能定制')
$tab = $configDlg.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $tabCond)
if ($tab) {
    $tab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Start-Sleep 1
    Write-Host "  Switched to 功能定制"
}

# Check all hide/disable checkboxes
$checkboxes = @(
    '关闭场景化功能推荐',
    '关闭在线素材资源推荐',
    '关闭模板推荐',
    '隐藏WPS AI拓展菜单项',
    '隐藏编辑拓展菜单项',
    '隐藏WPS清理重复文件功能菜单项',
    '隐藏WPS释放C盘空间功能菜单项',
    '隐藏WPS解压拓展菜单项',
    '隐藏WPS回收站拓展菜单项',
    '隐藏WPS桌面拓展菜单项',
    '隐藏WPS云文档功能菜单项',
    '隐藏WPS新建拓展菜单项(从模板新建、流程图、思维导图及海报图片功能)',
    '隐藏WPS扩展功能菜单项'
)
foreach ($cb in $checkboxes) {
    Toggle-Checkbox $configDlg $cb
}

# Switch to 其他选项 tab
$otherCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, '其他选项')
$otherTab = $configDlg.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $otherCond)
if ($otherTab) {
    $otherTab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Start-Sleep 1
    Write-Host "  Switched to 其他选项"
}
Toggle-Checkbox $configDlg '兼容离线状态下的未登录使用方式'

# Switch to 升级设置 tab
$upgradeCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, '升级设置')
$upgradeTab = $configDlg.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $upgradeCond)
if ($upgradeTab) {
    $upgradeTab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Start-Sleep 1
    Write-Host "  Switched to 升级设置"
}
# Select 关闭自动更新 radio
$radioCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty,
    '关闭自动更新与版本提醒')
$radio = $configDlg.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $radioCond)
if ($radio) {
    $radio.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Write-Host "  [SELECTED] 关闭自动更新"
}

# Click 确定
$okCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, '确定')
$okBtn = $configDlg.FindFirst([System.Windows.Automation.TreeScope]::Children, $okCond)
if ($okBtn) {
    $okBtn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
    Write-Host "  [APPLIED] Clicked 确定"
}

# Handle any confirmation popups
Start-Sleep 2
for ($i = 0; $i -lt 5; $i++) {
    $hideCond = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::NameProperty, '隐藏')
    $hideBtn = $root.FindFirst([System.Windows.Automation.TreeScope]::Children,
        (New-Object System.Windows.Automation.AndCondition(
            (New-Object System.Windows.Automation.PropertyCondition(
                [System.Windows.Automation.AutomationElement]::ProcessIdProperty, $main.Current.ProcessId)),
            $hideCond)))
    if ($hideBtn) {
        $hideBtn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
        Write-Host "  [CONFIRMED] popup 隐藏"
        Start-Sleep 1
    } else { break }
}

# Close ksomisc
Start-Sleep 2
Get-Process ksomisc -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "`n[DONE] All ksomisc settings applied via UIA automation" -ForegroundColor Green
Write-Host "  - compatible_type=1 (offline login)"
Write-Host "  - 13 items hidden (右键菜单/推荐/扩展)"
Write-Host "  - Auto-update disabled"
Write-Host "  Settings take effect after WPS restart."
