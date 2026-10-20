# Click red, remove stray A, save
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC8{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DC8]::SetProcessDPIAware()
function Click($x, $y, $ms = 700) {
    [void][DC8]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 350
    [DC8]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 90
    [DC8]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
function Key($vk, $ms = 150) {
    [DC8]::keybd_event([byte]$vk,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [DC8]::keybd_event([byte]$vk,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
Click 884 626        # red swatch (applies to current selection)
Click 725 838 400    # click right of stray 'A'
Key 0x08 300         # backspace delete 'A'
Key 0x11 100; Key 0x53 300; Key 0x11 200   # ctrl+s save
Write-Host 'red applied, stray char removed, saved'
