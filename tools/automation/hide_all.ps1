# Auto-loop: dismiss current popup, then check each hide-item and confirm its popup, finally OK
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class AU{
 [DllImport("user32.dll")]public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
}
'@
[void][AU]::SetProcessDPIAware()
function Click($x, $y, $ms = 900) {
    [void][AU]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 300
    [AU]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 90
    [AU]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds $ms
}

# 1. current popup (AI item): click 隐藏
Click 1733 1024 800

# 2. loop over the 10 hide-items (checkbox x=996; popup-confirm at 1733,1024)
$items = @(
    @(996, 723),   # 隐藏WPS扩展功能菜单项
    @(996, 786),   # 隐藏WPS新建拓展菜单项
    @(996, 846),   # 隐藏WPS云文档功能菜单项
    @(996, 908),   # 隐藏WPS桌面拓展菜单项
    @(996, 969),   # 隐藏WPS回收站拓展菜单项
    @(996, 1030),  # 隐藏WPS解压拓展菜单项
    @(996, 1092),  # 隐藏WPS释放C盘空间功能菜单项
    @(996, 1153),  # 隐藏WPS清理重复文件功能菜单项
    @(996, 1215),  # 隐藏编辑拓展菜单项
    @(996, 1276)   # 隐藏WPS AI拓展菜单项
)
$i = 0
foreach ($it in $items) {
    $i++
    Click $it[0] $it[1] 1000    # click checkbox
    Click 1733 1024 700         # confirm popup 隐藏 (if any)
    Write-Host "item $i done"
}

# 3. main OK
Click 1991 1426 1200
Write-Host 'ALL DONE - OK clicked'
