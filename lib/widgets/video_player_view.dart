import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/app_theme.dart';

/// 可复用的原生视频播放器组件（media_kit / libmpv 内核，非 H5）
///
/// 任何页面都可以直接引入使用：
///   VideoPlayerView(url: 'https://.../smart.m3u8', title: '片名')
///
/// 内置交互（满足项目播放器要求）：
///   - 长按画面：以 3 倍速率播放，松开恢复常速（画面中央显示提示）
///   - 屏幕右侧上下滑动：调节播放器音量（画面右侧显示音量面板）
///   - 底部工具栏：播放/暂停、进度条、锁定、全屏
///   - 单击画面：显示/隐藏控制层；锁定后单击显示「解锁」按钮
///   - 控制层 5 秒无操作自动隐藏（暂停时保持显示）
class VideoPlayerView extends StatefulWidget {
  /// 播放地址（m3u8 / mp4 直链）
  final String url;

  /// 标题（全屏时显示在顶栏）
  final String title;

  /// 是否自动播放
  final bool autoPlay;

  const VideoPlayerView({
    super.key,
    required this.url,
    required this.title,
    this.autoPlay = true,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  /// 播放器内核（libmpv）
  late final Player _player;

  /// 视频渲染控制器（Video 组件共用同一个纹理）
  late final VideoController _videoController;

  /// 最近一次播放错误信息（player.stream.error）
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    // 监听播放错误（地址无效 / 网络异常等）
    _player.stream.error.listen((msg) {
      if (msg.isNotEmpty && mounted) {
        setState(() => _error = msg);
      }
    });

    _open(widget.url);
  }

  @override
  void didUpdateWidget(covariant VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 换集 / 换片源：重新打开新地址（复用同一个 Player 实例）
    if (oldWidget.url != widget.url) {
      _open(widget.url);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// 打开播放地址
  void _open(String url) {
    if (url.isEmpty) return;
    setState(() => _error = null);
    _player.open(Media(url), play: widget.autoPlay);
  }

  /// 进入全屏：复用同一个 Player / VideoController，
  /// push 一个横屏全屏页，Video 组件渲染同一块纹理，播放不中断。
  Future<void> _enterFullscreen() async {
    // 顺手隐藏控制层，避免带着工具栏进全屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenPlayerPage(
          player: _player,
          videoController: _videoController,
          title: widget.title,
        ),
      ),
    );
    // 退出全屏后恢复竖屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // 视频画面（media_kit 原生纹理渲染）
        // controls: NoVideoControls 关闭 media_kit 自带控制层，改用本组件的自定义手势/工具栏
        Video(controller: _videoController, controls: NoVideoControls),

        // 交互层：手势 + 控制层（封装为独立组件，全屏页复用）
        _PlayerControls(
          player: _player,
          title: widget.title,
          showBackButton: false,
          onToggleFullscreen: _enterFullscreen,
          errorText: _error,
          onRetry: () => _open(widget.url),
        ),
      ],
    );
  }
}

/// 全屏播放页（横屏，黑色背景）
///
/// 与内嵌播放器共用同一个 [Player] 与 [VideoController]，
/// 只是再包一层 [Video] 渲染，切换过程画面不中断。
class _FullScreenPlayerPage extends StatelessWidget {
  final Player player;
  final VideoController videoController;
  final String title;

