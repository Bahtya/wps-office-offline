# Use UIAutomation to get bounding rect of the font color dropdown inside WPS
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$pidCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, 5744)
$main = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
if (-not $main) { Write-Host 'main window not found'; exit 1 }
Write-Host ("main: [{0}]" -f $main.Current.Name)

$fcName = '字体颜色(C)'
$fcCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $fcName)
$fc = $main.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $fcCond)
if (-not $fc) { Write-Host 'font color element not found'; exit 1 }
$fr = $fc.Current.BoundingRectangle
Write-Host ("FCCOLOR rect=({0},{1})-({2},{3})" -f [int]$fr.X, [int]$fr.Y, [int]($fr.X + $fr.Width), [int]($fr.Y + $fr.Height))
$kids = $fc.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
foreach ($k in $kids) {
    $kr = $k.Current.BoundingRectangle
    Write-Host ("CHILD name=[{0}] class=[{1}] rect=({2},{3})-({4},{5})" -f $k.Current.Name, $k.Current.ClassName, [int]$kr.X, [int]$kr.Y, [int]($kr.X + $kr.Width), [int]($kr.Y + $kr.Height))
}
