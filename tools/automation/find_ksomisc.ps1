# Locate all visible top-level windows of ksomisc (pid 17224 and 19220)
Add-Type -TypeDefinition @'
using System;using System.Text;using System.Runtime.InteropServices;
public class KW2{
 [DllImport("user32.dll")]public static extern bool EnumWindows(EnumWindowsProc cb,IntPtr l);
 public delegate bool EnumWindowsProc(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 public struct RECT{public int L,T,R,B;}
}
'@
$cb = {
    param([IntPtr]$h,[IntPtr]$l)
    $wpid = 0
    [void][KW2]::GetWindowThreadProcessId($h,[ref]$wpid)
    if (($wpid -eq 17224 -or $wpid -eq 19220) -and [KW2]::IsWindowVisible($h)) {
        $sb = New-Object System.Text.StringBuilder 256
        [void][KW2]::GetWindowText($h,$sb,256)
        $cn = New-Object System.Text.StringBuilder 256
        [void][KW2]::GetClassName($h,$cn,256)
        $r = New-Object KW2+RECT
        [void][KW2]::GetWindowRect($h,[ref]$r)
        Write-Host ("pid={0} hwnd=0x{1:X} class=[{2}] title=[{3}] rect=({4},{5})-({6},{7})" -f $wpid,$h.ToInt64(),$cn.ToString(),$sb.ToString(),$r.L,$r.T,$r.R,$r.B)
    }
    return $true
}
[void][KW2]::EnumWindows($cb,[IntPtr]::Zero)
