import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/home_data.dart';
import '../models/video_detail.dart';
import '../models/video_item.dart';
import '../models/video_page.dart';
import '../models/video_type.dart';

/// 接口异常
///
/// 统一把网络错误 / 业务错误转成可以直接展示给用户的中文提示。
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// 海洋CMS 接口服务（单例）
///
/// 接口文档：http://localhost:8080/json.php?ac=list
/// 返回值统一结构：{ code: 200, msg: 'success', data: ... }
class SeaCmsApi {
  SeaCmsApi._();

  static final SeaCmsApi instance = SeaCmsApi._();

  /// 请求超时时间
  static const Duration _timeout = Duration(seconds: 15);

  /// 统一的 GET 请求，负责拼参数、解析 JSON、转换异常
  Future<dynamic> _get(String ac, [Map<String, String> params = const {}]) async {
    final uri = Uri.parse(ApiConfig.jsonApi).replace(
      queryParameters: {'ac': ac, ...params},
    );

    http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } catch (_) {
      throw ApiException('无法连接服务器\n${ApiConfig.baseUrl}\n请确认海洋CMS已启动');
    }

    if (response.statusCode != 200) {
      throw ApiException('服务器返回异常（${response.statusCode}）');
    }

    Map<String, dynamic> body;
    try {
      // 接口返回 UTF-8，必须按 bodyBytes 解码，否则中文会乱码
      body = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('接口返回格式异常');
    }

    if (body['code'] != 200) {
      throw ApiException(body['msg']?.toString() ?? '接口调用失败');
    }
    return body['data'];
  }

  /// 首页聚合数据（轮播 / 每日推荐 / 近期热播）
  Future<HomeData> fetchHome() async {
    final data = await _get('home');
    return HomeData.fromJson(data as Map<String, dynamic>);
  }

  /// 视频分类树（顶部频道导航的数据来源）
  ///
  /// 返回两级分类：电影/电视剧/综艺/动漫 …（含各自的子分类）
  Future<List<VideoType>> fetchVideoTypes() async {
    final data = await _get('videotypes');
    return (data as List<dynamic>)
        .map((e) => VideoType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 视频详情（含简介与 playdata 播放数据）
  ///
  /// 返回字段为 sea_data 原始字段 + body（简介）+ playdata（播放地址原始串），
  /// playdata 会在 [VideoDetail.fromJson] 中解析成「片源 + 选集」。
  Future<VideoDetail> fetchVideoDetail(int id) async {
    final data = await _get('videodetail', {'id': '$id'});
    return VideoDetail.fromJson(data as Map<String, dynamic>);
  }

  /// 视频列表
  ///
  /// [typeId] 分类 id，[keyword] 关键词，[commend] 推荐位（1 为推荐），
  /// [order] 排序：time 最新 / hit 最多播放 / score 评分
  Future<VideoPage> fetchVideoList({
    int page = 1,
    int pageSize = 20,
    int? typeId,
    String? keyword,
    int? commend,
    String order = 'time',
  }) async {
    final params = <String, String>{
      'page': '$page',
      'pagesize': '$pageSize',
      'order': order,
    };
    if (typeId != null && typeId > 0) params['type'] = '$typeId';
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (commend != null) params['commend'] = '$commend';

    final data = await _get('videolist', params);
    return VideoPage.fromJson(data as Map<String, dynamic>);
  }

  /// 合并多个分类的列表
  ///
  /// 海洋CMS 的 `type` 参数只做精确匹配，父分类（电影/电视剧）下没有直接挂视频，
  /// 因此父级频道需要把子分类的数据一起取回来再合并、按上架时间排序。
  Future<VideoPage> fetchMergedList({
    required List<int> typeIds,
    int page = 1,
    int pageSize = 20,
    String order = 'time',
  }) async {
    if (typeIds.isEmpty) return const VideoPage.empty();
    if (typeIds.length == 1) {
      return fetchVideoList(typeId: typeIds.first, page: page, pageSize: pageSize, order: order);
    }

    // 并发请求各个子分类，减少等待时间
    final results = await Future.wait(
      typeIds.map((id) => fetchVideoList(
            typeId: id,
            page: page,
            pageSize: pageSize,
            order: order,
          )),
    );

    // 合并去重（同一部影片理论上只属于一个分类，这里做防御）
    final merged = <String, VideoItem>{};
    var total = 0;
    var maxTotalPage = 1;
    for (final result in results) {
      total += result.total;
      if (result.totalPage > maxTotalPage) maxTotalPage = result.totalPage;
      for (final item in result.list) {
        merged[item.id] = item;
      }
    }

    final list = merged.values.toList()
      ..sort((a, b) => b.addTimeValue.compareTo(a.addTimeValue));

    return VideoPage(
      list: list.take(pageSize).toList(),
      total: total,
      page: page,
      pageSize: pageSize,
      totalPage: maxTotalPage,
    );
  }
}
