import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/play_source.dart';
import '../models/video_detail.dart';
import '../models/video_item.dart';
import '../services/sea_cms_api.dart';
import '../widgets/state_views.dart';
import '../widgets/video_player_view.dart';

/// 播放页（自上而下）：
///   1. 顶部：播放器（无片源时显示海报占位）
///   2. 影片介绍：海报 + 片名 + 年份/地区/类型 + 导演/演员 + 简介（可展开）
///   3. 片源：横向切换标签（数据来自接口 playdata 解析）
///   4. 选集：网格按钮，点击换集；当前集高亮
///   5. 剩余空间留白
class VideoDetailPage extends StatefulWidget {
  /// 视频 id
  final int videoId;

  /// 进入页面前已知的视频信息（用于顶栏标题与海报占位，可选）
  final VideoItem? preview;

  const VideoDetailPage({super.key, required this.videoId, this.preview});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();

  /// 统一的播放页跳转入口（列表页 / 首页点击影片后调用）
  static void open(BuildContext context, VideoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VideoDetailPage(videoId: int.tryParse(item.id) ?? 0, preview: item),
      ),
    );
  }
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  VideoDetail? _detail;
  bool _loading = true;
  String? _error;

  /// 当前片源下标
  int _sourceIndex = 0;

  /// 当前选集下标（记录在「切换片源前的当前集」，便于换源后尽量停留在同一集）
  int _episodeIndex = 0;

  /// 简介是否展开
  bool _introExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  /// 加载详情（含播放数据）
  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await SeaCmsApi.instance.fetchVideoDetail(widget.videoId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        // 防御：片源/选集下标越界时归零
        if (detail.sources.isNotEmpty &&
            _sourceIndex >= detail.sources.length) {
          _sourceIndex = 0;
        }
        final eps = detail.sources.isNotEmpty
            ? detail.sources[_sourceIndex].episodes
            : const <Episode>[];
        if (eps.isNotEmpty && _episodeIndex >= eps.length) {
          _episodeIndex = 0;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// 当前片源（无片源时为 null）
  PlaySource? get _currentSource {
    final d = _detail;
    if (d == null || d.sources.isEmpty) return null;
    return d.sources[_sourceIndex];
  }

  /// 当前选集
  Episode? get _currentEpisode {
    final s = _currentSource;
    if (s == null || s.episodes.isEmpty) return null;
    final idx = _episodeIndex < s.episodes.length ? _episodeIndex : 0;
    return s.episodes[idx];
  }

  /// 切换片源：保持集数下标尽量不变（同一部剧不同源通常集数一致）
  void _onSourceChanged(int index) {
    if (index == _sourceIndex) return;
    setState(() => _sourceIndex = index);
  }

  /// 切换选集：换集播放
  void _onEpisodeChanged(int index) {
    if (index == _episodeIndex) return;
    setState(() => _episodeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _detail?.name ?? widget.preview?.name ?? '详情',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(text: '正在加载影片信息');
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadDetail);
    }
    final detail = _detail;
    if (detail == null) {
      return ErrorView(message: '影片信息为空', onRetry: _loadDetail);
    }

    return Column(
      children: [
        // 1. 顶部播放器
        _buildPlayerArea(detail),

        // 2. 介绍 / 3. 片源 / 4. 选集（整体可滚动）
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildIntroSection(detail)),
              if (detail.sources.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSourceTabs(detail)),
                // 选集标题
                SliverToBoxAdapter(child: _buildEpisodeHeader()),
                // 选集网格：用 SliverGrid 懒加载（长剧 900+ 集也不会卡）
                _buildEpisodeSliverGrid(),
              ],
              // 5. 底部留白
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ],
    );
  }

  /// 顶部播放器区域（16:9）
  ///
  /// 有片源：直接播放当前集；
  /// 无片源：显示海报 +「暂无播放资源」占位。
  Widget _buildPlayerArea(VideoDetail detail) {
    final episode = _currentEpisode;
    final hasPic = detail.pic.isNotEmpty;

    if (episode == null) {
      // 无播放资源：海报占位
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPic)
              CachedNetworkImage(
                imageUrl: detail.pic,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black),
                errorWidget: (_, __, ___) => Container(color: Colors.black),
              )
            else
              Container(color: Colors.black),
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const Text(
                '暂无播放资源',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    // 播放器：换集时 url 变化，组件内部会重新 open
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: VideoPlayerView(
        key: ValueKey('player_${detail.id}'),
        url: episode.url,
        title: '${detail.name} · ${episode.title}',
      ),
    );
  }

  /// 影片介绍：海报 + 基本信息 + 导演/演员 + 简介
  Widget _buildIntroSection(VideoDetail detail) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 海报
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: detail.pic,
                  width: 92,
                  height: 130,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(width: 92, height: 130, color: Colors.black12),
                  errorWidget: (_, __, ___) =>
                      Container(width: 92, height: 130, color: Colors.black12),
                ),
              ),
              const SizedBox(width: 12),

              // 片名 + 元信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // 更新状态角标（全32集 / HD 等）
                        if (detail.note.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              detail.note,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _metaText([
                      detail.year,
                      detail.area,
                      detail.lang,
                      detail.typeName,
                    ].where((e) => e.isNotEmpty).join(' / ')),
                    const SizedBox(height: 4),
                    _metaText('播放：${detail.hit} 次'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          // 导演 / 演员
          if (detail.director.isNotEmpty) _metaText('导演：${detail.director}'),
          if (detail.actor.isNotEmpty) ...[
            const SizedBox(height: 4),
            _metaText('演员：${detail.actor}'),
          ],

          // 简介（可展开收起）
          if (detail.intro.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _introExpanded = !_introExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.intro,
                    maxLines: _introExpanded ? null : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _introExpanded ? '收起' : '展开',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 元信息文字样式
  Widget _metaText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12.5, color: Colors.black45),
    );
  }

  /// 片源切换（横向标签）
  Widget _buildSourceTabs(VideoDetail detail) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '片源',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.sources.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _sourceIndex;
                return ChoiceChip(
                  label: Text(detail.sources[index].name),
                  selected: selected,
                  onSelected: (_) => _onSourceChanged(index),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white : Colors.black54,
                  ),
                  backgroundColor: Colors.black.withOpacity(0.05),
                  side: BorderSide.none,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 选集标题
  Widget _buildEpisodeHeader() {
    final source = _currentSource;
    if (source == null) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Text(
        '选集（${source.episodes.length}集）',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 选集网格（SliverGrid 懒加载，当前集高亮，点击换集）
  Widget _buildEpisodeSliverGrid() {
    final source = _currentSource;
    if (source == null || source.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final episodes = source.episodes;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final selected = index == _episodeIndex;
            return GestureDetector(
              onTap: () => _onEpisodeChanged(index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  episodes[index].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: selected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            );
          },
          childCount: episodes.length,
        ),
      ),
    );
  }
}
