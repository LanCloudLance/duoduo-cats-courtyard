# 本地复核

使用 Godot 4.7.2。将 game-source 复制到一个临时工作目录，再将 validation/godot-tests 复制为该目录的 tests。测试目录不要加入发布用 game-source 或 dist。

在临时目录的 override.cfg 中将 application/config/custom_user_dir_name 设为独立测试位置，避免本机实际安全点。先运行 Godot --headless --path 临时目录 --editor --import --quit，再运行 Godot --headless --path 临时目录 --script res://tests/full_journey_test.gd 或 solo_journey_test.gd。其他 *_test.gd 同样执行；light_surface_render_test.gd 需要图形界面，去掉 --headless。

render_light_preview.gd 和 render_rest_preview.gd 需要图形界面，命令最后用 -- 传入截图路径前缀。图片是受控状态夹具，只用于视觉核对。它们不替代 full_journey_test.gd 与 solo_journey_test.gd 的连续生产输入通关。
