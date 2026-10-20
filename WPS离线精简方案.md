# WPS Office 逆向分析与离线精简方案

- **分析对象**: WPS Office 个人版 `12.1.0.29158`（NSIS v3.05 安装包 `WPS_Setup_29161.exe`）
- **安装位置**: `C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\`（约 1.6 GB，其中 `office6\addons` 占 810 MB）
- **分析工具**: REA + Ghidra 12.1.4（CLI 通道）、字符串/注册表/计划任务核查
- **日期**: 2026-10-19
- **配套脚本**: [make-wps-offline.ps1](./make-wps-offline.ps1)

---

## 1. 结论（TL;DR）

**可以做成离线版**，且不需要动任何核心二进制。WPS 的云/广告/推送/磁盘扫描全部挂载在
「服务 + 计划任务 + addons 插件目录 + 网络端点」四层上，与文字/表格/演示/PDF 编辑核心
（`wps.exe / et.exe / wpp.exe / wpspdf.exe` + 核心 DLL）是**进程与插件级隔离**的：

1. 删除 `wpscloudsvr` 服务（云插件宿主）；
2. 删除 3 个计划任务（更新 ×2 + WNS 推送唤醒）；
3. 剪裁 `addons` 里约 100 个云/营销/AI/搜索/图片插件目录（移入隔离区，可回滚）；
4. 防火墙阻断 WPS 全部 EXE 出站（离线保底，防版本自愈回传）。

文档打开链路不受影响：`.docx` 关联直接指向
`office6\wps.exe /prometheus /wps "%1"`（HKCU `WPS.Docx.6`），不经过任何云组件。

---

## 2. 证据链

### 2.1 `wpscloudsvr.exe` — 云服务其实是个"插件宿主"

- 服务注册：`sc qc wpscloudsvr` → `C:\Program Files\Kingsoft\office6\wpscloudsvr.exe`，以
  **LocalSystem** 运行（安装目录在 AppData，服务副本在 Program Files，两处各一份）。
- 二进制内嵌自述：*"Provides WPS Office Cloud service, which includes: Cloud Document,
  File Security, VIP services…"*
- 字符串证据（插件加载命令行）：

  ```
  Run /InstanceId:WpsCloudSvr /lookup_module=wpscloudsvrimp.dll /run_plugin /plugin_name=qing            (云文档)
  ... /plugin_name=messagepush       (消息推送)
  ... /plugin_name=kdocershop        (稻壳商城营销)
  ... /plugin_name=messagecenter     (消息中心)
  ... /plugin_name=krecentfile       (最近文件收集)
  ... /plugin_name=multiclipboard    (云剪贴板)
  ... /plugin_name=kwpslocalserver
  ```
- 还含 `_SYNC_ELEVATION_SENDER_`、`UseStrictValidationForElevation` —— 编辑器提权 IPC 桥。
- PDB 泄露路径：`H:\pub_1qqq7\rc_bugfix_master_\Build\Release_x64\WPSOffice\office6\wpscloudsvr.pdb`

> 一个服务同时承载：云同步、推送、商城、消息中心、文件历史收集。砍掉它 = 一锅端。

### 2.2 `kwpswnsserver.exe` — Windows 原生推送通道（REA/Ghidra 反编译）

REA Evidence `ev_c494423843c1773e5b0239c631b44770930487345569b81b52fc730baf7ff4f0`
（SHA-256 `6d330292…7535a1f6`，1573 个函数，Ghidra 12.1.4）：

- 字符串 `0x43cb70`：

  ```
  Run addons/kpluginwrapper/kpluginwrapper.dll run_plugin
    -plugin_name=kmessagepushcenter -dll_name=kmessagepushcenter from_wns -data=
  ```

- RTTI 显示 `KWnsRegister::RequestChannel` 使用 WinRT
  `Microsoft::Windows::PushNotifications::PushNotificationChannel`（**Windows 系统级 WNS 推送**）。
- 反编译 `FUN_00404310`（引用上述命令行的函数，0x4047fd 处交叉引用）：
  1. 拼 `ksoqing://type=messagepush&cmd=`；
  2. 循环解混淆 12 字节 → `_wnsSaltKey_`（内置盐，校验推送 token）；
  3. 追加 `&token=<hash>`；
  4. 填 `SHELLEXECUTEINFOW` → `ShellExecuteEx` 派发进 WPS 内部协议。
