import 'package:flutter_test/flutter_test.dart';
import 'package:pangolin_content_sdk/pangolin_content_sdk.dart';
import 'package:pangolin_content_sdk/pangolin_content_sdk_method_channel.dart';
import 'package:pangolin_content_sdk/pangolin_content_sdk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPangolinContentSdkPlatform
    with MockPlatformInterfaceMixin
    implements PangolinContentSdkPlatform {
  @override
  Future<PangolinSdkStartResult> initialize(PangolinContentConfig config) {
    return Future.value(const PangolinSdkStartResult(success: true));
  }

  @override
  Future<bool> isStarted() => Future.value(true);

  @override
  Future<Map<String, bool>> requestRecommendedPermissions() {
    return Future.value(const <String, bool>{
      'android.permission.INTERNET': true,
    });
  }

  @override
  Future<List<PangolinNetworkCheckResult>> checkNetworkAccess({
    required List<String> hosts,
    required int port,
    required int timeoutMillis,
  }) {
    return Future.value(
      hosts
          .map(
            (host) => PangolinNetworkCheckResult(
              host: host,
              port: port,
              reachable: true,
              elapsedMs: 1,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> setTeenagerMode(bool enabled) async {}

  @override
  Future<void> setRewardAdHandler(PangolinRewardAdHandler? handler) async {}

  @override
  Future<PangolinLoginSign> getLoginSignString({
    required String serverKey,
    required String uid,
    String? nonce,
    int? timestampSeconds,
    Map<String, String> params = const <String, String>{},
  }) {
    return Future.value(
      PangolinLoginSign(
        sign: 'signed-$uid',
        nonce: nonce ?? 'nonce',
        timestampSeconds: timestampSeconds ?? 1,
        params: <String, String>{...params, 'ouid': uid},
      ),
    );
  }

  @override
  Future<PangolinUser?> loginWithSign(String sign) {
    return Future.value(const PangolinUser(uid: 'user-1'));
  }

  @override
  Future<PangolinUser?> logout() {
    return Future.value(const PangolinUser(uid: 'user-1'));
  }

  @override
  Future<bool> isLoggedIn() {
    return Future.value(true);
  }

  @override
  Future<List<PangolinDrama>> requestAllDramas({
    required int page,
    required int pageSize,
    required bool orderByHot,
  }) {
    return Future.value(const <PangolinDrama>[
      PangolinDrama(id: 1000, title: 'Drama'),
    ]);
  }

  @override
  Future<List<PangolinDrama>> requestRecommendedDramas({
    required int page,
    required int pageSize,
  }) {
    return Future.value(const <PangolinDrama>[]);
  }

  @override
  Future<List<PangolinDrama>> requestDramasByIds(List<int> ids) {
    return Future.value(ids.map((id) => PangolinDrama(id: id)).toList());
  }

  @override
  Future<List<PangolinDrama>> requestDramasByCategory(
    String category, {
    required int page,
    required int pageSize,
    required int order,
  }) {
    return Future.value(const <PangolinDrama>[]);
  }

  @override
  Future<List<PangolinDrama>> searchDramas(
    String query, {
    required bool fuzzy,
    required int page,
    required int pageSize,
  }) {
    return Future.value(const <PangolinDrama>[]);
  }

  @override
  Future<List<String>> requestDramaCategories() {
    return Future.value(const <String>['都市']);
  }

  @override
  Future<List<PangolinDrama>> getDramaHistory({
    required int offset,
    required int count,
  }) {
    return Future.value(const <PangolinDrama>[]);
  }

  @override
  Future<List<PangolinDrama>> getFavorList({
    required int offset,
    required int count,
  }) {
    return Future.value(const <PangolinDrama>[]);
  }

  @override
  Future<void> clearDramaHistory() async {}

  @override
  Future<PangolinDramaLock> verifyDramaParams({
    required int total,
    required int freeSet,
    required int lockSet,
  }) {
    return Future.value(PangolinDramaLock(freeSet: freeSet, lockSet: lockSet));
  }

  @override
  Future<void> openDramaDetail({
    required int dramaId,
    required PangolinDramaDetailOptions options,
  }) async {}

  @override
  Future<void> openDramaDrawFeed({
    required PangolinDramaDrawOptions options,
  }) async {}

  @override
  Future<void> pauseEmbeddedDramaDrawFeed() async {}

  @override
  Future<void> resumeEmbeddedDramaDrawFeed() async {}
}

void main() {
  final initialPlatform = PangolinContentSdkPlatform.instance;

  test('$MethodChannelPangolinContentSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPangolinContentSdk>());
  });

  test('PangolinContentConfig uses Android playback defaults', () {
    final map = const PangolinContentConfig(
      appId: 'app-id',
      configFileName: 'SDK_Setting.json',
    ).toMap();

    expect(map['disableVerifier'], isTrue);
    expect(map['disableTTPlayer'], isFalse);
  });

  test('PangolinDrama reads Pangolin coverImage field', () {
    final drama = PangolinDrama.fromMap(const <Object?, Object?>{
      'id': 7,
      'title': 'Test Drama',
      'coverImage': 'https://example.com/cover.jpg',
    });

    expect(drama.coverUrl, 'https://example.com/cover.jpg');
  });

  test('PangolinDrama normalizes protocol-relative cover URLs', () {
    final drama = PangolinDrama.fromMap(const <Object?, Object?>{
      'id': 7,
      'coverImage': '//example.com/cover.jpg',
    });

    expect(drama.coverUrl, 'https://example.com/cover.jpg');
  });

  test('PangolinDramaDrawOptions maps Flutter enums to Android values', () {
    final map = const PangolinDramaDrawOptions(
      channelType: PangolinDramaDrawChannelType.recommendTheater,
      hideChannelName: false,
      progressBarStyle: PangolinDramaDrawProgressBarStyle.light,
      adCodeId: 'draw-ad',
      customCategory: '古言',
      detailFreeSet: -1,
      detailLockSet: -1,
      detailUseCustomRewardAd: true,
      detailHideCellularToast: true,
      detailTopOffset: 12,
      finishOnBlockedBack: true,
    ).toMap();

    expect(map['channelType'], 'recommendTheater');
    expect(map['contentType'], 'onlyDrama');
    expect(map['hideChannelName'], isFalse);
    expect(map['progressBarStyle'], 'light');
    expect(map['adCodeId'], 'draw-ad');
    expect(map['customCategory'], '古言');
    expect(map['dramaFree'], 5);
    expect(map['detailFreeSet'], -1);
    expect(map['detailLockSet'], -1);
    expect(map['detailUseCustomRewardAd'], isTrue);
    expect(map['detailHideCellularToast'], isTrue);
    expect(map['detailTopOffset'], 12);
    expect(map['finishOnBlockedBack'], isTrue);
  });

  test('PangolinDramaDetailOptions maps detail page options', () {
    final map = const PangolinDramaDetailOptions(
      index: 2,
      fromGid: 88,
      enterFrom: PangolinDramaEnterFrom.dramaCard,
      recMap: <String, Object?>{'scene': 'card'},
      unlockAdMode: PangolinDramaUnlockAdMode.specific,
      hideDoubleClick: true,
      hideLongClickSpeed: true,
      bottomOffset: 10,
      topOffset: 20,
      scriptTipsTopMargin: 30,
      icpTipsBottomMargin: 40,
      useCustomRewardAd: true,
    ).toMap();

    expect(map['index'], 2);
    expect(map['fromGid'], 88);
    expect(map['enterFrom'], 'dramaCard');
    expect(map['recMap'], <String, Object?>{'scene': 'card'});
    expect(map['unlockAdMode'], 'specific');
    expect(map['hideDoubleClick'], isTrue);
    expect(map['hideLongClickSpeed'], isTrue);
    expect(map['bottomOffset'], 10);
    expect(map['topOffset'], 20);
    expect(map['scriptTipsTopMargin'], 30);
    expect(map['icpTipsBottomMargin'], 40);
    expect(map['useCustomRewardAd'], isTrue);
  });

  test('initialize and requestAllDramas', () async {
    final fakePlatform = MockPangolinContentSdkPlatform();
    PangolinContentSdkPlatform.instance = fakePlatform;

    final result = await PangolinContentSdk.instance.initialize(
      const PangolinContentConfig(
        appId: 'app-id',
        configFileName: 'SDK_Setting.json',
      ),
    );
    final dramas = await PangolinContentSdk.instance.requestAllDramas();

    expect(result.success, isTrue);
    expect(dramas.single.id, 1000);
  });

  test('loginWithUid creates sign and logs in', () async {
    final fakePlatform = MockPangolinContentSdkPlatform();
    PangolinContentSdkPlatform.instance = fakePlatform;

    final user = await PangolinContentSdk.instance.loginWithUid(
      uid: 'user-1',
      serverKey: 'server-key',
      nonce: 'nonce',
      timestampSeconds: 123,
    );

    expect(user?.uid, 'user-1');
  });
}
