import 'video_type.dart';

/// 频道（首页效果图顶部的频道栏）
///
/// 频道列表完全由接口返回的分类树生成（`ac=videotypes`），不在客户端写死：
///   - 第一个固定为「首页」（聚合内容：轮播 + 推荐 + 热播）
///   - 其余频道 = CMS 顶级分类（电影 / 电视剧 / 综艺 / 动漫 ...）
///
/// 海洋CMS 的视频一般挂在「子分类」上（电影 → 动作片/爱情片/科幻片…），
/// 父分类本身查不到数据，所以每个频道聚合「父分类 + 全部子分类」（见 SeaCmsApi.fetchMergedList）。
class Channel {
  /// 频道名
  final String name;

  /// 是否为首页（首页展示聚合内容，其它频道展示列表）
  final bool isHome;

  /// 参与聚合的分类 id（父 + 子）
  final List<int> typeIds;

  /// 由 CMS 顶级分类生成频道（父分类 id + 全部子分类 id）
  factory Channel.fromVideoType(VideoType type) {
    return Channel(
      name: type.name,
      typeIds: [type.id, ...type.children.map((c) => c.id)],
    );
  }

  /// 「首页」频道（固定第一项，展示聚合内容）
  static const Channel home = Channel(name: '首页', isHome: true);

  const Channel({
    required this.name,
    this.isHome = false,
    this.typeIds = const [],
  });

  /// 由接口分类树构建完整频道列表：首页 + 各顶级分类
  static List<Channel> buildFromTypes(List<VideoType> types) {
    return [
      home,
      ...types.map(Channel.fromVideoType),
    ];
  }
}
