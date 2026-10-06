import 'package:flutter/material.dart';

import '../models/video_item.dart';
import '../models/video_page.dart';
import '../services/sea_cms_api.dart';
import 'state_views.dart';
import 'video_card.dart';

/// 通用视频网格列表（3 列海报，支持下拉刷新、上拉加载更多）
///
/// 通过 [loader] 回调注入数据来源，因此既能用于频道列表（按分类聚合），
/// 也能用于关键词搜索、推荐位等场景。
class VideoGridView extends StatefulWidget {
  /// 分页数据加载器：入参为页码，返回一页数据
  final Future<VideoPage> Function(int page) loader;

  /// 空数据文案
  final String emptyText;

  /// 空数据补充说明
  final String? emptyHint;

  /// 网格内边距
  final EdgeInsets padding;

  /// 点击条目
  final ValueChanged<VideoItem>? onItemTap;

  const VideoGridView({
    super.key,
    required this.loader,
    this.emptyText = '暂无内容',
    this.emptyHint,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 24),
    this.onItemTap,
  });

  @override
  State<VideoGridView> createState() => _VideoGridViewState();
}

class _VideoGridViewState extends State<VideoGridView> {
  final ScrollController _scrollController = ScrollController();

  final List<VideoItem> _items = [];
  int _page = 0;
  int _totalPage = 1;
  bool _loading = false;
  bool _firstLoaded = false;
  String? _error;

  bool get _hasMore => _page < _totalPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动到底部附近时自动加载下一页
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load(page: 1, reset: true);
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    await _load(page: _page + 1);
  }

  /// 下拉刷新
  Future<void> _refresh() async {
    _totalPage = 1;
    await _load(page: 1, reset: true);
  }

  /// 统一的数据加载
  Future<void> _load({required int page, bool reset = false}) async {
    setState(() => _loading = true);
    try {
      final result = await widget.loader(page);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.list);
        _page = result.page;
        _totalPage = result.totalPage;
        _loading = false;
        _firstLoaded = true;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _firstLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 首次加载
    if (!_firstLoaded && _loading) return const LoadingView();

    // 首次加载失败
    if (_items.isEmpty && _error != null) {
      return ErrorView(message: _error!, onRetry: _loadFirstPage);
    }

    // 空数据
    if (_items.isEmpty) {
      return EmptyView(text: widget.emptyText, hint: widget.emptyHint);
    }

    return RefreshIndicator(
      color: const Color(0xFFE62117),
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        // 内容不足一屏时也能下拉刷新
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: widget.padding,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
                // 海报 2:3 + 两行片名
                childAspectRatio: 0.52,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => VideoCard(
                  item: _items[index],
                  onTap: () => widget.onItemTap?.call(_items[index]),
                ),
                childCount: _items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  /// 底部状态：加载中 / 没有更多 / 加载失败
  Widget _buildFooter() {
    Widget child;
    if (_loading) {
      child = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE62117)),
      );
    } else if (_error != null) {
      child = Text(
        _error!,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
      );
    } else if (_hasMore) {
      child = const Text(
        '上拉加载更多',
        style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
      );
    } else {
      child = const Text(
        '没有更多了',
        style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
      );
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      child: child,
    );
  }
}
