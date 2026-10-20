# Find ribbon font color button rect in the main window
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$pidCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, 5744)
$main = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
if (-not $main) { Write-Host 'main window not found'; exit 1 }

$fcName = '字体颜色(C)'
$fcCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $fcName)
$hits = $main.FindAll([System.Windows.Automation.TreeScope]::Descendants, $fcCond)
Write-Host ("hits={0}" -f $hits.Count)
foreach ($h in $hits) {
    $r = $h.Current.BoundingRectangle
    Write-Host ("HIT name=[{0}] class=[{1}] rect=({2},{3})-({4},{5})" -f $h.Current.Name, $h.Current.ClassName, [int]$r.X, [int]$r.Y, [int]($r.X + $r.Width), [int]($r.Y + $r.Height))
}
# also search plain 字体颜色 (ribbon button may have no (C))
$fcName2 = '字体颜色'
$fcCond2 = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $fcName2)
$hits2 = $main.FindAll([System.Windows.Automation.TreeScope]::Descendants, $fcCond2)
Write-Host ("hits2={0}" -f $hits2.Count)
foreach ($h in $hits2) {
    $r = $h.Current.BoundingRectangle
    Write-Host ("HIT2 name=[{0}] class=[{1}] rect=({2},{3})-({4},{5})" -f $h.Current.Name, $h.Current.ClassName, [int]$r.X, [int]$r.Y, [int]($r.X + $r.Width), [int]($r.Y + $r.Height))
}
