library;

import 'pangolin_content_sdk_platform_interface.dart';
import 'src/pangolin_content_models.dart';

export 'src/pangolin_content_models.dart';

class PangolinContentSdk {
  PangolinContentSdk._();

  static final PangolinContentSdk instance = PangolinContentSdk._();

  Future<PangolinSdkStartResult> initialize(PangolinContentConfig config) {
    return PangolinContentSdkPlatform.instance.initialize(config);
  }

  Future<bool> isStarted() {
    return PangolinContentSdkPlatform.instance.isStarted();
  }

  Future<Map<String, bool>> requestRecommendedPermissions() {
    return PangolinContentSdkPlatform.instance.requestRecommendedPermissions();
  }

  Future<List<PangolinNetworkCheckResult>> checkNetworkAccess({
    List<String> hosts = const <String>[
      'csj-sp.csjdeveloper.com',
      'toblog.ctobsnssdk.com',
    ],
    int port = 443,
    int timeoutMillis = 3000,
  }) {
    return PangolinContentSdkPlatform.instance.checkNetworkAccess(
      hosts: hosts,
      port: port,
      timeoutMillis: timeoutMillis,
    );
  }

  Future<void> setTeenagerMode(bool enabled) {
    return PangolinContentSdkPlatform.instance.setTeenagerMode(enabled);
  }

  Future<void> setRewardAdHandler(PangolinRewardAdHandler? handler) {
    return PangolinContentSdkPlatform.instance.setRewardAdHandler(handler);
  }

  Future<PangolinLoginSign> getLoginSignString({
    required String serverKey,
    required String uid,
    String? nonce,
    int? timestampSeconds,
    Map<String, String> params = const <String, String>{},
  }) {
    return PangolinContentSdkPlatform.instance.getLoginSignString(
      serverKey: serverKey,
      uid: uid,
      nonce: nonce,
      timestampSeconds: timestampSeconds,
      params: params,
    );
  }

  Future<PangolinUser?> loginWithSign(String sign) {
    return PangolinContentSdkPlatform.instance.loginWithSign(sign);
  }

  Future<PangolinUser?> loginWithUid({
    required String uid,
    required String serverKey,
    String? nonce,
    int? timestampSeconds,
    Map<String, String> params = const <String, String>{},
  }) async {
    final loginSign = await getLoginSignString(
      serverKey: serverKey,
      uid: uid,
      nonce: nonce,
      timestampSeconds: timestampSeconds,
      params: params,
    );
    return loginWithSign(loginSign.sign);
  }

  Future<PangolinUser?> logout() {
    return PangolinContentSdkPlatform.instance.logout();
  }

  Future<bool> isLoggedIn() {
    return PangolinContentSdkPlatform.instance.isLoggedIn();
  }

  Future<List<PangolinDrama>> requestAllDramas({
    int page = 1,
    int pageSize = 20,
    bool orderByHot = false,
  }) {
    return PangolinContentSdkPlatform.instance.requestAllDramas(
      page: page,
      pageSize: pageSize,
      orderByHot: orderByHot,
    );
  }

  Future<List<PangolinDrama>> requestRecommendedDramas({
    int page = 1,
    int pageSize = 20,
  }) {
    return PangolinContentSdkPlatform.instance.requestRecommendedDramas(
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<PangolinDrama>> requestDramasByIds(List<int> ids) {
    return PangolinContentSdkPlatform.instance.requestDramasByIds(ids);
  }

  Future<List<PangolinDrama>> requestDramasByCategory(
    String category, {
    int page = 1,
    int pageSize = 20,
    int order = 1,
  }) {
    return PangolinContentSdkPlatform.instance.requestDramasByCategory(
      category,
      page: page,
      pageSize: pageSize,
      order: order,
    );
  }

  Future<List<PangolinDrama>> searchDramas(
    String query, {
    bool fuzzy = true,
    int page = 1,
    int pageSize = 20,
  }) {
    return PangolinContentSdkPlatform.instance.searchDramas(
      query,
      fuzzy: fuzzy,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<String>> requestDramaCategories() {
    return PangolinContentSdkPlatform.instance.requestDramaCategories();
  }

  Future<List<PangolinDrama>> getDramaHistory({int offset = 0, int count = 0}) {
    return PangolinContentSdkPlatform.instance.getDramaHistory(
      offset: offset,
      count: count,
    );
  }

  Future<List<PangolinDrama>> getFavorList({int offset = 0, int count = 0}) {
    return PangolinContentSdkPlatform.instance.getFavorList(
      offset: offset,
      count: count,
    );
  }

  Future<void> clearDramaHistory() {
    return PangolinContentSdkPlatform.instance.clearDramaHistory();
  }

  Future<PangolinDramaLock> verifyDramaParams({
    required int total,
    required int freeSet,
    required int lockSet,
  }) {
    return PangolinContentSdkPlatform.instance.verifyDramaParams(
      total: total,
      freeSet: freeSet,
      lockSet: lockSet,
    );
  }

  Future<void> openDramaDetail({
    required int dramaId,
    PangolinDramaDetailOptions options = const PangolinDramaDetailOptions(),
  }) {
    return PangolinContentSdkPlatform.instance.openDramaDetail(
      dramaId: dramaId,
      options: options,
    );
  }

  Future<void> openDramaDrawFeed({
    PangolinDramaDrawOptions options = const PangolinDramaDrawOptions(),
  }) {
    return PangolinContentSdkPlatform.instance.openDramaDrawFeed(
      options: options,
    );
  }
}