- 配置键：`Software\kingsoft\Office\6.0\plugins\messagepushcenter\wns`。

> **注意**：计划任务要运行的 `kmessagepushcenter` 插件 DLL 本地**不存在**——它由
> `kplugindistributer` 云端下发。即 WPS 具备"远程投递 DLL 并以参数驱动执行"的通道，
> 这也是离线版必须加防火墙的原因（删文件挡不住云下发，断网才挡得住）。

### 2.3 系统挂载点

| 挂载点 | 内容 | 作用 |
|---|---|---|
| 服务 `wpscloudsvr` | LocalSystem | 云文档/推送/商城插件宿主 |
| 计划任务 `WpsUpdateLogonTask_1531` | `ksolaunch.exe /wpsupdate` | 登录时查更新 |
| 计划任务 `WpsUpdateTask_1531` | 同上 | 定时查更新 |
| 计划任务 `WpsWakeWnsLogonTask` | `kpluginwrapper … kmessagepushcenter wake_wns` | **登录即唤醒 WNS 长连接推送** |

2.4 "扫描磁盘"的真身（实测确认）

1. **内置 VOIDTOOLS Everything 全盘索引器**：`addons\everythingsearch\everythingbinary\Everything.exe`
   （含 `md5.ini` 指纹校验）。其 `Everything-KingSoft-CloudSearch.ini` **无任何排除项**，
   仅隐藏托盘图标——即"云搜索"场景下对全部 NTFS 卷建 MFT 索引；
   桌面搜索配置也只排除 `C:\Windows`、`C:\ProgramData`、回收站。
   **实测（2026-10-19）**：该 EXE 会将自身注册为 Windows 服务 `Everything`
   （自动启动、LocalSystem，父进程 services.exe），开机常驻后台全盘索引——
   已并入脚本第 2 步与服务 `wpscloudsvr` 一并删除。
2. `wpscloudsvr` 的云同步插件（qing）+ `krecentfile`（最近文件收集）+ `qingshellext`
   （资源管理器命名空间扩展）持续关注用户文件活动。
3. 相关营销入口：`ksearchpanel`（搜索面板）、`kfileradarguide`（"文件雷达"引导）。

### 2.5 端点中枢 `ksolite.dll`

从 `office6\ksolite.dll`（11.6 MB）提取出 **498 个金山系域名**，包括：

- 广告 CDN：`abroadad.cache.wpscdn.com`、`*.wpscdn.cn`（素材/皮肤/推广位）
- 推送：`api-push.wps.cn`、`cloudnotify.wps.cn`
- AI：`ai.wps.cn`、`aiwrite.wps.cn`、`aippt.wps.cn`、`copilot-api.wps.cn`…
- 稻壳模板商城：`*.docer.wps.cn`、`chn.docer.com`
- 云文档/账号/会员：`qing.wps.cn`、`account.wps.cn`、`*-vip.wps.cn`、`365.kdocs.cn`

> 配套脚本采用"按 EXE 防火墙阻断"而非逐域名 hosts——域名表随版本变化，按程序阻断一劳永逸。

---

## 3. 组件分类清单

### 保留（编辑核心，勿动）
`wps.exe` `et.exe` `wpp.exe` `wpspdf.exe` 及核心 DLL：
`wpscore/etcore/wppcore/etmain/wpsmain/wppmain/kso/kshell/ksolite/ksouil/wpsuil/ufd*/jsetapi/jswpsapi…`、
`qt*`（Qt5 UI）、`skia.dll`、`angle`、`mui`（多语言）、`kvprinter`（导出 PDF 的虚拟打印机）、
`data/res/skins/iconthemes`、`kwpsconvert.exe`（本地格式转换）。

> **不要**因为 `ksolite.dll` 里有 498 个域名就删它——它是核心壳，网络交给防火墙管。

