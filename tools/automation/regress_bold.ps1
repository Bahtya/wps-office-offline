# Regression with actual change: select all -> Bold -> save -> verify -> undo -> save
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DN{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DN]::SetProcessDPIAware()
function Click($x, $y, $ms = 700) {
    [void][DN]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 350
    [DN]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 90
    [DN]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
function Chord($a, $b, $ms = 500) {
    [DN]::keybd_event([byte]$a,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 100
    [DN]::keybd_event([byte]$b,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 100
    [DN]::keybd_event([byte]$b,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 80
    [DN]::keybd_event([byte]$a,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
Click 1254 896 500          # canvas
Chord 0x11 0x41              # ctrl+a
Click 350 260                # Bold B button (ribbon row1 left)
Start-Sleep -Milliseconds 800
Chord 0x11 0x53              # ctrl+s
Write-Host 'bold+save sent'
