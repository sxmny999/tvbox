import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/channel.dart';
import '../models/home_data.dart';
import '../models/video_item.dart';
import '../models/video_page.dart';
import '../services/sea_cms_api.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/channel_tab_bar.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';
import '../widgets/video_card.dart';
import '../widgets/video_grid_view.dart';
import 'video_detail_page.dart';
import 'video_list_page.dart';

/// 首页
///
/// 结构参考 resource/首页/首页.png：
///   顶部：Logo + 站名 + 搜索框 + 筛选
///   频道：由接口 ac=videotypes 返回的分类树动态生成（首页 + 电影/电视剧/综艺/动漫…）
///   内容：轮播图 +「每日推荐」横滑 +「近期热播电影」网格
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 频道列表：第一个固定为「首页」，其余由接口分类树生成
  List<Channel> _channels = [Channel.home];

  /// 当前频道下标
  int _currentIndex = 0;

  /// 已经打开过的频道（频道内容懒加载，避免一次性发起多个请求）
  final Set<int> _openedChannels = {0};

  /// 频道加载失败提示（保留最近一次失败原因，调试用；失败不影响「首页」频道使用）
  // ignore: unused_field
  String? _channelsError;

  /// 首页聚合数据
  HomeData? _homeData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 频道导航与首页数据并行加载，互不阻塞
    _loadHomeData();
    _loadChannels();
  }

  /// 加载频道导航（ac=videotypes 分类树 → 频道列表）
  Future<void> _loadChannels() async {
    try {
      final types = await SeaCmsApi.instance.fetchVideoTypes();
      if (!mounted) return;
      setState(() {
        _channels = Channel.buildFromTypes(types);
        _channelsError = null;
      });
    } on ApiException catch (e) {
      // 加载失败时保留「首页」频道，保证 App 仍可用；提示错误原因并提供重试
      if (!mounted) return;
      setState(() => _channelsError = e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('频道加载失败：${e.message}'),
          action: SnackBarAction(label: '重试', onPressed: _loadChannels),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// 加载首页聚合数据
  Future<void> _loadHomeData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SeaCmsApi.instance.fetchHome();
      if (!mounted) return;
      setState(() {
        _homeData = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// 切换频道
  void _onChannelChanged(int index) {
    setState(() {
      _currentIndex = index;
      _openedChannels.add(index);
    });
  }

  /// 点击影片 → 进入播放页
  void _onVideoTap(VideoItem item) {
    VideoDetailPage.open(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 黑色顶栏区域：顶部栏 + 频道 Tab
            Container(
              color: AppColors.darkBar,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeTopBar(
                    siteName: _homeData?.site.siteName ?? '',
                    onSearchTap: () => _toast('搜索功能开发中'),
                    onFilterTap: () => _toast('筛选功能开发中'),
                  ),
                  ChannelTabBar(
                    channels: _channels,
                    currentIndex: _currentIndex,
                    onChanged: _onChannelChanged,
                  ),
                ],
              ),
            ),
            // 频道内容（IndexedStack 保留各频道滚动位置）
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  for (var i = 0; i < _channels.length; i++)
                    _openedChannels.contains(i)
                        ? _buildChannelContent(i)
                        : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 频道内容：首页聚合内容 / 其它频道列表
  Widget _buildChannelContent(int index) {
    final channel = _channels[index];
    if (channel.isHome) return _buildHomeContent();

    return VideoGridView(
      key: PageStorageKey('channel_${channel.name}'),
      emptyText: '「${channel.name}」频道暂无内容',
      emptyHint: '可在海洋CMS后台添加该分类的影片',
      onItemTap: _onVideoTap,
      loader: (page) => _loadChannelVideos(channel, page),
    );
  }

  /// 频道分页数据（聚合父分类 + 全部子分类后合并）
  Future<VideoPage> _loadChannelVideos(Channel channel, int page) {
    return SeaCmsApi.instance.fetchMergedList(
      typeIds: channel.typeIds,
      page: page,
    );
  }

  /// 首页频道：轮播 + 每日推荐 + 近期热播
  Widget _buildHomeContent() {
    if (_loading) return const LoadingView(text: '正在加载首页数据');
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadHomeData);

    final home = _homeData;
    if (home == null) {
      return ErrorView(message: '首页数据为空', onRetry: _loadHomeData);
    }

    // 海洋CMS 推荐位未配置时回退到「热门」数据，避免「每日推荐」栏目空白
    final hasCommend = home.recommendVideos.isNotEmpty;
    final recommendVideos = hasCommend ? home.recommendVideos : home.hotVideos;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHomeData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 轮播图
          SliverToBoxAdapter(
            child: BannerCarousel(items: home.hotVideos, onTap: _onVideoTap),
          ),

          // 每日推荐
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '每日推荐',
              onMore: () => _openMoreList(
                title: '每日推荐',
                loader: (page) => SeaCmsApi.instance.fetchVideoList(
                  page: page,
                  commend: hasCommend ? 1 : null,
                  order: hasCommend ? 'time' : 'hit',
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildRecommendRow(recommendVideos)),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // 近期热播电影
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '近期热播电影',
              onMore: () => _openMoreList(
                title: '近期热播电影',
                loader: (page) => SeaCmsApi.instance.fetchVideoList(page: page),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
                childAspectRatio: 0.52,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = home.newVideos[index];
                  return VideoCard(item: item, onTap: () => _onVideoTap(item));
                },
                // 首页只展示一屏 6 个，其余进「更多」
                childCount: home.newVideos.length > 6 ? 6 : home.newVideos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 「每日推荐」横向滚动列表
  Widget _buildRecommendRow(List<VideoItem> items) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 120,
        child: EmptyView(text: '暂无推荐内容'),
      );
    }

    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => VideoCard(
          item: items[index],
          width: 100,
          titleSize: 11.5,
          onTap: () => _onVideoTap(items[index]),
        ),
      ),
    );
  }

  /// 打开「更多」列表页
  void _openMoreList({
    required String title,
    required Future<VideoPage> Function(int page) loader,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoListPage(title: title, loader: loader),
      ),
    );
  }

  /// 轻提示
  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