### 剪裁（脚本已覆盖）
| 类别 | 代表组件 |
|---|---|
| 云文档/同步 | `qing*` `yunbox` `ksyncengine` `kclouddocs` `kcloud*` `kweb*cloudsync*` `kwebadaptersyncfolder` |
| 推送/消息 | `messagepush` `kaipushsdk` `kmessagecenter*` `ktips*` `cloudpushsdk` |
| 营销/运营 | `kstartpage` `officespace` `kwebdashboard` `kappcenter` `kdocer*` `kprome*`（prometheus 门户全家） `kwebmemberrenewalpopup`（会员续费弹窗） `kwhatsnew` `khoneycomb` |
| AI | `kwpsai*` `kwebai*` `kpdfai*` `kcopilot*` `kwpslingxi`（灵犀） `kai*` |
| 全盘搜索 | `everythingsearch` `ksearchpanel` `kfileradarguide` |
| 图片套件 | `photo` `photoeditlite` `photopreviewerlite` `photolaunch.exe` |
| 跨设备互传 | `ksoftbus*` `kdevicecenter` `systemshareext` `ktransferhelper` |
| 更新/云控 | `wtoolex\`（wpsupdate 等 3 EXE） `kplugindistributer` `knimbusconfig` `kentcloudconfig` `kwpsupdateui` |
| 遥测 | `kcrashdumper*.exe` `transerr.exe` `kfeedback` |

### 可选
- `addons\cef` + `kcef*`（168 MB Chromium Embedded）：起始页/门户/Docer 网页渲染内核。
  纯文档编辑不需要；脚本 `-RemoveCEF` 开关控制。裁掉后个别"设置里的网页面板"会空白，属预期。
- `ksolaunch.exe`：保留（崩溃恢复/启动器壳），防火墙已断其外联；开始菜单快捷方式已改指 `wps.exe`。
- `khyperion`、`kapmsdk` 等语义不明的 addons：**默认保留**（宁可少删，防火墙兜底）。

---

## 4. 离线后的功能变化（预期内）

不可用：稻壳模板/商城、会员/登录、云文档同步、AI（灵犀/Copilot/AI 排版）、
跨设备传输、文件雷达/全盘搜索、推送通知、热点/资讯、自动更新、皮肤商店在线部分。

不受影响：docx/xlsx/pptx/pdf 打开·编辑·保存·另存·打印、本地模板、本地最近文件、
PDF 导出与批注、公式/图表/宏（个人版本无 VBA 的限制与联网无关）、多开、兼容模式。

---

## 5. 执行与验证

```powershell
# 演练
powershell -ExecutionPolicy Bypass -File make-wps-offline.ps1 -WhatIf
# 执行（自动提权；-RemoveCEF 可再裁 168MB）
powershell -ExecutionPolicy Bypass -File make-wps-offline.ps1 -RemoveCEF
```

验证：
1. 双击各类文档正常打开/编辑/保存/打印；
2. 任务管理器无常驻 `wpscloudsvr`/`Everything`/`kwpswnsserver`；
3. `netstat -bno` 无 WPS 进程外连；
4. 重启后无云组件复活（计划任务已删、服务已删、防火墙仍在）。

回滚：`_quarantine` 目录整体拖回 + `Remove-NetFirewallRule -DisplayName "WPS-Offline-Block*"`
（服务重建命令见脚本尾注）。

---

## 7. 第二轮增补（登录与漏网组件）

### 7.1 登录能否摘除

**功能上已经摘除**：登录状态通过 IPC 向 `wpscloudsvr` 查询（`kshell.dll` 证据：
`getLoginInfoIpcRes`、`isQingRunning`、`isQingOffLineMode`、`onCheckLoginStateTimeout`）。
服务删除 + 断网后查询永远失败 → 走离线分支；本地打开/编辑/保存无登录墙。

**SDK/界面层可继续摘**（已并入脚本）：
- `office6\kqingaccountsdk.dll` —— 账号 SDK（内置 QQ/微博/小米/华为/苹果/钉钉等 OAuth 端点）。
  **全部 office6 根目录 PE 均无静态导入**（PE 导入表全量核查），纯动态加载 → 摘除不断启动。
- addons：`kusercenter`（用户中心）、`kqingdlg`（登录对话框）、`khyperion`（账号/会员框架，
  字符串含 qing/docer/login/cloud）、`kdeactivator`、`krecentfile`、`kcloudfiledialog`
  （文件对话框云位置）、`yunkitapi`（云 API，**内嵌硬编码 IP `http://120.131.9.220`**）、
  `kyunhook`、`kspostpay`（支付）、`kassosettingguide`、`kwebknovicetask`（新手引导）。

