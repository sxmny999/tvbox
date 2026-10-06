import 'play_source.dart';

/// 视频详情模型（对应海洋CMS `ac=videodetail` 接口）
///
/// 接口直接返回 sea_data 的原始字段（v_name / v_actor / body / playdata 等），
/// 这里只取 App 需要的字段，并把 playdata 解析成「片源 + 选集」结构。
class VideoDetail {
  /// 视频 id
  final int id;

  /// 片名
  final String name;

  /// 海报
  final String pic;

  /// 年份
  final String year;

  /// 地区
  final String area;

  /// 语言
  final String lang;

  /// 更新状态，如「全32集」「更新至第02集」
  final String note;

  /// 导演
  final String director;

  /// 演员
  final String actor;

  /// 分类名，如「大陆剧」
  final String typeName;

  /// 播放量
  final int hit;

  /// 剧情简介（sea_content.body）
  final String intro;

  /// 播放数据（已解析的片源列表）
  final List<PlaySource> sources;

  const VideoDetail({
    required this.id,
    required this.name,
    required this.pic,
    required this.year,
    required this.area,
    required this.lang,
    required this.note,
    required this.director,
    required this.actor,
    required this.typeName,
    required this.hit,
    required this.intro,
    required this.sources,
  });

  /// 是否有任何可播放的片源
  bool get playable => sources.isNotEmpty;

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    // 简介：sea_content.body 与 playdata 里都可能有简介，取非空者
    final intro = '${json['body'] ?? ''}'.trim();

    return VideoDetail(
      id: int.tryParse('${json['v_id']}') ?? 0,
      name: '${json['v_name'] ?? ''}',
      pic: '${json['v_pic'] ?? ''}',
      year: '${json['v_publishyear'] ?? ''}',
      area: '${json['v_publisharea'] ?? ''}',
      lang: '${json['v_lang'] ?? ''}',
      note: '${json['v_note'] ?? ''}',
      director: '${json['v_director'] ?? ''}',
      actor: '${json['v_actor'] ?? ''}',
      typeName: '${json['typename'] ?? ''}',
      hit: int.tryParse('${json['v_hit']}') ?? 0,
      intro: intro,
      // playdata 原始串解析为片源+选集
      sources: PlayDataParser.parse('${json['playdata'] ?? ''}'),
    );
  }
}
