/// 视频条目模型
///
/// 对应海洋CMS json.php 中 videolist / home 返回的单个视频对象。
/// 接口里所有字段都是字符串，这里统一做空值兜底，避免上层判空。
class VideoItem {
  /// 视频 id
  final String id;

  /// 所属分类 id
  final String typeId;

  /// 片名
  final String name;

  /// 竖版海报
  final String pic;

  /// 横版海报（部分数据为空）
  final String spic;

  /// 更新状态，如「更新至12集」「HD」「全32集」
  final String note;

  /// 主演（接口用 " / " 分隔）
  final String actor;

  /// 导演
  final String director;

  /// 年份
  final String year;

  /// 地区
  final String area;

  /// 语言
  final String lang;

  /// 评分
  final String score;

  /// 上架时间戳（秒），用于合并多分类时排序
  final String addTime;

  const VideoItem({
    required this.id,
    this.typeId = '',
    this.name = '',
    this.pic = '',
    this.spic = '',
    this.note = '',
    this.actor = '',
    this.director = '',
    this.year = '',
    this.area = '',
    this.lang = '',
    this.score = '',
    this.addTime = '',
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) => VideoItem(
        id: _str(json['id']),
        typeId: _str(json['type_id']),
        name: _str(json['name']),
        pic: _str(json['pic']),
        spic: _str(json['spic']),
        note: _str(json['note']),
        actor: _str(json['actor']),
        director: _str(json['director']),
        year: _str(json['year']),
        area: _str(json['area']),
        lang: _str(json['lang']),
        score: _str(json['score']),
        addTime: _str(json['addtime']),
      );

  /// 接口字段统一转字符串
  static String _str(dynamic value) => value == null ? '' : value.toString();

  /// 演员列表
  List<String> get actorList =>
      actor.split(' / ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// 用于列表展示的海报地址：优先横版，其次竖版
  String get coverImage => spic.isNotEmpty ? spic : pic;

  /// 上架时间戳（排序用）
  int get addTimeValue => int.tryParse(addTime) ?? 0;
}
