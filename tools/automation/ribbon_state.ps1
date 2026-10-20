# Objective ribbon-state probe: are the font/size ribbon groups enabled?
# args: pid
param([int]$ProcId = 24556)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$pidCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $ProcId)
$main = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
if (-not $main) { Write-Host 'main not found'; exit 1 }

$classCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty, 'KToolButton')
$btns = $main.FindAll([System.Windows.Automation.TreeScope]::Descendants, $classCond)
$en = 0; $dis = 0
foreach ($b in $btns) {
    if ($b.Current.IsEnabled) { $en++ } else { $dis++ }
}
Write-Host ("KToolButton enabled={0} disabled={1} total={2}" -f $en, $dis, $btns.Count)

# comboboxes (font name / size boxes in ribbon)
$cbCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::ComboBox)
$cbs = $main.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cbCond)
foreach ($c in $cbs) {
    $r = $c.Current.BoundingRectangle
    if ($r.Y -lt 160) {
        Write-Host ("RIBBON COMBO name=[{0}] value=[{1}] enabled={2} rect=({3},{4})" -f $c.Current.Name, $c.Current.GetValue([System.Windows.Automation.ValuePattern]::Pattern), $c.Current.IsEnabled, [int]$r.X, [int]$r.Y)
    }
}
