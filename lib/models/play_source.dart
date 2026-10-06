/// 片源与选集模型 + 海洋CMS播放数据解析
///
/// 海洋CMS 的 playdata（sea_playdata.body）原始格式：
///   `片源标识$$集名1$地址1$备注1#集名2$地址2$备注2#...$$$片源2$$集名$地址$备注#...`
///
/// 本地 CMS 实际数据样例（单一片源，片源标识为空）：
///   `$$第 1 集$https://jimaoys90.com/public/playback/xxx/smart.m3u8$jlm3u8#第 2 集$https://.../smart.m3u8$jlm3u8#...`
///
/// 分隔符约定：
///   - 片源之间用 `$$$` 分隔（多片源场景）
///   - 片源标识与集列表之间用 `$$` 分隔
///   - 集与集之间用 `#` 分隔
///   - 每集内部用 `$` 分隔：`集名$播放地址$备注`
class Episode {
  /// 集名，如「第 1 集」
  final String title;

  /// 播放地址（m3u8 / 直链）
  final String url;

  const Episode({required this.title, required this.url});
}

/// 片源（一个片源包含若干选集）
class PlaySource {
  /// 片源名（CMS 标识为空时显示「默认源」）
  final String name;

  /// 选集列表
  final List<Episode> episodes;

  const PlaySource({required this.name, required this.episodes});

  bool get isEmpty => episodes.isEmpty;
}

/// playdata 解析器
class PlayDataParser {
  /// 解析原始播放数据为片源列表
  ///
  /// [raw] 为空或格式异常时返回空列表。
  static List<PlaySource> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];

    // 1) 按 $$$ 拆成多个片源组
    final groups = trimmed.split('\$\$\$');
    final sources = <PlaySource>[];

    for (final group in groups) {
      final g = group.trim();
      if (g.isEmpty) continue;

      // 2) 找到片源标识与集列表之间的 $$ 分隔符
      //    格式：`标识$$集列表`（标识可能为空，即以 $$ 开头）
      final sepIdx = g.indexOf('\$\$');
      final flag = sepIdx >= 0 ? g.substring(0, sepIdx).trim() : '';
      final epStr = sepIdx >= 0 ? g.substring(sepIdx + 2) : g;

      // 3) 按 # 拆出每一集：`集名$地址$备注`
      final episodes = <Episode>[];
      for (final rawEp in epStr.split('#')) {
        final ep = rawEp.trim();
        if (ep.isEmpty) continue;

        final segs = ep.split('\$');
        // 过滤空段：$$ 开头的数据拆出来第一段通常是空串
        final parts = segs.where((s) => s.trim().isNotEmpty).toList();
        if (parts.length < 2) continue;

        // 集名可能是「第 1 集（第 1 季 第 1 集）」这类带括号补充说明的长文本，
        // 选集按钮较窄，这里只保留主标题
        final title = _shortenTitle(parts[0].trim());
        final url = parts[1].trim();
        // 地址必须是 http 开头才视为有效播放地址
        if (url.isEmpty || !url.startsWith('http')) continue;

        episodes.add(Episode(title: title, url: url));
      }

      if (episodes.isEmpty) continue;

      // 片源名：优先用 CMS 标识，为空时显示「默认源」
      sources.add(PlaySource(
        name: flag.isNotEmpty ? flag : '默认源',
        episodes: episodes,
      ));
    }

    return sources;
  }

  /// 精简集名：去掉括号里的补充说明，并把「第 1 集」压成「第1集」
  /// 例：「第 1 集（第 1 季 第 1 集）」→「第1集」
  static String _shortenTitle(String raw) {
    var t = raw;
    final idxCn = t.indexOf('（');
    if (idxCn > 0) t = t.substring(0, idxCn);
    final idxEn = t.indexOf('(');
    if (idxEn > 0) t = t.substring(0, idxEn);
    // 去掉数字两侧的空格，让按钮文字更紧凑
    return t.replaceAll(RegExp(r'\s+'), '').trim();
  }
}
