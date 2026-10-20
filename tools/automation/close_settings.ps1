# Close Settings window (corrected physical coords) then capture
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC4{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
}
'@
[void][DC4]::SetProcessDPIAware()
[void][DC4]::SetCursorPos(1644, 96)
Start-Sleep -Milliseconds 300
[DC4]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[DC4]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Seconds 2
Write-Host 'clicked settings X at (1644,96)'
