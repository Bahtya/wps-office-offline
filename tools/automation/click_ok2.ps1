# Click OK button of ksomisc at absolute screen coords
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class MC{
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
}
'@
[void][MC]::SetCursorPos(1029, 684)
Start-Sleep -Milliseconds 400
[MC]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[MC]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
Write-Host 'OK clicked at (1029,684)'
Start-Sleep -Seconds 3
Get-Process ksomisc -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ("ksomisc still: " + $_.Id) }
