# Clean up IME mess then redo acceptance
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class DB{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
}
'@
[void][DB]::SetProcessDPIAware()
function Click($x, $y, $ms = 600) {
    [void][DB]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 350
    [DB]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 90
    [DB]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
function Key($vk, $ms = 150) {
    [DB]::keybd_event([byte]$vk,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [DB]::keybd_event([byte]$vk,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}
Key 0x1B 300      # Esc: dismiss IME candidates
Key 0x08 300      # Backspace: remove stray char
Key 0x14 300      # (caps) no-op spacer
Click 1254 896 400  # canvas click (cursor to text)
Key 0x08 300      # Backspace again if stray char at cursor
# switch IME to English via Shift (common in MS Pinyin)
Key 0xA0 300      # Left Shift tap
Key 0x11 100; Key 0x41 200; Key 0x11 200   # Ctrl+A
Click 866 251 900   # font color arrow -> palette
Write-Host 'palette should be open now'
