import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pangolin_content_sdk/pangolin_content_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isStarted returns a bool', (tester) async {
    final started = await PangolinContentSdk.instance.isStarted();
    expect(started, isA<bool>());
  });
}
