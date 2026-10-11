# M31 离线验收版

两份发行附件的音乐、字体与全部游戏资源已内置，解压后无需联网或另装引擎。

- [Mac Universal 下载](https://github.com/LanCloudLance/duoduo-cats-courtyard/releases/download/m31-offline-v0.3.1/DuoduoCats-M31-macOS-Universal.zip)：Apple Silicon / Intel，解压后双击“朵朵与猫猫.app”。Mac 使用临时签名，未 Apple 公证；[首次打开说明](https://support.apple.com/zh-cn/102445)。
- [Windows x64 下载](https://github.com/LanCloudLance/duoduo-cats-courtyard/releases/download/m31-offline-v0.3.1/DuoduoCats-M31-Windows-x64.zip)：先“全部解压”，双击 DuoduoCats.exe，DuoduoCats.pck 保持同目录。Windows 实机启动尚未测试。
- [SHA256 校验文件](SHA256SUMS.txt)。两份 ZIP 内都附操作说明和引擎、字体许可证。

源码位于 ../../game-source，完整指纹见 source-manifest.json；发行附件的字节数、资源包指纹和验证范围见 package-manifest.json。

M29 改写分章旋律、压力层与成果音；M30 改造第四章维修顺序与两类开路战斗；M31 增加第五章不同代价的取枝方法、真实错误光路、局部提示、战斗预兆和双人出口确认。三遍自审、37 组集成与独立原生包审核均有报告。陌生玩家理解、真人趣味、长期听感、Windows 实机与实体双手柄仍待验收；暂停菜单记事标签与底栏提示的轻微重叠为已记录 P2。

## 从源码导出原生版本

使用 Godot 4.7.2 和同版本官方导出模板。先复制 game-source 为独立导出目录，再将此目录的 native-project.godot 放入导出目录并命名为 project.godot。该设置仅增加版本、独立离线存档和 Apple GPU 纹理导入支持；editor 特性把编辑器目录隔离到专用 QA namespace。

在 Godot 导出设置中建立 macOS / Windows Desktop 两个 release 预设：macOS architecture=universal，bundle identifier=cn.lancloud.duoduo.m31，版本 0.3.1 / build 31，内置临时签名且不公证；Windows architecture=x86_64，embed_pck=false，modify_resources=false，发布者签名关闭。两平台均导出 all_resources，include_filter=assets/visual-m26/*.json，exclude_filter=tests/*,override.cfg,*.md,assets/story-prologue/home-room.png，脚本导出 compiled bytecode，console wrapper 关闭。

正式包不包含测试驱动、override.cfg、MCP addon 或私有 QA autoload。测试运行应先复制为独立 QA 项目，核验实际 userdir 为 DuoduoCatsCourtyard-qa-*；不要用正式玩家存档做自动测试。

仓库 dist 是此前 Site v19 的 Web 产物，本次下载版本以这个 M31 原生 Release 为准。
