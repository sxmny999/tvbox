import 'package:flutter/material.dart';

/// 全局配色
/// 参考首页效果图：黑色顶栏 + 白色内容区 + 红色强调色
class AppColors {
  AppColors._();

  /// 品牌红：Tab 选中态、进度条、强调色
  static const Color primary = Color(0xFFE62117);

  /// 顶栏 / 栏目标题条 底色
  static const Color darkBar = Color(0xFF000000);

  /// 页面内容区底色
  static const Color pageBg = Color(0xFFFFFFFF);

  /// 主要文字（标题、影片名）
  static const Color textPrimary = Color(0xFF111111);

  /// 次要文字（副标题、更新状态）
  static const Color textSecondary = Color(0xFF999999);

  /// 搜索框底色（黑色顶栏上的深灰）
  static const Color searchBg = Color(0xFF2A2A2A);

  /// 图片占位底色
  static const Color placeholder = Color(0xFFEFEFEF);

  /// 分割线
  static const Color divider = Color(0xFFEDEDED);
}

/// 全局主题
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pageBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        // 中文环境下刷新指示器颜色跟随品牌色
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
      );
}
