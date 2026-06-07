import 'package:flutter_test/flutter_test.dart';
import 'package:pangolin_content_sdk_example/main.dart';

void main() {
  testWidgets('renders drama workbench', (tester) async {
    await tester.pumpWidget(const PangolinExampleApp());

    expect(find.text('穿山甲内容 SDK'), findsOneWidget);
    expect(find.text('初始化'), findsWidgets);
  });
}