  const _FullScreenPlayerPage({
    required this.player,
    required this.videoController,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 同一控制器，画面无缝切换到全屏（同样关闭自带控制层）
          Video(controller: videoController, controls: NoVideoControls),
          _PlayerControls(
            player: player,
            title: title,
            showBackButton: true,
            // 全屏页的「全屏」按钮语义 = 退出全屏
            onToggleFullscreen: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// 播放器交互层：手势识别 + 顶部/底部工具栏 + 各种状态浮层
///
/// 内嵌模式与全屏页共用，通过 [showBackButton] / [onToggleFullscreen] 区分。
class _PlayerControls extends StatefulWidget {
  final Player player;

  /// 顶栏标题（全屏时展示）
  final String title;

  /// 是否显示左上角返回按钮（全屏页显示，内嵌不显示）
  final bool showBackButton;

  /// 全屏按钮回调
  final VoidCallback onToggleFullscreen;

  /// 播放错误信息（来自 player.stream.error）
  final String? errorText;

  /// 错误重试回调
  final VoidCallback? onRetry;

  const _PlayerControls({
    required this.player,
    required this.title,
    required this.showBackButton,
    required this.onToggleFullscreen,
    this.errorText,
    this.onRetry,
  });

  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  /// 控制层是否可见
  bool _visible = true;

  /// 是否锁定（锁定后隐藏全部控件，仅保留解锁按钮）
  bool _locked = false;

  /// 长按加速中
  bool _speedBoosting = false;

  /// 音量手势拖动中
  bool _volumeDragging = false;

  /// 当前音量（media_kit 0~100）
  double _volume = 100;

  /// 控制层自动隐藏计时器
  Timer? _hideTimer;

  /// 音量浮层自动隐藏计时器
  Timer? _volumeOverlayTimer;

  /// 进度条拖动中（拖动时不跟随真实播放进度刷新）
  bool _seeking = false;
  Duration _seekPos = Duration.zero;

  static const Duration _autoHideDelay = Duration(seconds: 5);

  /// 流订阅（dispose 时取消，避免全屏反复进出时累积监听器）
  StreamSubscription<double>? _volumeSub;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    // 记录初始音量
    _volume = widget.player.state.volume;
    _volumeSub = widget.player.stream.volume.listen((v) {
      if (mounted && !_volumeDragging) setState(() => _volume = v);
    });
    // 播放状态变化时刷新自动隐藏计时（暂停时控制层保持显示）
    _playingSub = widget.player.stream.playing.listen((playing) {
      if (!mounted) return;
      if (playing) {
        _scheduleHide();
      } else {
        _hideTimer?.cancel();
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _volumeSub?.cancel();
    _playingSub?.cancel();
    _hideTimer?.cancel();
    _volumeOverlayTimer?.cancel();
    super.dispose();
  }

  /// 重新计时自动隐藏控制层
  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_locked) return; // 锁定状态不存在「可见控制层」
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  /// 显示控制层并重新计时隐藏
  void _showControls() {
    setState(() => _visible = true);
    _scheduleHide();
  }

  /// 单击画面：
  ///   - 未锁定：切换控制层显示/隐藏
  ///   - 已锁定：显示解锁按钮（几秒后自动消失）
  void _onTap() {
    if (_locked) {
      setState(() => _visible = true);
      _scheduleHide();
      return;
    }
    if (_visible) {
      _hideTimer?.cancel();
      setState(() => _visible = false);
    } else {
      _showControls();
    }
  }

  /// 长按开始：3 倍速播放
  void _onLongPressStart() {
    if (_locked) return;
    setState(() => _speedBoosting = true);
    widget.player.setRate(3.0);
  }

  /// 长按结束：恢复常速
  void _onLongPressEnd() {
    if (!_speedBoosting) return;
    setState(() => _speedBoosting = false);
    widget.player.setRate(1.0);
  }

  /// 屏幕右侧竖直滑动：调节音量
  void _onVerticalDragUpdate(DragUpdateDetails details, double width) {
    // 仅屏幕右侧 1/3 区域响应音量手势（左侧留给亮度等扩展）
    if (details.localPosition.dx < width * 2 / 3) return;

    if (!_volumeDragging) {
      _volumeDragging = true;
      _volumeOverlayTimer?.cancel();
      setState(() => _visible = false); // 拖音量时隐藏控制层，避免干扰
    }

    // 上滑（dy 为负）增大音量：全屏高度约对应 0~100 的调节范围
    final delta = -details.delta.dy;
    final newVolume = (_volume + delta * 0.35).clamp(0.0, 100.0);
    setState(() => _volume = newVolume);
    widget.player.setVolume(newVolume);
  }

  /// 音量手势结束：收起音量浮层
  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_volumeDragging) return;
    _volumeDragging = false;
    // 1 秒后隐藏音量浮层
    _volumeOverlayTimer?.cancel();
    _volumeOverlayTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() {});
    });
    // 音量操作完成后重新显示控制层并计时隐藏
    _showControls();
  }

  /// 播放 / 暂停（底部工具栏按钮直接调用 player.playOrPause，见 _PlayPauseButton）

