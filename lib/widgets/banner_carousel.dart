import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/video_item.dart';
import 'video_card.dart';

/// 首页轮播图（自动播放 + 指示点）
///
/// 数据来自接口 home 的 hot_videos（按点击量排序）
class BannerCarousel extends StatefulWidget {
  final List<VideoItem> items;
  final ValueChanged<VideoItem>? onTap;

  /// 自动轮播间隔
  final Duration interval;

  const BannerCarousel({
    super.key,
    required this.items,
    this.onTap,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 数据刷新后重新开始轮播
    if (oldWidget.items != widget.items) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 启动自动轮播
  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => _buildPage(widget.items[index]),
          ),
          // 指示点
          Positioned(
            right: 24,
            bottom: 10,
            child: Row(
              children: List.generate(widget.items.length, (i) {
                final active = i == _index;
                return Container(
                  width: active ? 12 : 6,
                  height: 4,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 单张轮播卡片：海报 + 底部渐变 + 片名
  Widget _buildPage(VideoItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: GestureDetector(
        onTap: () => widget.onTap?.call(item),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PosterImage(url: item.coverImage),
              // 底部渐变，保证片名可读
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 60,
                bottom: 8,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (item.note.isNotEmpty)
                      Text(
                        item.note,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFDDDDDD)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
