# Check if ribbon dock windows are disabled; re-enable them
Add-Type -TypeDefinition @'
using System;using System.Text;using System.Runtime.InteropServices;
public class WE{
 [DllImport("user32.dll")]public static extern bool EnumChildWindows(IntPtr h,EnumChildProc cb,IntPtr l);
 public delegate bool EnumChildProc(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]public static extern bool IsWindowEnabled(IntPtr h);
 [DllImport("user32.dll")]public static extern bool EnableWindow(IntPtr h,bool b);
 public struct RECT{public int L,T,R,B;}
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
}
'@
# find main window of pid 19896
Add-Type -TypeDefinition @'
using System;using System.Text;using System.Runtime.InteropServices;
public class WM{
 [DllImport("user32.dll")]public static extern bool EnumWindows(EnumWindowsProc cb,IntPtr l);
 public delegate bool EnumWindowsProc(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")]public static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
}
'@
$mainHwnd = [IntPtr]::Zero
$cb = {
    param([IntPtr]$h,[IntPtr]$l)
    $wpid = 0
    [void][WM]::GetWindowThreadProcessId($h,[ref]$wpid)
    if ($wpid -eq 19896 -and [WM]::IsWindowVisible($h)) {
        $cn = New-Object System.Text.StringBuilder 256
        [void][WM]::GetClassName($h,$cn,256)
        if ($cn.ToString() -eq 'OpusApp') { Set-Variable -Name mainHwnd -Value $h -Scope 1 }
    }
    return $true
}
[void][WM]::EnumWindows($cb,[IntPtr]::Zero)
# re-find via script-scope var
$script:mainHwnd = [IntPtr]::Zero
$cb2 = {
    param([IntPtr]$h,[IntPtr]$l)
    $wpid = 0
    [void][WM]::GetWindowThreadProcessId($h,[ref]$wpid)
    if ($wpid -eq 19896 -and [WM]::IsWindowVisible($h)) {
        $cn = New-Object System.Text.StringBuilder 256
        [void][WM]::GetClassName($h,$cn,256)
        if ($cn.ToString() -eq 'OpusApp') { $script:mainHwnd = $h }
    }
    return $true
}
[void][WM]::EnumWindows($cb2,[IntPtr]::Zero)
Write-Host ("main=0x{0:X}" -f $script:mainHwnd.ToInt64())

$cbc = {
    param([IntPtr]$h,[IntPtr]$l)
    $cn = New-Object System.Text.StringBuilder 256
    [void][WE]::GetClassName($h,$cn,256)
    $c = $cn.ToString()
    $tt = New-Object System.Text.StringBuilder 256
    [void][WE]::GetWindowText($h,$tt,256)
    $r = New-Object WE+RECT
    [void][WE]::GetWindowRect($h,[ref]$r)
    $vis = [WE]::IsWindowVisible($h)
    $en = [WE]::IsWindowEnabled($h)
    if ($vis -and ($c -match 'Mso' -or $c -match 'OpusApp' -or $c -match '_Ww')) {
        Write-Host ("hwnd=0x{0:X} class=[{1}] title=[{2}] rect=({3},{4})-({5},{6}) enabled={7}" -f $h.ToInt64(),$c,$tt.ToString(),$r.L,$r.T,$r.R,$r.B,$en)
    }
    return $true
}
[void][WE]::EnumChildWindows($script:mainHwnd,$cbc,[IntPtr]::Zero)
