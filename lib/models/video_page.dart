import 'video_item.dart';

/// 分页列表结果（对应接口 ac=videolist 的返回结构）
class VideoPage {
  final List<VideoItem> list;
  final int total;
  final int page;
  final int pageSize;
  final int totalPage;

  const VideoPage({
    required this.list,
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPage = 0,
  });

  /// 空结果（用于参数为空等边界场景）
  const VideoPage.empty()
      : list = const [],
        total = 0,
        page = 1,
        pageSize = 20,
        totalPage = 0;

  factory VideoPage.fromJson(Map<String, dynamic> json) => VideoPage(
        list: (json['list'] as List<dynamic>? ?? [])
            .map((e) => VideoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: _int(json['total']),
        page: _int(json['page'], 1),
        pageSize: _int(json['pagesize'], 20),
        totalPage: _int(json['totalpage']),
      );

  /// 是否还有下一页
  bool get hasMore => page < totalPage;

  static int _int(dynamic value, [int fallback = 0]) =>
      int.tryParse(value?.toString() ?? '') ?? fallback;
}
