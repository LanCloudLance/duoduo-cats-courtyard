# 朵朵与猫猫：庭院网页试玩

同一 Godot 4.7.2 / GDScript 工程的 Web 单线程导出。权威游戏源码保留在工作区 outputs/duoduo-game；这里 game-source 是本次构建对应快照，修改后需同步再构建。dist 为网站部署内容。

网页入口提供单人、同屏双人、继续／选关、全屏和操作说明。浏览器用独立的 /userfs/DuoduoCatsCourtyard 安全点，IndexedDB 保存在本站当前浏览器中；不与桌面自动同步。网页顶部操作说明会暂停游戏，回画面后 Enter 或菜单键继续。

构建设置环境变量 GODOT_BIN 和 GODOT_WEB_TEMPLATES，运行 python3 build_web.py。后者目录包含官方 web_nothreads_release.zip 和 web_nothreads_debug.zip。正式构建不设置 WEB_DEBUG、WEB_STORAGE_PROBE。

build_web.py 在隔离目录导入 game-source，排除本机 override.cfg 和 tests，导出 release。官方 wasm 用 gzip 压缩为 engine.bin，在浏览器流式解压，恢复原始字节后编译；无第三方游戏运行服务。每个资产均低于 25 MiB。

中文字体为 SIL OFL 许可的 Google Fonts Noto Sans SC，固定 Regular 字重、裁剪至游戏文字。许可证位于 dist/OFL.txt 与 game-source/assets/fonts/OFL.txt。

本地 Chromium：13 项键盘／角色切换／暂停／合成手柄／返回测试通过。独立存档夹具：5 项实际 E 休息写入、关闭浏览器、重新打开、恢复与单／双人隔离通过。存档夹具仅注入本地 debug 构建，正式 release 不含该分支；只读观测仅在 debug 开启。此验证不代表 Windows 实体手柄、Safari 或所有浏览器已经验收。

M13 将调桥庭院升级为首个视觉样板：绘本庭院底图、三位角色站立／行走图集、独立机关动画、纸色 HUD、互动音效与静音按钮。只有庭院启用新角色渲染，其他关卡暂沿用原来的玩法美术。游戏规则和碰撞位置不变。网站仍仅站点所有者可访问。

assets/visual-m13 的图片由本项目使用内置图像工具生成。原始色键图保留，游戏着色器在运行时移除背景；没有将棋盘格当作透明素材。角色服装目前是图集的一部分，后续完整换装仍需拆分装备层和补充方向动画。
