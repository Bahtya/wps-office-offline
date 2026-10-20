# kprometheus_patch_map.py - Version-aware patch offsets
# Each entry: { function_head_bytes: patch_offset_file }
# The patch_offset is a FILE OFFSET (not RVA). Verified by prologue bytes.
# To add a new version: run find_offset.py with the new kprometheus.dll

PATCHES = {
    "12.1.0.29158": {
        # file_offset -> (expected_head_hex, description)
        0x58A080: ("48895c24", "createDocerTabButton (稻壳AI模板)"),
        0x1CF650: ("48895c24", "ensureCrossTerminalButton (WPS随行)"),
        0x2FEF00: ("e93bfeff", "isCrossTerminalEntryVisible thunk (WPS随行兜底)"),
        0x1D3B00: ("48895c24", "ensureAppMarketButton (应用市场)"),
        0x1E1D60: ("48895c24", "ensureMobileButton (手机同步)"),
        0x1E4D00: ("48895c24", "ensureStandardWhatsNewButton (新功能引导)"),
        0x1EBFF0: ("48895c24", "ensureTemplateMarketButton (模板市场)"),
        0x1EF030: ("48895c24", "ensureWhatsNewButton (新功能)"),
        0x1878D0: ("48895c24", "initCrossTerminalBtn (WPS随行旧UI)"),
        0x18EBD0: ("48895c24", "CrossTerminalBtn ref1"),
        0x19D090: ("48895c24", "CrossTerminalBtn ref2"),
        0x1AC380: ("48895c24", "CrossTerminalBtn ref3"),
        0x2CE610: ("48895c24", "initUnloginedButton (登录按钮)"),
        0x2CEA70: ("4883ec28", "isUnloginRectangleButtonStyleVisible"),
    },
    # Add new versions here after running analysis
}

# kic switch type names for feature customization
KIC_SWITCHES_OFF = [
    "type.scene_recommend",      # 关闭场景化功能推荐
    "type.template",             # 关闭模板推荐
    "type.online_template",      # 关闭在线素材资源推荐
    "type.vas_shellext",         # 隐藏WPS扩展功能菜单项
    "type.cloud_shellext",       # 隐藏WPS云文档功能菜单项
    "type.compress_shellext",    # 隐藏WPS解压拓展菜单项
    "type.desktop_shellext",     # 隐藏WPS桌面拓展菜单项
    "type.recyclerecovery_shellext",  # 隐藏WPS回收站拓展菜单项
    "type.freediskspace_shellext",    # 隐藏WPS释放C盘空间功能菜单项
    "type.wpsai_shellext",       # 隐藏WPS AI拓展菜单项
    "type.edit_shellext",        # 隐藏编辑拓展菜单项
    "type.vas_shellnewext",      # 隐藏WPS新建拓展菜单项
]
