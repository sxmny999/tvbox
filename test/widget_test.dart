import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tvbox/models/video_item.dart';
import 'package:tvbox/widgets/video_card.dart';

void main() {
  testWidgets('VideoCard 展示片名与更新状态', (WidgetTester tester) async {
    const item = VideoItem(
      id: '1',
      name: '测试影片',
      pic: '',
      note: '更新至12集',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: VideoCard(item: item, width: 100),
          ),
        ),
      ),
    );

    expect(find.text('测试影片'), findsOneWidget);
    expect(find.text('更新至12集'), findsOneWidget);
  });
}
