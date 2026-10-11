# 朵朵与猫猫：把回家的路点亮

**最新：M31 离线验收版，序章、五章冒险与回家尾声。**

- [Mac Universal（Apple Silicon / Intel）](https://github.com/LanCloudLance/duoduo-cats-courtyard/releases/download/m31-offline-v0.3.1/DuoduoCats-M31-macOS-Universal.zip)
- [Windows 64 位](https://github.com/LanCloudLance/duoduo-cats-courtyard/releases/download/m31-offline-v0.3.1/DuoduoCats-M31-Windows-x64.zip)
- [发行说明与附件](https://github.com/LanCloudLance/duoduo-cats-courtyard/releases/tag/m31-offline-v0.3.1) · [文件校验与验证范围](release/m31/README.md)

完整解压后即可运行，音乐、字体、素材均已内置。Mac 双击 .app；Windows 双击 DuoduoCats.exe，保持 .pck 同目录。Mac 原生独立 QA 版已做本机开局、移动、互动和暂停恢复检查；Windows 实机运行、真实双手柄和真人趣味仍待验收。Mac 尚未 Apple 公证，首次启动指引随包附上。

game-source 已同步封版 M31 源码；[三遍自审](release/m31/final-review.md)、[原生包独立审核](release/m31/native-package-audit.md)及来源清单可查。离线版存档与网页版分开。

## Web 构建与历史记录

以下保留此前 Web 交付说明。dist 对应此前私有 Site v19；此次公开 GitHub 原生发行不会替换该网站的部署版本。

同一 Godot 4.7.2 / GDScript 工程的 Web 单线程导出。权威游戏源码保留在工作区 outputs/duoduo-game；这里 game-source 是本次构建对应快照，修改后需同步再构建。dist 为网站部署内容。

M28 当前入口提供完整新旅程、按人数继续、设置和已解锁章节回访；旧独立开发场只在 development-menu 启用。主线为序章、五章与归家。谜题采用真实受力、光路、隔离与可恢复探索；单人战斗一位部署、手动接棒，双人两位真人、第三位候补。详见 [全篇重审和返工评审](validation/m28/final-review.md)。技术候选不代表儿童趣味、Windows实体手柄或真实首通时长已验收。浏览器用独立的 /userfs/DuoduoCatsCourtyard 安全点，IndexedDB 保存在本站当前浏览器中；不与桌面自动同步。网页顶部操作说明会暂停游戏，回画面后 Enter 或菜单键继续。

构建设置环境变量 GODOT_BIN 和 GODOT_WEB_TEMPLATES，运行 python3 build_web.py。后者目录包含官方 web_nothreads_release.zip 和 web_nothreads_debug.zip。正式构建不设置 WEB_DEBUG、WEB_STORAGE_PROBE。

build_web.py 在隔离目录导入 game-source，排除本机 override.cfg 和 tests，导出 release。官方 wasm 用 gzip 压缩为 engine.bin，在浏览器流式解压，恢复原始字节后编译；无第三方游戏运行服务。每个资产均低于 25 MiB。

中文字体为 SIL OFL 许可的 Google Fonts Noto Sans SC，固定 Regular 字重、裁剪至游戏文字。许可证位于 dist/OFL.txt 与 game-source/assets/fonts/OFL.txt。

M12 历史记录：当时本地 Chromium 13 项键盘／角色切换／暂停／合成手柄／返回测试通过。独立存档夹具：5 项实际 E 休息写入、关闭浏览器、重新打开、恢复与单／双人隔离通过。存档夹具仅注入本地 debug 构建，正式 release 不含该分支；只读观测仅在 debug 开启。此验证不代表 Windows 实体手柄、Safari 或所有浏览器已经验收。

M13 将调桥庭院升级为首个视觉样板：绘本庭院底图、三位角色站立／行走图集、独立机关动画、纸色 HUD、互动音效与静音按钮。这是 M13 当时的范围；后续战斗与 M15 灯廊、休息区均已接入独立绘本表现。游戏规则和碰撞位置不变。网站仍仅站点所有者可访问。

assets/visual-m13 的图片由本项目使用内置图像工具生成。原始色键图保留，游戏着色器在运行时移除背景；没有将棋盘格当作透明素材。角色服装目前是图集的一部分，后续完整换装仍需拆分装备层和补充方向动画。

M15 已补齐灯廊、休息区和完成卡片，四段试玩可以连续完成。详见 validation/M15-demo-complete.md；战斗动作流畅度保留后续专项打磨。

M16 调整战斗：主动连击、输入缓冲、闪避取消、团团打断与圆圆接力、新近战／施法／半血震地敌人、自动阶段衔接。实现和证据见 validation/M16-combat.md；新增受控测试与真实输入通关仍分开记录，Windows 实体手柄与主观手感待试玩。

M17 开始逐关制作，新增正式序章“今天明明准备什么都不干”。家中日常、双人分工、发现门口异常、一起出发与独立通关记录形成完整开场；圆圆仍是 NPC，到正式第三章才可操作。序章可选单人或双人，庭院样板独立保留。36 个回归套件最终 719 项检查通过（新增入口的导航夹具调整后定向复测），其中序章真实键盘通关 51 项、合成手柄 8 项；本机没有实体手柄，真人节奏与最终角色演出尚待验收。详见 validation/M17-prologue.md 与 m17-validation-summary.json。

M18 根据用户对 M17 的否定重做序章：移除家务检查清单和目标光圈，添加真实动作、滚动物件、循序的白猫离场，以及需要观察与实际拖动的门口地毯谜题；人手撑门与木门挡两种办法并存。新序章通关记录使用独立 v2 前缀，保留旧记录。详见 validation/M18-prologue-interaction.md。

M19 自查修正三处灯廊提示与真实支撑状态不一致的问题。44 组、780 项完整回归通过；实机参考、体验差距与本机性能样本见 validation/M19-self-audit.md。程序检查未代替主观体验验收。

M20 补充敌人的蓄势／出手／收招动作，灯廊增加 0.35 秒蓄光、10 秒余光通路，压缩重复照路与切换操作，调整邻近互动说明。46 组、817 项回归与另外 16 项像素／支撑图形检查通过；性能对比、网页检查边界和试玩重点见 validation/M20-enemy-light.md。Windows 实体手柄与主观手感待试玩。

M21 完成一轮长循环：扩大真实战斗空间，增加有限卷叶与预警地带、路线预判施法，灯廊之后接入共享镜面风铃谜题，加入六段原创场景配乐。独立评审曾否决盲绕无压力的候选，修正后复审通过；网页又发现音乐缓冲与字体问题，发布前已修正。最终55组954项回归、20项图形检查通过。专业评论与小学生模拟评审、闭环问题、名作参考和验证限制见 [M21-review.md](validation/M21-review.md)。本阶段没有真实儿童、Windows实体手柄或主观听感验收；不以程序通关宣称游戏已好玩。

validation 中的 compose-m21.py 与 m21-regression.py 是原工作区脚本快照，BASE 采用原目录结构；新 checkout 复跑需调整 BASE、Godot/FFmpeg 路径。Godot 测试资源位于 validation/godot-tests，临时复制到 game-source/tests 并完成编辑器导入后，可按 res://tests/<name>.gd 运行；正式Web构建排除tests。原WAV母带留在工作区work/audio/m21，网站只带Ogg循环文件。

M22 根据用户反馈替换风铃机关素材，并按已选木质童话方向重写六段原创合成配乐。图形遮挡自查、构建与验证边界见 [M22-art-music.md](validation/M22-art-music.md)。音乐听感仍需用户试听判断。

M23 重写战斗与强敌配乐，用户后续反馈“好些了”，当前继续采用该方向。M24 接入第一章“点亮第一盏灯”：序章可继续、独立单人/双人入口、两人清理受力枝架、两段战斗、修灯推理、圆圆线索与共同休息。当时第二章尚未实现，仍为试玩版。最终7套件176项针对性检查通过；完整回归初轮的一个菜单夹具失败已修复定向复测，证据与体验限制见 [M24-first-chapter.md](validation/M24-first-chapter.md)。

M25 将第二至第五章和可玩的回家尾声接完，五章可连续推进，也可独立选章。M25 当时仍为短篇试玩实现，机关部分使用示意素材，未达到完整游戏时长与最终演出。67套件、1574项检查最终通过，四章单人/双人正常输入完整通关；完整证据、失败修复与体验边界见 [M25-remaining-chapters.md](validation/M25-remaining-chapters.md)。

M26 修复角色立绘滑行的主要表现，接入位移驱动的正/背面步态、停步与工具动作，补齐第二至第五章专属绘本背景和联动机关/NPC素材。69套件1751项回归及空项目独立PCK的32项检查通过；原生连续动作录像与19张冻结场景图分开保存。慢速切帧、家居方向与完整换装仍需打磨。证据和范围见 [M26-animation-chapter-art.md](validation/M26-animation-chapter-art.md)，素材原图与生成来源保留在 game-source/assets/visual-m26 和 docs/art。
