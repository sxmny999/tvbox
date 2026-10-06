import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/channel.dart';

/// 频道 Tab 栏（横向可滚动，选中项红色加粗 + 底部红色指示条）
///
/// 对应效果图顶部的：首页 / Netflix / 电影 / 电视剧 / 短剧 / 动漫
class ChannelTabBar extends StatelessWidget {
  final List<Channel> channels;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const ChannelTabBar({
    super.key,
    required this.channels,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: channels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final selected = index == currentIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      channels[index].name,
                      style: TextStyle(
                        fontSize: selected ? 17 : 16,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        color: selected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 选中指示条：宽度跟随文字
                    Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
