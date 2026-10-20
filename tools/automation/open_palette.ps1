# Open color palette via arrow, then click red swatch
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC6{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
}
'@
[void][DC6]::SetProcessDPIAware()
[void][DC6]::SetCursorPos(866, 251)
Start-Sleep -Milliseconds 350
[DC6]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[DC6]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 800
Write-Host 'arrow clicked'
