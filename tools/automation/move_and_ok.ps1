# Move ksomisc main window back onscreen, then click its OK button
Add-Type -TypeDefinition @'
using System;using System.Text;using System.Runtime.InteropServices;
public class MV{
 [DllImport("user32.dll")]public static extern bool EnumWindows(EnumWindowsProc cb,IntPtr l);
 public delegate bool EnumWindowsProc(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int ht,bool repaint);
 [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 public struct RECT{public int L,T,R,B;}
}
'@
# find the widest visible ksomisc window (the real one with tabs)
$script:best = [IntPtr]::Zero; $script:bestW = 0
$cb = {
    param([IntPtr]$h,[IntPtr]$l)
    $wpid = 0
    [void][MV]::GetWindowThreadProcessId($h,[ref]$wpid)
    if ($wpid -eq 17224 -and [MV]::IsWindowVisible($h)) {
        $sb = New-Object System.Text.StringBuilder 256
        [void][MV]::GetWindowText($h,$sb,256)
        $cn = New-Object System.Text.StringBuilder 256
        [void][MV]::GetClassName($h,$cn,256)
        if ($cn.ToString() -eq 'Qt5QWindow' -and $sb.Length -gt 0) {
            $r = New-Object MV+RECT
            [void][MV]::GetWindowRect($h,[ref]$r)
            $w = $r.R - $r.L
            if ($w -gt $script:bestW) { $script:bestW = $w; $script:best = $h }
        }
    }
    return $true
}
[void][MV]::EnumWindows($cb,[IntPtr]::Zero)
if ($script:best -eq [IntPtr]::Zero) { Write-Host 'no window'; exit 1 }
Write-Host ("moving hwnd=0x{0:X}" -f $script:best.ToInt64())
[void][MV]::MoveWindow($script:best, 100, 80, 700, 600, $true)
Start-Sleep -Milliseconds 600
[void][MV]::SetForegroundWindow($script:best)
Start-Sleep -Milliseconds 300
# OK button = bottom-right area of a 700x600 dialog: approx (100+560, 80+555)
[void][MV]::SetCursorPos(660, 635)
Start-Sleep -Milliseconds 400
[MV]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[MV]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
Write-Host 'clicked (660,635)'
Start-Sleep -Seconds 3
$p = Get-Process -Id 17224 -ErrorAction SilentlyContinue
if ($p) { Write-Host 'ksomisc still alive' } else { Write-Host 'ksomisc exited - OK accepted' }