**摘不掉的残留（无害）**：标题栏登录按钮画在 `kshell.dll`（核心壳，含
`KQingLoginButton`/`isNeedShowLoginBar`/`NoLogin` 状态机）；文件对话框"未登录"横幅
`KNotLoginWidget` 在 `ksolite.dll`。断网后点击登录只会失败/转圈，不影响编辑。
另存在 `DisablePartForceLoginLogic`、`isEnableForceLogin` 等"强制登录"逻辑开关名，
个人版本地编辑未观测到强制登录路径，离线状态下不可达。

### 7.2 其余漏网组件（已并入脚本）

- 协作/在线：`kwpscowork` `kcooperatearea` `kcoworkdockpanel` `konlinefileconfig`
  `konlinegradient` `kwebonlinetaskpane` `kwebdocscontrol` `kwebextensionlist`
  `kwebmarkdown` `multiclipboard`
- 营销管理器：`kappmgr` `kapplist` `kextensionmgr` `kpluginmanager`（注意保留
  `kpluginwrapper`/`kpluginrunner` 运行时加载器，其他本地功能仍依赖）`kskincenter`
  （皮肤商店）`kdatamigration`
- AI 漏网：`kwpscopilot` `kwppcopilot` `kwppcopilotentry` `kpdfcopilot` `kwppaiquoteppt`
  `kwppmathor` `kwpsmathor` `kwebwppaioutline` `ketaidataanalysis` `kkdcconv`
  `kwpsdriverescore` `klayoutopt`（版式优化 EXE）`kwebwpsdoccomposing` `kwpsnote`
- 诊断/帮助：`kdiagnostictools` `secanalyze` `khelp` `kwebhelpqa`
- 根目录：`pintaskbar.exe` `kwinappinstaller.exe`（UWP 扩展安装器）

### 7.3 保留但可选的大块头

