# Full acceptance without cloud service: focus, ctrl+a, arrow, red, save
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DA{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DA]::SetProcessDPIAware()
function Click($x, $y, $ms = 600) {
    [void][DA]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 350
    [DA]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 90
    [DA]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
function Key($vk) {
    [DA]::keybd_event([byte]$vk,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [DA]::keybd_event([byte]$vk,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 150
}
Click 1254 896 500      # canvas focus
Key 0x11; Key 0x41; Key 0x11   # ctrl+a
Click 866 251 900       # font color arrow -> palette
Click 884 626 900       # red swatch
Key 0x11; Key 0x53; Key 0x11   # ctrl+s
Write-Host 'sequence done: select-all, palette, red, save'
