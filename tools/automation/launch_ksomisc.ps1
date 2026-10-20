# Launch ksomisc and force its window onscreen at a known rect
Add-Type -TypeDefinition @'
using System;using System.Text;using System.Runtime.InteropServices;
public class KM{
 [DllImport("user32.dll")]public static extern bool EnumWindows(EnumWindowsProc cb,IntPtr l);
 public delegate bool EnumWindowsProc(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")]public static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int ht,bool r);
 [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
}
'@
Start-Process 'C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksomisc.exe'
Start-Sleep -Seconds 5
$proc = Get-Process ksomisc -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { Write-Host 'ksomisc not running'; exit 1 }
$targetPid = $proc.Id
Write-Host ("pid=" + $targetPid)
$script:hwnd = [IntPtr]::Zero
$cb = {
    param([IntPtr]$h,[IntPtr]$l)
    $wpid = 0
    [void][KM]::GetWindowThreadProcessId($h,[ref]$wpid)
    if ($wpid -eq $targetPid -and [KM]::IsWindowVisible($h)) {
        $cn = New-Object System.Text.StringBuilder 256
        [void][KM]::GetClassName($h,$cn,256)
        $tt = New-Object System.Text.StringBuilder 256
        [void][KM]::GetWindowText($h,$tt,256)
        # the real dialog has a title and is the widest
        if ($tt.Length -gt 4 -and $cn.ToString() -like 'Qt5Q*') {
            $r = New-Object KM+RECT2
        }
    }
    return $true
}
# simpler: enumerate and move every titled visible window of the pid to a sane rect
$cb2 = {
    param([IntPtr]$h,[IntPtr]$l)
    $wpid = 0
    [void][KM]::GetWindowThreadProcessId($h,[ref]$wpid)
    if ($wpid -eq $targetPid -and [KM]::IsWindowVisible($h)) {
        $tt = New-Object System.Text.StringBuilder 256
        [void][KM]::GetWindowText($h,$tt,256)
        if ($tt.Length -gt 4) {
            [void][KM]::MoveWindow($h, 80, 60, 1100, 800, $true)
            [void][KM]::SetForegroundWindow($h)
            Write-Host ("moved hwnd=0x{0:X} title=[{1}]" -f $h.ToInt64(), $tt.ToString())
        }
    }
    return $true
}
[void][KM]::EnumWindows($cb2,[IntPtr]::Zero)
Write-Host 'done'
