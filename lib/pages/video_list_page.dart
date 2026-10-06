import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/video_page.dart';
import '../models/video_item.dart';
import '../widgets/video_grid_view.dart';
import 'video_detail_page.dart';

/// 通用视频列表页
///
/// 首页各栏目的「更多」入口复用此页面，通过 [loader] 注入不同的数据来源
/// （推荐位 / 最新上架 / 关键词搜索结果等）。
class VideoListPage extends StatelessWidget {
  /// 页面标题
  final String title;

  /// 分页数据加载器
  final Future<VideoPage> Function(int page) loader;

  const VideoListPage({
    super.key,
    required this.title,
    required this.loader,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.darkBar,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: VideoGridView(
        loader: loader,
        emptyText: '$title 暂无内容',
        // 点击影片 → 进入播放页
        onItemTap: (VideoItem item) => VideoDetailPage.open(context, item),
      ),
    );
  }
}
