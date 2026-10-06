import 'video_item.dart';

/// 站点信息（对应接口 ac=siteinfo / home 中的 site 字段）
class SiteInfo {
  final String siteName;
  final String siteUrl;
  final String totalVideo;
  final String siteVersion;

  const SiteInfo({
    this.siteName = '',
    this.siteUrl = '',
    this.totalVideo = '',
    this.siteVersion = '',
  });

  factory SiteInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SiteInfo();
    return SiteInfo(
      siteName: json['site_name']?.toString() ?? '',
      siteUrl: json['site_url']?.toString() ?? '',
      totalVideo: json['total_video']?.toString() ?? '',
      siteVersion: json['site_version']?.toString() ?? '',
    );
  }
}

/// 首页聚合数据（对应接口 ac=home）
///
/// 接口返回 4 组数据，首页使用其中 3 组：
/// - hot_videos       按点击量：用于顶部轮播
/// - recommend_videos 推荐位：用于「每日推荐」
/// - new_videos       最新上架：用于「近期热播」
class HomeData {
  final SiteInfo site;
  final List<VideoItem> hotVideos;
  final List<VideoItem> recommendVideos;
  final List<VideoItem> newVideos;

  const HomeData({
    this.site = const SiteInfo(),
    this.hotVideos = const [],
    this.recommendVideos = const [],
    this.newVideos = const [],
  });

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
        site: SiteInfo.fromJson(json['site'] as Map<String, dynamic>?),
        hotVideos: _list(json['hot_videos']),
        recommendVideos: _list(json['recommend_videos']),
        newVideos: _list(json['new_videos']),
      );

  /// 解析 { list: [...] } 结构
  static List<VideoItem> _list(dynamic block) {
    if (block is! Map<String, dynamic>) return const [];
    final list = block['list'] as List<dynamic>? ?? [];
    return list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
