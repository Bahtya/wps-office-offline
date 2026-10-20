# Click the OK button of ksomisc config tool via real cursor
Add-Type -TypeDefinition @'
using System;using System.Text;using System.Runtime.InteropServices;
public class KW{
 [DllImport("user32.dll")]public static extern bool EnumWindows(EnumWindowsProc cb,IntPtr l);
 public delegate bool EnumWindowsProc(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 public struct RECT{public int L,T,R,B;}
}
'@
$targetPid = 17224
$script:hwnd = [IntPtr]::Zero
$cb = {
    param([IntPtr]$h,[IntPtr]$l)
    $wpid = 0
    [void][KW]::GetWindowThreadProcessId($h,[ref]$wpid)
    if ($wpid -eq $targetPid -and [KW]::IsWindowVisible($h)) {
        $sb = New-Object System.Text.StringBuilder 256
        [void][KW]::GetWindowText($h,$sb,256)
        if ($sb.ToString() -like '*WPS*') { $script:hwnd = $h }
    }
    return $true
}
[void][KW]::EnumWindows($cb,[IntPtr]::Zero)
if ($script:hwnd -eq [IntPtr]::Zero) { Write-Host 'window not found'; exit 1 }
$r = New-Object KW+RECT
[void][KW]::GetWindowRect($script:hwnd,[ref]$r)
Write-Host ("rect=({0},{1})-({2},{3})" -f $r.L,$r.T,$r.R,$r.B)
[void][KW]::SetForegroundWindow($script:hwnd)
Start-Sleep -Milliseconds 300
# 确定 = bottom-right primary button
$x = $r.R - 85; $y = $r.B - 45
Write-Host ("clicking OK at ({0},{1})" -f $x,$y)
[void][KW]::SetCursorPos($x,$y)
Start-Sleep -Milliseconds 400
[KW]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[KW]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Seconds 2
$still = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
if ($still) { Write-Host 'process still alive (window may have applied and closed UI, or click missed)' } else { Write-Host 'process exited - applied' }
