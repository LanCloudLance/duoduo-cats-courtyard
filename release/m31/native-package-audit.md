# M31 原生离线交付独立审核

日期：2026-10-11。审核对象为 `work/m31/offline` 的打包流程及正式产物；审核员未启动游戏、未写玩家存档、未联网或安装工具，仅解压到工作目录用于校验。最终 ZIP 与启动说明已封审。已验证范围内无未关闭 P0/P1，可作为 M31 离线验收版交付。

## 已验证

- M31 权威 manifest 的 723 项全部 SHA256 匹配。非缓存文件唯一额外项为既有 QA `override.cfg`，打包 stage 明确排除。正式 stage 的 gameplay/UI/input/assets 共 197 个非 UID 文件与 M31 指纹完全相同。
- 4 个官方模板提取文件的字节数及 SHA256 均符合 templates-provenance.json。Mac release 模板具有 x86_64 与 arm64；Windows 模板与交付 EXE 字节完全一致，PE32+ GUI、machine 0x8664，未嵌入 Authenticode 证书。
- 自行解析正式 PCK v4 中央目录，297 项全部内容 MD5 有效，目录恰好终止于文件尾。Mac 与 Windows PCK 均为 28,240,972 字节，SHA256 为 `8caddd37d5fe165aed22d8108f3f6074d6a0f555ce2472c60dfc96fa87d914be`。
- 正式 PCK 无 tests、addons、offline_probe、override.cfg。独立解码 ECFG project.binary：use_custom_user_dir=true，base namespace=`DuoduoCatsCourtyard-Offline`，main_scene=`res://main.tscn`，无 autoload；features 仅为 4.7，无 editor。editor 条件的 QA namespace 不作用于 release template。
- 27 个音频/字体 import 文件的真实 remap target 全部在 PCK 中。所有音乐与中文字体现已随资源包交付，无外网依赖发现。
- 正式 Mac .app 的 codesign --verify --deep --strict 成功；签名为 ad-hoc、TeamIdentifier 未设置，无 Apple 公证证明。Info.plist 版本 0.3.1 / build 31，执行文件与资源正确对应。两架构 Mach-O 最低系统 load command 分别为 Intel 10.13、Apple Silicon 11.0，与 plist 相符，未把此检查当作旧系统实机测试。
- 审阅独立 QA twin 的原始 smoke log：实际 OS userdir 为 DuoduoCatsCourtyard-qa-m31-offline，151 checks / failed 0。审核员未亲自执行这次运行，不将其扩展为 Windows 运行验证。

## 流程问题及修复核验

1. 首次 editor import 即使未启动主场景，仍尝试建立正式 Offline userdir；sandbox 拒绝，红日志保留。已改为 editor 特性专用 QA namespace，正式 PCK 读回验证 base namespace 正确。
2. 首次 Mac Universal 导出缺少模板验证所需配置及 ETC2/ASTC 导入开关；红日志保留。后续正式 Mac 与 Windows 导出已成功，正式二进制、资源与签名已核验。
3. 原 verify_authority 只检查已知文件，不识别新增文件；现已补完整文件集合断言，唯一排除项为已知缓存/QA override。
4. 挂包检查回执的 inventory 是 inspection project 与 PCK 的 overlay，含 inspection 自身 probe.gd、project.godot；纯 PCK 的 297 项独立解析结果不包含这两个文件。最终回执应区分两种 inventory。

## 最终交付层复核

- Mac ZIP 为 87,678,310 字节，SHA256 `01078ca4a1b5a6cd33af562465e14cda32a62c8f8b1c3c1406b0c444f7bbe8c3`；Windows ZIP 为 65,285,791 字节，SHA256 `8447c5695dfcbb1b6175fe78149c82cc138fe9dbd39caf3d7da51fb77cac67ff`。两包逐项 CRC 通过，12 / 7 个文件与 build 目录文件集合及 SHA256 完全匹配；路径均安全相对路径，无 QA/测试文件。
- 初版 ditto ZIP 未置 UTF-8 文件名标志，Mac 原生解压可用但其他解压器可能误读中文。主流程已统一改写为显式 UTF-8 ZIP；新的最终 ZIP 所有非 ASCII 名称均带 UTF-8 标志。仅封审新版哈希。
- 对新版 Mac ZIP 用原生 ditto 重新解压，中文 app、执行文件与 PCK 路径正确，可执行权限保留 0755，codesign --verify --deep --strict 再次通过。解压后所有文件与正式 build SHA256 相同。
- 两份“开始游戏.txt”与“版本与校验.txt”已检查：正常新旅程入口、对应继续按钮、真实键盘工具映射、Windows EXE/PCK 必须同目录、两系统实际存档路径、独立离线存档、版本及测试边界清楚。Mac 说明含 Apple 官方安全打开帮助链接。
- 两包均附 Godot MIT、完整第三方许可文本与 Font-OFL.txt；字体 OFL 与权威源逐字节相同。
- 查看 native-paused.png / native-restored.png，中文、人物、序章和暂停/恢复画面正常。审阅主流程 CUA 普通输入记录说明、原始运行日志与 native-qa-saves.json：新单人旅程、D 移动、Esc 暂停、Return 恢复、E 团团互动与永久 extras.tuantuan 保存有证据。运行与存档位于独立 QA namespace。后续 CUA 连接中断，未把菜单出现“继续单人”扩展为重开后的完整章节继续验收。

## 保留边界及后续项

- P2：native-paused.png 底部“旅途记事”小标签仍叠在菜单键盘说明上。未阻塞启动、保存或操作；记录为后续 UI 清理，本次未改权威 M31。
- Windows 实机启动和实体双手柄、Intel Mac 与较旧系统运行未验证。Mac ad-hoc 签名不是 Apple Developer ID 公证。
- 真人趣味、第一次发现解法、长期音乐感受未形成新的验收结论。

封审后再比对权威 manifest 723 项完整文件集合及 SHA256，无改动。原始独立机器回执为 independent-audit-receipt.json，最终 ZIP 哈希与解压证据为 evidence/independent-final-zips.json。
