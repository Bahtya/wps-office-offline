# Corrected probe: find the DOC window across all wps pids, report ribbon combo state + banner
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$all = $root.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
$target = $null
foreach ($w in $all) {
    if ($w.Current.ProcessId -in @((Get-Process wps -ErrorAction SilentlyContinue).Id) -and $w.Current.Name -match 'WPS Office') {
        $target = $w
        break
    }
}
if (-not $target) { Write-Host 'doc window not found'; exit 1 }
Write-Host ("window: [{0}] pid={1}" -f $target.Current.Name, $target.Current.ProcessId)

$cbCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::ComboBox)
$cbs = $target.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cbCond)
$en = 0; $dis = 0
foreach ($c in $cbs) {
    $r = $c.Current.BoundingRectangle
    if ($r.Y -lt 170 -and $r.Height -gt 0) {
        if ($c.Current.IsEnabled) { $en++ } else { $dis++ }
        Write-Host ("  ribbon combo y={0} enabled={1}" -f [int]$r.Y, $c.Current.IsEnabled)
    }
}
Write-Host ("RIBBON COMBOS enabled={0} disabled={1}" -f $en, $dis)

$bCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, '立即登录')
$b = $target.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $bCond)
Write-Host ("login-banner present: {0}" -f [bool]$b)
