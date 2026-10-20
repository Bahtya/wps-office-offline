# re-wps — WPS Office 12.1.0.29158 离线纯净版逆向工程

## 最终方案（一键）

```powershell
# 精简（需管理员，自动提权）
powershell -ExecutionPolicy Bypass -File make-wps-offline.ps1

# 一键还原
powershell -ExecutionPolicy Bypass -File restore-wps.ps1
```

## 核心机制（实测定型）

| 层 | 机制 |
|---|---|
| 登录门禁 | `HKCU\Software\Kingsoft\Office\6.0\Common : compatible_type=1`（官方开关，独立兜住登录态） |
| 云服务 | wpscloudsvr 服务+exe 彻底移除；Everything 索引器移除 |
| 网络隔离 | 48 个 WPS 可执行文件防火墙出入站全阻断 |
| 插件裁剪 | addons 白名单制（仅留 knetwork）+ 81 个推广类插件二次隔离 + 云端插件池清空 |
| 界面纯净 | kuip XML 删除（会员专享/WPS AI 标签）+ kprometheus.dll 二进制 stub（稻壳AI模板/应用市场/WPS随行等 10+ 按钮） |
| 横幅 | 点击 X 永久关闭（状态存 KIC 加密库） |

## 目录结构

```
├── make-wps-offline.ps1    # 主精简脚本（10 步）
├── restore-wps.ps1         # 一键还原
├── WPS离线精简方案.md       # 完整逆向报告（12.1-12.9 节）
├── WPS_Setup_x64_29158.exe # 原始安装包（374MB）
├── evidence/               # REA 分析证据（wns 进程 dossier 等）
└── tools/
    ├── patches/            # 最终补丁脚本（登录门禁/界面纯净/插件清理）
    ├── analysis/           # 逆向工具（导出解析/反汇编/字符串定位/交叉引用）
    ├── automation/         # UI 自动化验证（截图/DPI/键盘鼠标/UIA 探针）
    ├── frida/              # Frida 运行时追踪脚本
    ├── debug/              # 调试产物（注册表快照/追踪输出/临时文件）
    ├── screenshots/        # 过程截图
    └── archive/            # 二分排查期工具（历史归档）
```

## 补丁清单（kprometheus.dll，RVA→31 C0 C3）

| RVA | 函数 | 效果 |
|---|---|---|
| 0x58A080 | createDocerTabButton | 稻壳AI模板按钮消失 |
| 0x1CF650 | ensureCrossTerminalButton | WPS随行消失 |
| 0x2FEF00 | isCrossTerminalEntryVisible | WPS随行（可见性兜底） |
| 0x1D3B00 | ensureAppMarketButton | 应用市场消失 |
| 0x1E1D60 | ensureMobileButton | 手机同步消失 |
| 0x1E4D00 | ensureStandardWhatsNewButton | 新功能引导消失 |
| 0x1EBFF0 | ensureTemplateMarketButton | 模板市场消失 |
| 0x1EF030 | ensureWhatsNewButton | 同上 |
| 0x1878D0 | initCrossTerminalBtn | WPS随行（旧 UI 路径） |
| 0x18EBD0 / 0x19D090 / 0x1AC380 | CrossTerminalBtn 引用族 | WPS随行（全部路径） |

kuip 删除元素：
- `res\wpsongmani.kui`: CT_WorkSpace（会员专享）+ CT_Copilot（WPS AI）
- `res\{et,wpp,ufd}ongmani.*`: CT_Copilot
- `addons\kstartpage\res\kuip\officenav.kui`: newfromtemplate + AI 入口×5

注意事项见报告 §11–12（证据链、踩坑记录、死胡同列表）。
