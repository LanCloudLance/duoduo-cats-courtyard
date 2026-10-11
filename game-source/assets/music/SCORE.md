# M29 木质童话配乐

当前配乐由项目内 `work/m29/compose_score.py` 手写音高、节奏、和声与分句，离线合成木质条板、拨弦和轻打击音色。随机噪声只用于短促槌头/刷鼓触感，不决定旋律。没有下载第三方采样、引用已有歌曲或使用系统音色库；不是真人木琴/吉他录音，不据技术数据宣称已经好听。

9首基础曲为home、explore、puzzle、chapter3、chapter4、chapter5、battle、boss、rest。chapter2使用explore主题。每首基础Ogg只含伴奏，对应`-melody.ogg`为同样本长度的旋律层；battle、boss、chapter5有独立`-pressure.ogg`。MusicDirector组合播放，单独试听基础Ogg不是完整配乐。

每首按A、B、4小节呼吸、发展、回归编排。呼吸段撤去旋律、鼓和压力声部。reflect情绪撤旋律；pressure加入对齐声部。3段`accent-*.ogg`是非循环短乐句，遵守音乐静音/音量/暂停并短暂降低底曲。chime-0/1.wav仍是M22原创收光效果，不在此次改写范围内。

`score-manifest.json`记录源码、素材指纹、乐段时间与结构指标。完整母带、事件谱和历史试听基线保留于`work/m29/music`；`listen.html`提供原版/M29三组30秒匹配响度试听及90秒离线导演示意。离线示意不是游戏录音；引擎接入和主观听玩须分别验证。历史M22/M23文档保留为历史，不再代表当前权威源码音乐。
