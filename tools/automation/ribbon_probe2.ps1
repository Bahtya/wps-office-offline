# Objective probe: is the ribbon command state alive?
# Signal: the font-name/size combos in the ribbon become ENABLED once command state refreshes.
param([int]$ProcId = 16848)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$pidCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $ProcId)
$main = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
if (-not $main) { Write-Host 'main not found'; exit 1 }

$cbCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::ComboBox)
$cbs = $main.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cbCond)
$en = 0; $dis = 0; $rows = @()
foreach ($c in $cbs) {
    $r = $c.Current.BoundingRectangle
    if ($r.Y -lt 160 -and $r.Height -gt 0) {
        if ($c.Current.IsEnabled) { $en++ } else { $dis++ }
        $rows += ("combo y={0} name=[{1}] enabled={2}" -f [int]$r.Y, $c.Current.Name, $c.Current.IsEnabled)
    }
}
Write-Host ("RIBBON COMBOS enabled={0} disabled={1}" -f $en, $dis)
$rows | ForEach-Object { Write-Host "  $_" }

# 字号 group specifically
$fcCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, '字号')
$el = $main.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $fcCond)
if ($el) {
    Write-Host ("字号 group enabled={0}" -f $el.Current.IsEnabled)
}
# banner presence
$bCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, '立即登录')
$b = $main.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $bCond)
Write-Host ("login-banner present: {0}" -f [bool]$b)
