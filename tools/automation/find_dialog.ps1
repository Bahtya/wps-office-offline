# Enumerate child windows of WPS main window to find the font dialog
Add-Type -TypeDefinition @'
using System;using System.Text;using System.Runtime.InteropServices;
public class WC{
 [DllImport("user32.dll")]public static extern bool EnumChildWindows(IntPtr h,EnumChildProc cb,IntPtr l);
 public delegate bool EnumChildProc(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 public struct RECT{public int L,T,R,B;}
}
'@
$main = [IntPtr]0x2A047A
$cb = {
    param([IntPtr]$h,[IntPtr]$l)
    $sb = New-Object System.Text.StringBuilder 256
    [void][WC]::GetWindowText($h,$sb,256)
    $t = $sb.ToString()
    $cn = New-Object System.Text.StringBuilder 256
    [void][WC]::GetClassName($h,$cn,256)
    if ([WC]::IsWindowVisible($h)) {
        $r = New-Object WC+RECT
        [void][WC]::GetWindowRect($h,[ref]$r)
        if ($t -ne '' -or $r.R - $r.L -gt 300) {
            Write-Host ("hwnd=0x{0:X} class=[{1}] title=[{2}] rect=({3},{4})-({5},{6})" -f $h.ToInt64(),$cn.ToString(),$t,$r.L,$r.T,$r.R,$r.B)
        }
    }
    return $true
}
[void][WC]::EnumChildWindows($main,$cb,[IntPtr]::Zero)
