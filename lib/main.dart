import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'core/app_theme.dart';
import 'pages/home_page.dart';

void main() {
  // media_kit（libmpv）初始化：必须在创建任何 Player 之前调用
  MediaKit.ensureInitialized();
  runApp(const TvBoxApp());
}

/// 应用入口
class TvBoxApp extends StatelessWidget {
  const TvBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '影视大全',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}