| 组件 | 大小 | 去留建议 |
|---|---|---|
| `addons\kufeconvertplugin` + `kpdf2wordv3` | ~66MB | PDF↔Word 本地转换引擎（未检出网络端点）；要转换功能就留 |
| `addons\wppmediaplayer` | 18MB | ffmpeg/SDL，PPT 内嵌视频播放才需要 |
| `addons\kmarkdown` | 12MB | 本地 Markdown 编辑支持，无云痕迹 |
| `addons\repsvr` / `v8` / `kpluginrunner` 等 | — | 语义不明或属运行时桥，默认保留，防火墙兜底 |
| `utility\` | 72MB | 卸载器 + 修复数据，建议保留（否则只能手动删目录） |
| `office6\wpscenter.exe` | 1.1MB | 配置中心界面，改设置要用，保留 |

---

## 8. 白屏事件排查实录（2026-10-19，二分定位终局）

### 8.1 教训：验证链路污染

第一轮冒烟使用"截图上传视觉服务"判定，后经 computer-use 视觉模型现场复核发现
**结论全部为假阴性**（截图链路存在缓存/错位，"渲染正常"判定不可信）。
改用 computer-use 直接观察屏幕 + UIA 元素计数（正常渲染 238-249 个元素，
错误页恒为 47-48 个）作为判定标准后，才获得可信数据。

### 8.2 二分定位结论

对 278 个隔离项做逐级二分（每轮 computer-use 视觉验证），最终锁定：

- **`addons\knetwork` 是编辑器启动硬依赖**——缺失必现
  "我们遇到了一个无法恢复的问题"错误页（文档画布停在"正在打开文档···"），
  且点击"重新载入"无法恢复。
- 决定性对照（同基线 103 项隔离）：
  - 103 项 + knetwork 在位 → ✅ 完整渲染
  - 104 项（加删 knetwork）→ ❌ 错误页
- **终极验证状态：277 项隔离 + 仅保留 knetwork → ✅ 完整渲染**
  （正文/图片/页脚"页面 1/3 字数 592"/功能区全部正常，
  且顶栏不再出现"稻壳儿"门户标签，界面反而更干净）。

注：排查过程中 kmultcatalog/knewdoc/knewdocs 曾表现"单独隔离即崩"，
最终证明 knetwork 在位时它们均可安全裁除（对照实验先例受验证链路污染干扰）。

### 8.3 最终精简策略

addons 采用**白名单保留制**：仅保留 `knetwork`，其余（约 262 个目录）全部移入隔离区；
office6 根目录 14 个 offender 文件 + `wtoolex\` 更新器目录照旧隔离。
已写入 `make-wps-offline.ps1` 第 4 步。

### 8.5 工具栏可用性实测（2026-10-19 终局）

用户报告"工具栏无法点击"。computer-use 完整交互链实测（干净实例、双击方式启动）：

| 操作 | 结果 |
|---|---|
| 点击正文画布 | ✅ 焦点落入正文（字体框实时显示"五号/Calibri"） |
| 键盘输入 `T1` | ✅ 成功（标题栏出现未保存星号 `*`） |
| Ctrl+A 全选 | ✅ 成功（字号/字体框清空，原灰色按钮组 enabled=true） |
| 连点"增大字号"×2 | ✅ 截图可见正文字号显著变大 |
| Alt+F4 / 保存对话框 / 不保存退出 | ✅ 全链路正常 |

**结论：核心格式工具栏（字体/字号/开始选项卡）在离线精简版上完全可用。**

**按钮分两类**：
- **活按钮**：开始/插入/页面/审阅等全部格式与排版命令（先点正文获得焦点即可用；无焦点/无选区时灰色是 Office 通用行为）
- **死按钮**（点击无反应，属预期）：`WPS AI`、`会员专享`、`稻壳AI模板`——
  其后端 addon 已按需求裁除，按钮仅为 KCommand 注册表残留入口。
  可见性由打包资源+云端配置控制（`%1_taskpanelAIEntry_visible` 键模式，本地无注册表开关），
  无低成本隐藏手段；视作"已删功能的空壳"即可。

**注意**：同一 WPS 实例被反复强杀/长时间挂机后会出现交互钝化（点击/快捷键被吞），
重启实例即恢复——排查期间多次观察到该现象，与精简无关（恢复提示条出现即为信号）。

### 8.6 云端插件池与"核心支持库"弹窗（2026-10-19 终局二）

**发现**：`%APPDATA%\Kingsoft\wps\addons\pool\win-x64\` 沉淀了 **38 个云端按需下发插件**
（kpubaigcbox 8.4MB / kwpsaigc 8.5MB / kpromeaccountpanel 5.8MB 等）——即"还会运行新东西"
的实体仓库。已整体移入隔离区并重建空目录。

**setupplugin.plg**（office6\setupplugincfg\，明文 XML 插件注册声明）：
移除 178 条指向已裁 addon 的死声明（备份 .korig）。实测：窗口结构 241 元素不变、
文档正常渲染——安全。

**"核心支持库正在加载中"弹窗**（点稻壳AI模板按钮触发）：
弹窗本体在编译资源内（文本/类名均不可寻址：三种编码全文无、窗口类=Qt5QWindow、
字符串无 lea 交叉引用）。尝试三个补丁点均未命中链路（kprometheus
`promotionTabClicked`/`onPromotionTabClicked`、ksolite `KPluginDependLoader::
loadByAcceptFlowControl`、`KPluginLoader::load`），全部已还原，未留无效补丁。

**无害性实证**（弹窗出现时）：WPS 进程 TCP 连接 = 0、addons 目录数不变 = 1、
3 分钟内新文件 = 0——防火墙下该弹窗只是干转的进度条，点其关闭按钮即消，
不下载、不落盘、不运行任何新代码。**根除它需要逆向门户内嵌声明加载器（工程量
大、风险高），当前以"隔离一切可执行实体 + 断网"实现等效安全。**

### 8.7 登录提示根除（kshell.dll 二进制补丁）



实测确认不登录可正常编辑（键入/撤销/保存全通过），但"访客状态·立即登录"横幅仍在。
逆向定位（解析 kshell.dll 导出表 31362 个符号 + capstone 反汇编）：

| 函数 | RVA | 文件偏移 | 作用 |
|---|---|---|---|
| `KxDrTipWidget::isNeedShowLoginBar` | 0x77fcf0 | 0x77f0f0 | 登录横幅总开关（读云端配置，无本地开关） |
| `KxDrTipWidget::isNeedShowGuidedLoginTip` | 0x77fb70 | 0x77ef70 | 引导登录提示 |
| `KxDrTipWidget::isNeedShowForceLoginTip` | 0x77f4b0 | 0x77e8b0 | 强制登录提示 |
| `KxApplication::IsStartUpInForceLoginMode` | 0x55b400 | 0x55a800 | 启动强制登录模式 |

补丁：函数入口写 `31 C0 C3`（`xor eax,eax; ret`）恒返回 false。
原件备份 `kshell.dll.korig`；已并入 `make-wps-offline.ps1` 第 7 步（含版本校验，
原字节非 0x48/0x40 开头则跳过），`restore-wps.ps1` 第 1.5 步自动还原。

视觉验证（computer-use）：补丁后控件树中"访客状态/立即登录"均消失，
文档正常渲染、可编辑；实现完全不登录的离线核心使用。
工具：`tools/loginpatch.py`（patch/restore/status）、`tools/exports.py`、`tools/disas.py`。

## 9. "WPS云盘"资源管理器挂载（已处理）

- 注册点：`HKCU\...\Explorer\MyComputer\NameSpace\{EEEEFCF7-867B-4FA2-9ABD-884CF531B600}`
  与 `HKCU\...\Explorer\Desktop\NameSpace\{EEEEFCF7-...-884CF531B602}`，
  COM 实现即已隔离的 `qingnse.dll/qingnse64.dll`（删除后为孤儿键）。
- 已删除并重启资源管理器；已并入 make-wps-offline.ps1 第 7 步。

## 10. 配套脚本

| 脚本 | 作用 |
|---|---|
| `make-wps-offline.ps1` | 精简（UTF-8 BOM；杀进程→删服务×2→删任务→隔离组件→防火墙→改快捷方式→删云盘命名空间） |
| `restore-wps.ps1` | 一键还原：隔离区 279 项路径重建回位（已校验 0 错）、重建 wpscloudsvr/Everything 服务、重建 3 个计划任务（定时任务原始触发时刻未留存，统一 10:00）、删防火墙规则、快捷方式改回 ksolaunch、重建云盘命名空间 |
| `tools/bisect.py` 等 | 排查期工具（冒烟截图/批量搬移/二分） |

## 11. 证据与限制说明

- Ghidra 分析经由 REA CLI 完成（MCP 通道 30 秒超时 < Ghidra 35 秒分析时长，故走 CLI）；
  `kwpswnsserver.exe` 全量分析 Evidence：`ev_c494423843c1773e5b0239c631b44770930487345569b81b52fc730baf7ff4f0`。
- `wpscloudsvr.exe`（x64, 1.1 MB）证据来自字符串/导入面扫描（`FindFirstFileW`、`GetDriveTypeW`、
  插件命令行），未做全量反编译——结论不依赖它。
- "addons 目录名 → 功能"的映射基于命名约定与已知 WPS 生态词汇（qing=云文档、docer=稻壳、
  prome=prometheus 门户、lingxi=灵犀 AI），未逐个反编译 230 个插件；脚本因此采用
  **隔离区（可回滚）+ 防火墙双保险**，而非不可逆删除。
- Everything INI 证明索引范围；是否在默认状态下自动启动索引，取决于首次进入"云文档/搜索"
  功能（离线版中该入口已被裁除+断网，不再可达）。

## 12. 最终结论（2026-10-20 实测定型）

### 12.1 "工具栏灰死"的完整因果链（三层叠加，逐层排除）

1. **白名单裁剪期残留**：早期裁剪导致文档打不开（knetwork 硬依赖），修复后编辑器正常。
2. **kshell.dll 二进制补丁（元凶，已废弃）**：为遮登录横幅补丁的 4 个布尔函数与
   命令启用状态机共享判定，补丁后功能区整体进入 disabled（UIA IsEnabled=false 实证），
   还原 kshell.dll 后 42/42 按钮恢复 enabled。**遮横幅的补丁 = 弄死工具栏的直接元凶。**
3. **未登录访客锁（根因）**：横幅文案"当前处于访客状态，请登录后继续使用"是限制版；
   逆向 ksolite.dll 导出表定位 `KCloudSvrProxy::isLogined/isEnableForceLogin`，
   wpscloudsvr 服务是登录态 IPC 载体——删除服务 => IPC 断链 => 保守锁定。

### 12.2 正解：官方开关（非逆向补丁）

WPS 自带 配置和修复工具（`office6\ksomisc.exe`）→ 其他选项 →
**「兼容离线状态下的未登录使用方式」**。注册表落点（差分实锤）：

```
HKCU\Software\Kingsoft\Office.0\Common : compatible_type = 1 (dword)
```

效果（本机实测，全量还原后验证）：
- 横幅从"访客限制警告"降级为普通推荐条（"登录支持开启多端云文档同步…可随时查看编辑"）；
- 功能区命令全部激活：选中文字 → 点字体颜色 → 色板弹出 → 选红 → **全文变红**；
- Ctrl+S 保存成功，document.xml 内 71 处 `FF0000`（全选应用成功）。

### 12.3 组件裁剪约束修正

| 组件 | 旧结论 | 修正结论 |
|---|---|---|
| wpscloudsvr 服务 | 删除 | **保留并运行**（IPC 登录态载体）；离线由防火墙阻断外联兜底 |
| kqingaccountsdk.dll | 隔离 | **保留**（账号事件分发，命令启用链依赖） |
| kshell.dll 补丁 | 4 函数 31C0C3 | **废弃**（破坏功能区；横幅交给 compatible_type 处理） |

### 12.4 定性

"离线可用"的正确姿势 = 官方离线兼容开关（compatible_type=1）+ 保留本地 IPC 服务
+ 防火墙断外联 + 按需裁剪云端插件（knetwork 必留）。纯二进制补丁路线在这个版本
行不通：登录判定散布于 ksolite/kshell/账号SDK/云服务 IPC 四处，动任何一处都会被
保守逻辑转化为功能降级。


### 12.5 终版修正（2026-10-20 11:10 后补充实测）

12.3 表中"wpscloudsvr 服务必须保留"的结论**作废**。组合实测：
`compatible_type=1` + 服务删除 + 两处 exe 移除 + 进程清零 → 功能区依然全功能
（色板弹出/选红/编辑/保存全链路通过，文档全文 FF0000 保存成功）。
官方开关本身就是为无云服务环境设计，独立兜住登录态，不依赖本地服务存活。
12.3 修正表更新为：

| 组件 | 终版结论 |
|---|---|
| wpscloudsvr 服务 | **可彻底删除**（依赖 compatible_type=1） |
| wpscloudsvr.exe（两处） | **可彻底移除**（同上） |
| kqingaccountsdk.dll | 保留倾向（未单独做移除组合实测） |
| kshell.dll 补丁 | 废弃（破坏功能区，横幅交给 compatible_type） |


### 12.6 标签空壳最终结论（2026-10-20 12:40）

「稻壳AI模板」「会员专享」「WPS AI」三个标签为 **kshell 内核动态注入**，不受
addons 裁剪、setupplugin.plg、ongmani.kui 的 visible 属性控制（实测 visible=false
补丁无效，已回滚）。其显隐由 KIC 云端开关体系（加密注册表 kic\switch\*）驱动，
离线断网时保持默认显示。

实测现状（离线纯净版终态）：
- 点击三个标签均为空壳响应：WPS AI 标签=空白功能区，无报错/无弹窗/无网络请求；
- 云端下发链路已被防火墙阻断（48 exe 全阻断），插件池仅剩 WPS 启动时 mkdir 的
  空占位目录（零文件）；
- 自动更新已关（官方开关，计划任务同步清除）。

结论：**接受三个空壳标签**（无功能/无网络/无副作用）。继续深挖需逆向 kshell 的
tab 注入路径并做二进制补丁——该区域曾因补丁引发全功能区 disabled 事故，风险收益比
不成立。


### 12.7 界面纯净三连击（2026-10-20 13:20 完成，全部实测验证）

在 12.6 "接受空壳" 结论之后继续深挖，最终全部清除：

| 标签 | 逆向定位 | 处置 |
|---|---|---|
| 会员专享 | `res\wpsongmani.kui` 的 `<KRbControlCommand id="CT_WorkSpace" idKey="CommonVipTab" text="@Special Apps">` | 删除 XML 元素 |
| WPS AI | 各 ongmani 的 `<KRbTabProxyCommand id="CT_Copilot" idKey="WpsCopilotAI">` | 删除 XML 元素 |
| 稻壳AI模板 | `kprometheus.dll!KPromeDocerTabButtonCtrl::createDocerTabButton`（RVA 0x58AC80，经日志字符串 `createDocerTabButton: personal button created` 交叉引用定位） | 入口写 `31 C0 C3`（恒返回"未创建"，函数本身存在该返回路径，安全） |

**关键教训（这条链条上的死胡同与正解）**：
- `visible="false"` 属性补丁无效——kuip 解析器只认固定属性集，静默忽略未知属性；
- kuip 是活资源（隐藏文件会导致文档打不开），但改后必须清 `%APPDATA%\Kingsoft\office6\cache` 编译缓存；
- `useFakeTab="false"`、注册表明文开关（StartPageNavigationHideNewFromTemplate）、隔离 kstartpage 均无效——
  该按钮由 kprometheus 二进制内代码创建，与插件/kuip/注册表无关；
- 文件锁定时用 `r+b` 定点写而非整文件重写。

**验证链**：UIA 树三标签全部消失 + "新建"保留 + 文档正常打开 +
功能区加粗按钮点击实链路（18 处 `<w:b/>` 写入保存的 docx）+ Ctrl+S 保存成功。
已固化进 make-wps-offline.ps1 第 10 步。


### 12.8 右上角按钮清除（2026-10-20 14:00）

| 按钮 | 逆向定位 | 处置 | 结果 |
|---|---|---|---|
| 应用市场 | `KPromeTabBarImpl::initAppMarketBtn` + `ensureAppMarketButton` + `checkInitAppMarketBtn` | 入口 31 C0 C3 | ✅ 消失 |
| WPS随行 | `isCrossTerminalEntryVisible`（可见性判定导出）+ `initCrossTerminalBtn` | 恒 false | ✅ 消失 |
| 立即登录 | `KPromeHeaderAvatar`（initUnloginedButton / isUnloginRectangleButtonStyleVisible / ensureAvatarPlaceHolder 全部 stub） | ❌ 未消失 | 保留 |

立即登录按钮 = KPromeHeaderAvatar 头像组件，属 kshell 登录体系核心 UI；
实验中 stub initFpccomb/面板类函数导致过一次启动崩溃（已回退），avatar 相关
stub 全部无效——它的创建路径在 TabBar 构造主链上，再动有全 UI 崩溃风险。
结论：保留登录入口（点击弹登录窗，无广告内容），离线状态下无实际作用。

### 12.9 ksomisc 自动化说明

功能定制页的 13 项隐藏开关写入 KIC 加密配置（kic\switch\*，BASE64+加密，无法
直接注册表注入）。可行替代：`compatible_type=1`（明文 DWORD）已覆盖核心场景。
其余开关如需重放，用 UI 自动化驱动 ksomisc.exe（配置工具本身无命令行参数）。


### 12.10 ksomisc 功能定制开关脚本化（2026-10-20 15:45）

**逆向结论**:
- ksomisc 功能定制页 13 项复选框的设置 ID 为 `type.*` 格式
- 读取方 = `krt.dll!getFuncSwitchState`（读 mdbx/KIC）
- 写入方 = `KIC::SettingsImpl::setSwitch`（加密写 kic-switch-user）
- 加密为确定性编码（同输入→同输出），但密钥不在本地

**脚本化方案： KIC 加密 blob 移植**
1. 在 ksomisc 中手动勾选所需选项（一次）
2. 运行 `python tools/analysis/export_kic_blobs.py` 导出 .reg
3. 脚本已保存在 `tools/patches/kic_switches_working.reg`
4. make-wps-offline.ps1 第 7b 步自动 reg import 注入

### 12.11 通用性重构（2026-10-20 16:00）

**审计结果**: 脚本 9 项可移植性问题已修复

| 问题 | 修复 |
|---|---|
| 版本号 RVA 硬编码 | 加入 prologue 字节校验，不匹配自动跳过 |
| 用户名硬编码 | 全部改 $env: 和自动检测 |
| KIC 加密 blob 机器绑定 | 替换为 UIA 自动化驱动 ksomisc（通用无依赖） |

**KIC 加密算法**: AES-ECB（krt.dll 含 AES sbox + SHA256 常量）
- 密钥在 krt.dll 二进制内，无法高效提取
- Frida 调 gpcrypt::Encode 因 QString 引用 ABI 问题失败
- 通用替代: 已实现 ksomisc_auto.ps1（UIA 自动化），无需破解加密
