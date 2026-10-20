# Proper chord: ctrl down, s down, s up, ctrl up
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC10{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DC10]::SetProcessDPIAware()
[DC10]::keybd_event(0x11,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 120
[DC10]::keybd_event(0x53,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 120
[DC10]::keybd_event(0x53,0,2,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 120
[DC10]::keybd_event(0x11,0,2,[UIntPtr]::Zero)
Write-Host 'proper ctrl+s sent'
