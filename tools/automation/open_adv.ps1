# Reopen advanced dialog, go to upgrade tab
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class AV{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
}
'@
[void][AV]::SetProcessDPIAware()
[void][AV]::SetCursorPos(960, 851)   # 高级(A)... button
Start-Sleep -Milliseconds 300
[AV]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[AV]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Seconds 3
Write-Host 'advanced opened'
