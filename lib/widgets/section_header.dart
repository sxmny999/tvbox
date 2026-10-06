import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// 栏目标题条（黑底白字 + 右侧「更多」）
///
/// 对应效果图中的「每日推荐 / 更多」「近期热播电影 / 更多」
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;

  /// 标题条高度
  final double height;

  const SectionHeader({
    super.key,
    required this.title,
    this.onMore,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.darkBar,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              behavior: HitTestBehavior.opaque,
              child: const Row(
                children: [
                  Text(
                    '更多',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFFBDBDBD)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
