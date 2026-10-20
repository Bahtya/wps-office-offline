# DPI-aware clicks with scale-corrected physical coords
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC2{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
}
'@
[void][DC2]::SetProcessDPIAware()

function Click($x, $y, $label) {
    [void][DC2]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 350
    [DC2]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 90
    [DC2]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Write-Host "clicked [$label] at ($x,$y)"
    Start-Sleep -Milliseconds 900
}

Click 2227 977 'popup-hide'
Click 1350 1300 'main-ok'
Start-Sleep -Seconds 3
$p = Get-Process -Id 17224 -ErrorAction SilentlyContinue
if ($p) { Write-Host 'ksomisc alive' } else { Write-Host 'ksomisc exited' }
