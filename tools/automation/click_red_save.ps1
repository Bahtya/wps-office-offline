# Click red swatch, then Ctrl+S
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC7{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DC7]::SetProcessDPIAware()

# red swatch (standard colors row, 2nd)
[void][DC7]::SetCursorPos(884, 626)
Start-Sleep -Milliseconds 400
[DC7]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[DC7]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 1000
Write-Host 'red clicked'

# Ctrl+S save
[DC7]::keybd_event(0x11,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 60
[DC7]::keybd_event(0x53,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 60
[DC7]::keybd_event(0x53,0,2,[UIntPtr]::Zero)
[DC7]::keybd_event(0x11,0,2,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 1500
Write-Host 'saved'
