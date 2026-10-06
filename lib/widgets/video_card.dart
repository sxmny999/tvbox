import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/video_item.dart';

/// 网络海报图
///
/// 统一处理加载中占位与加载失败兜底，避免列表里出现空白或报错图标。
class PosterImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const PosterImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _PosterFallback();

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, url) => Container(color: AppColors.placeholder),
      errorWidget: (context, url, error) => const _PosterFallback(),
    );
  }
}

/// 海报兜底图
class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.placeholder,
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, size: 26, color: Color(0xFFCCCCCC)),
    );
  }
}

/// 竖版海报卡片（「每日推荐」横滑 与 频道列表网格 共用）
class VideoCard extends StatelessWidget {
  final VideoItem item;
  final VoidCallback? onTap;

  /// 固定宽度，为空时撑满父容器（网格场景）
  final double? width;

  /// 海报宽高比，默认 2:3
  final double aspectRatio;

  /// 片名字号
  final double titleSize;

  const VideoCard({
    super.key,
    required this.item,
    this.onTap,
    this.width,
    this.aspectRatio = 2 / 3,
    this.titleSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PosterImage(url: item.pic),
                // 右下角更新状态，如「更新至12集」
                if (item.note.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.black.withValues(alpha: 0.62),
                      child: Text(
                        item.note,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                // 左上角评分
                if (item.score.isNotEmpty && item.score != '0')
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: AppColors.primary.withValues(alpha: 0.9),
                      child: Text(
                        item.score,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: titleSize,
            height: 1.25,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: width == null ? card : SizedBox(width: width, child: card),
    );
  }
}
