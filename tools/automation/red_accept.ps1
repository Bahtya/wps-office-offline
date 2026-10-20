# Red-text acceptance: canvas focus, select all, click font-color arrow, screenshot
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DC5{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DC5]::SetProcessDPIAware()

function Click($x, $y) {
    [void][DC5]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 350
    [DC5]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 90
    [DC5]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 600
}
function CtrlA() {
    [DC5]::keybd_event(0x11,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [DC5]::keybd_event(0x41,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [DC5]::keybd_event(0x41,0,2,[UIntPtr]::Zero)
    [DC5]::keybd_event(0x11,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 400
}

Click 1254 896      # canvas focus
CtrlA               # select all
Click 846 251       # font color dropdown arrow
Write-Host 'done: focus + ctrl+a + fontcolor arrow'
