# Which window owns the ribbon point? And get rect of the invisible recovery bar elements
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class WP{
 [DllImport("user32.dll")]public static extern IntPtr WindowFromPoint(POINT p);
 [DllImport("user32.dll")]public static extern IntPtr GetAncestor(IntPtr h,uint f);
 [DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,System.Text.StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern int GetClassName(IntPtr h,System.Text.StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 public struct POINT{public int X;public int Y;public POINT(int x,int y){X=x;Y=y;}}
}
'@

# A+ button: image (358,100) -> logical (347,97) -> physical (694,194)
$pt = New-Object WP+POINT 694,194
$hw = [WP]::WindowFromPoint($pt)
$cn = New-Object System.Text.StringBuilder 256
$tt = New-Object System.Text.StringBuilder 256
[void][WP]::GetClassName($hw,$cn,256)
[void][WP]::GetWindowText($hw,$tt,256)
$root2 = [WP]::GetAncestor($hw,2)
Write-Host ("ribbon point hwnd=0x{0:X} class=[{1}] title=[{2}] visible={3} root=0x{4:X}" -f $hw.ToInt64(),$cn.ToString(),$tt.ToString(),[WP]::IsWindowVisible($hw),$root2.ToInt64())

# UIA rects for recovery bar elements (names contain 恢复 / 提醒 / 发送报告)
$pidCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, 19896)
$main = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
$names = @('立即恢复','不再提醒','发送报告','上一次未正常关闭，已恢复到最新版本。','如没有找到您的文件， 建议使用 金山数据恢复大师')
foreach ($n in $names) {
    $c = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $n)
    $el = $main.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $c)
    if ($el) {
        $r = $el.Current.BoundingRectangle
        Write-Host ("[{0}] rect=({1},{2})-({3},{4}) offscreen={5}" -f $n, [int]$r.X, [int]$r.Y, [int]($r.X+$r.Width), [int]($r.Y+$r.Height), $el.Current.IsOffscreen)
    } else { Write-Host ("[{0}] not found" -f $n) }
}
