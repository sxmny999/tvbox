import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// 首页顶部栏：Logo + 站名 + 搜索框 + 筛选按钮
///
/// 对应效果图顶部的黑色区域
class HomeTopBar extends StatelessWidget {
  /// 站点名称（来自接口 site_name）
  final String siteName;

  /// 点击搜索框
  final VoidCallback? onSearchTap;

  /// 点击筛选
  final VoidCallback? onFilterTap;

  const HomeTopBar({
    super.key,
    this.siteName = '',
    this.onSearchTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: 8),
          // 站点名，过长时省略
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              siteName.isEmpty ? '影视大全' : siteName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildSearchBox()),
          const SizedBox(width: 8),
          _buildFilterButton(),
        ],
      ),
    );
  }

  /// 红蓝渐变 Logo（暂无图片资源，用图形代替）
  Widget _buildLogo() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFFE62117), Color(0xFF1E5AA8)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
    );
  }

  /// 圆角搜索框（点击进入搜索，暂未实现）
  Widget _buildSearchBox() {
    return GestureDetector(
      onTap: onSearchTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: AppColors.searchBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                '搜索你想看的',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Color(0xFF8F8F8F)),
              ),
            ),
            Icon(Icons.search, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// 描边「筛选」按钮
  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: onFilterTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.filter_alt_outlined, size: 14, color: Colors.white),
            SizedBox(width: 3),
            Text('筛选', style: TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
