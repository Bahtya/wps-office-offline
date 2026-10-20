# Enumerate all KToolButton elements in the ribbon with rects
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$pidCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, 5744)
$main = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
if (-not $main) { Write-Host 'main not found'; exit 1 }

$classCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty, 'KToolButton')
$btns = $main.FindAll([System.Windows.Automation.TreeScope]::Descendants, $classCond)
Write-Host ("KToolButton count={0}" -f $btns.Count)
$i = 0
foreach ($b in $btns) {
    $r = $b.Current.BoundingRectangle
    if ($true) {
        Write-Host ("BTN{0} name=[{1}] rect=({2},{3})-({4},{5}) enabled={6}" -f $i, $b.Current.Name, [int]$r.X, [int]$r.Y, [int]($r.X+$r.Width), [int]($r.Y+$r.Height), $b.Current.IsEnabled)
    }
    $i++
}
