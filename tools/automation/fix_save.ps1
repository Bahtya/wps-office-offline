# Delete stray char and save
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC9{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DC9]::SetProcessDPIAware()
function Key($vk, $ms = 200) {
    [DC9]::keybd_event([byte]$vk,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [DC9]::keybd_event([byte]$vk,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
Key 0x08      # backspace: delete stray char before cursor
Key 0x11 100
Key 0x53 400  # ctrl+s
Key 0x11 200
Write-Host 'backspace + ctrl+s sent'
