import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pangolin_content_sdk/pangolin_content_sdk.dart';
import 'package:pangolin_content_sdk/pangolin_content_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelPangolinContentSdk();
  const channel = MethodChannel('pangolin_content_sdk');
  MethodCall? lastMethodCall;

  setUp(() {
    lastMethodCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          lastMethodCall = methodCall;
          switch (methodCall.method) {
            case 'initialize':
              return <String, Object?>{'success': true, 'message': 'ok'};
            case 'isStarted':
              return true;
            case 'requestRecommendedPermissions':
              return <String, Object?>{
                'android.permission.READ_PHONE_STATE': 1,
                'appTrackingTransparency': 0,
              };
            case 'checkNetworkAccess':
              return <Map<String, Object?>>[
                <String, Object?>{
                  'host': 'csj-sp.csjdeveloper.com',
                  'port': 443,
                  'reachable': true,
                  'elapsedMs': 12,
                },
              ];
            case 'getLoginSignString':
              return <String, Object?>{
                'sign': 'signed-value',
                'nonce': 'nonce-value',
                'timestampSeconds': 123,
                'params': <String, String>{'ouid': 'user-1'},
              };
            case 'login':
              return <String, Object?>{'uid': 'user-1'};
            case 'logout':
              return <String, Object?>{'uid': 'user-1'};
            case 'isLogin':
              return true;
            case 'requestAllDramas':
              return <Map<String, Object?>>[
                <String, Object?>{'id': 7, 'title': 'Test Drama'},
              ];
            case 'openDramaDetail':
              return null;
            case 'openDramaDrawFeed':
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize', () async {
    final result = await platform.initialize(
      const PangolinContentConfig(
        appId: 'app-id',
        configFileName: 'SDK_Setting.json',
      ),
    );

    expect(result.success, isTrue);
  });

  test('requestRecommendedPermissions', () async {
    final permissions = await platform.requestRecommendedPermissions();

    expect(permissions['android.permission.READ_PHONE_STATE'], isTrue);
    expect(permissions['appTrackingTransparency'], isFalse);
  });

  test('checkNetworkAccess', () async {
    final checks = await platform.checkNetworkAccess(
      hosts: const <String>['csj-sp.csjdeveloper.com'],
      port: 443,
      timeoutMillis: 3000,
    );

    expect(checks.single.host, 'csj-sp.csjdeveloper.com');
    expect(checks.single.reachable, isTrue);
  });

  test('requestAllDramas', () async {
    final dramas = await platform.requestAllDramas(
      page: 1,
      pageSize: 20,
      orderByHot: false,
    );

    expect(dramas.single.id, 7);
    expect(dramas.single.title, 'Test Drama');
  });

  test('openDramaDrawFeed', () async {
    await platform.openDramaDrawFeed(
      options: const PangolinDramaDrawOptions(
        channelType: PangolinDramaDrawChannelType.theater,
        hideLikeButton: true,
        hideFavorButton: true,
        progressBarStyle: PangolinDramaDrawProgressBarStyle.dark,
        adCodeId: 'draw-ad',
        nativeAdCodeId: 'draw-native-ad',
        customCategory: '都市',
        dramaFree: 2,
        detailUseCustomRewardAd: true,
        detailHideBack: true,
        detailHideMore: true,
        detailBottomOffset: 24,
        finishOnBlockedBack: true,
        topDramaId: 26946,
      ),
    );

    expect(lastMethodCall?.method, 'openDramaDrawFeed');
    final arguments = lastMethodCall?.arguments as Map<Object?, Object?>;
    final options = arguments['options'] as Map<Object?, Object?>;
    expect(options['channelType'], 'theater');
    expect(options['contentType'], 'onlyDrama');
    expect(options['hideLikeButton'], isTrue);
    expect(options['hideFavorButton'], isTrue);
    expect(options['progressBarStyle'], 'dark');
    expect(options['adCodeId'], 'draw-ad');
    expect(options['nativeAdCodeId'], 'draw-native-ad');
    expect(options['customCategory'], '都市');
    expect(options['dramaFree'], 2);
    expect(options['detailUseCustomRewardAd'], isTrue);
    expect(options['detailHideBack'], isTrue);
    expect(options['detailHideMore'], isTrue);
    expect(options['detailBottomOffset'], 24);
    expect(options['finishOnBlockedBack'], isTrue);
    expect(options['topDramaId'], 26946);
  });

  test('openDramaDetail forwards detail page options', () async {
    await platform.openDramaDetail(
      dramaId: 7,
      options: const PangolinDramaDetailOptions(
        index: 3,
        freeSet: 5,
        lockSet: 2,
        playDurationSeconds: 12,
        fromGid: 99,
        enterFrom: PangolinDramaEnterFrom.dramaHome,
        recMap: <String, Object?>{'source': 'home'},
        unlockAdMode: PangolinDramaUnlockAdMode.specific,
        hideDoubleClick: true,
        hideLongClickSpeed: true,
        bottomOffset: 10,
        topOffset: 20,
        scriptTipsTopMargin: 30,
        icpTipsBottomMargin: 40,
        useCustomRewardAd: true,
      ),
    );

    expect(lastMethodCall?.method, 'openDramaDetail');
    final arguments = lastMethodCall?.arguments as Map<Object?, Object?>;
    final options = arguments['options'] as Map<Object?, Object?>;
    expect(arguments['dramaId'], 7);
    expect(options['index'], 3);
    expect(options['enterFrom'], 'dramaHome');
    expect(options['recMap'], <String, Object?>{'source': 'home'});
    expect(options['unlockAdMode'], 'specific');
    expect(options['hideDoubleClick'], isTrue);
    expect(options['hideLongClickSpeed'], isTrue);
    expect(options['bottomOffset'], 10);
    expect(options['topOffset'], 20);
    expect(options['scriptTipsTopMargin'], 30);
    expect(options['icpTipsBottomMargin'], 40);
    expect(options['useCustomRewardAd'], isTrue);
  });

  test('login binding methods', () async {
    final sign = await platform.getLoginSignString(
      serverKey: 'server-key',
      uid: 'user-1',
      nonce: 'nonce-value',
      timestampSeconds: 123,
    );

    expect(sign.sign, 'signed-value');
    expect(lastMethodCall?.method, 'getLoginSignString');

    final user = await platform.loginWithSign(sign.sign);
    expect(user?.uid, 'user-1');

    expect(await platform.isLoggedIn(), isTrue);

    final loggedOut = await platform.logout();
    expect(loggedOut?.uid, 'user-1');
  });
}
