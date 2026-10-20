# Read ksomisc state: enumerate ALL descendants with toggle pattern
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$pidCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, 17224)
$main = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
if (-not $main) { Write-Host 'window not found'; exit 1 }

$all = $main.FindAll([System.Windows.Automation.TreeScope]::Descendants, $pidCond)
Write-Host ("total elements: {0}" -f $all.Count)
foreach ($e in $all) {
    $ct = $e.Current.ControlType.ProgrammaticName
    if ($ct -match 'CheckBox' -or $ct -match 'TabItem' -or $ct -match 'Button') {
        $st = ''
        try { $st = $e.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern).Current.ToggleState } catch {}
        $sel = ''
        try { $sel = ' sel=' + $e.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Current.IsSelected } catch {}
        Write-Host ("{0} [{1}] toggle={2}{3}" -f $ct, $e.Current.Name, $st, $sel)
    }
}