  /// 锁定 / 解锁
  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      _visible = !_locked; // 解锁后恢复控制层；锁定后立即隐藏
    });
    if (!_locked) _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // --- 手势区 ---
          onTap: _onTap,
          onLongPressStart: (_) => _onLongPressStart(),
          onLongPressEnd: (_) => _onLongPressEnd(),
          onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, width),
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            children: [
              // --- 中央状态浮层 ---
              _buildCenterStates(),

              // --- 音量浮层（右侧竖直拖动时） ---
              if (_volumeDragging) _buildVolumeOverlay(),

              // --- 锁定状态：只保留一个居中解锁按钮 ---
              if (_locked && _visible) _buildUnlockButton(),

              // --- 控制层（顶栏 + 底部工具栏） ---
              if (_visible && !_locked) ..._buildControls(context),
            ],
          ),
        );
      },
    );
  }

  /// 中央状态浮层：缓冲中 / 播放错误
  Widget _buildCenterStates() {
    final error = widget.errorText;
    return StreamBuilder<bool>(
      stream: widget.player.stream.buffering,
      initialData: widget.player.state.buffering,
      builder: (context, bufferingSnap) {
        // 播放错误：显示错误提示 + 重试
        if (error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text(
                  '播放失败，请检查网络后重试',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        // 缓冲中：转圈
        if (bufferingSnap.data == true && !_speedBoosting) {
          return const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        // 长按加速提示
        if (_speedBoosting) {
          return const Center(
            child: _SpeedBadge(),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// 音量浮层：右侧居中的音量图标 + 百分比
  Widget _buildVolumeOverlay() {
    final v = _volume;
    IconData icon;
    if (v <= 0) {
      icon = Icons.volume_off;
    } else if (v < 33) {
      icon = Icons.volume_mute;
    } else if (v < 66) {
      icon = Icons.volume_down;
    } else {
      icon = Icons.volume_up;
    }
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 6),
            Text(
              '${v.round()}%',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// 锁定时居中的解锁按钮
  Widget _buildUnlockButton() {
    return Center(
      child: GestureDetector(
        onTap: _toggleLock,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  /// 顶栏 + 底部工具栏
  List<Widget> _buildControls(BuildContext context) {
    return [
      // --- 顶栏：返回（全屏）+ 标题，底部黑色渐变 ---
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              // 返回按钮（仅全屏页显示）
              if (widget.showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),

      // --- 底部工具栏 ---
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: _buildBottomBar(),
      ),
    ];
  }

  /// 底部工具栏：播放/暂停 + 时间 + 进度条 + 锁定 + 全屏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: StreamBuilder<Duration>(
        stream: widget.player.stream.position,
        initialData: widget.player.state.position,
        builder: (context, positionSnap) {
          return StreamBuilder<Duration>(
            stream: widget.player.stream.duration,
            initialData: widget.player.state.duration,
            builder: (context, durationSnap) {
              final position = _seeking ? _seekPos : positionSnap.data!;
              final duration = durationSnap.data ?? Duration.zero;

              return Row(
                children: [
                  // 播放 / 暂停按钮
                  _PlayPauseButton(player: widget.player),

                  // 当前时间
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),

                  // 进度条
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.5,
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _clampProgress(position, duration),
                        max: 1,
                        onChanged: duration == Duration.zero
                            ? null
                            : (v) {
                                // 拖动中：本地记录进度，不立即 seek
                                setState(() {
                                  _seeking = true;
                                  _seekPos =
                                      duration * v;
                                });
                              },
                        onChangeEnd: (v) {
                          widget.player.seek(duration * v);
                          setState(() => _seeking = false);
                          _scheduleHide();
                        },
                      ),
                    ),
                  ),

                  // 总时长
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      _formatDuration(duration),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),

                  // 锁定按钮
                  IconButton(
                    icon: Icon(
                      _locked ? Icons.lock : Icons.lock_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _toggleLock,
                  ),

                  // 全屏按钮
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: widget.onToggleFullscreen,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 时长格式化 mm:ss（超过 1 小时为 h:mm:ss）
  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  /// 进度值安全限制到 0~1
  static double _clampProgress(Duration position, Duration duration) {
    if (duration == Duration.zero) return 0;
    final v = position.inMilliseconds / duration.inMilliseconds;
    return v.clamp(0.0, 1.0);
  }
}

/// 长按加速提示角标：▶▶ 3X
class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.fast_forward, color: AppColors.primary, size: 20),
          SizedBox(width: 4),
          Text(
            '3 倍速播放中',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// 播放/暂停按钮（随播放状态切换图标）
class _PlayPauseButton extends StatelessWidget {
  final Player player;

  const _PlayPauseButton({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      initialData: player.state.playing,
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () => player.playOrPause(),
        );
      },
    );
  }
}
