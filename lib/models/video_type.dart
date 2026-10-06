/// 视频分类模型（对应海洋CMS `ac=videotypes` 接口）
///
/// 接口返回两级分类树：
///   data: [
///     { id: "1", name: "电影", upid: "0", order: "1",
///       children: [ { id: "5", name: "动作片", upid: "1", ... } ] }
///   ]
/// 注意：CMS 里 id / upid / order 均为字符串，需转成 int。
class VideoType {
  /// 分类 id
  final int id;

  /// 分类名
  final String name;

  /// 父分类 id（0 表示顶级分类）
  final int upid;

  /// 排序号
  final int order;

  /// 子分类
  final List<VideoType> children;

  const VideoType({
    required this.id,
    required this.name,
    required this.upid,
    required this.order,
    this.children = const [],
  });

  factory VideoType.fromJson(Map<String, dynamic> json) {
    return VideoType(
      id: int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      upid: int.tryParse('${json['upid']}') ?? 0,
      order: int.tryParse('${json['order']}') ?? 0,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => VideoType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
