import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pangolin_content_sdk_method_channel.dart';
import 'src/pangolin_content_models.dart';

abstract class PangolinContentSdkPlatform extends PlatformInterface {
  PangolinContentSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static PangolinContentSdkPlatform _instance =
      MethodChannelPangolinContentSdk();

  static PangolinContentSdkPlatform get instance => _instance;

  static set instance(PangolinContentSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<PangolinSdkStartResult> initialize(PangolinContentConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<bool> isStarted() {
    throw UnimplementedError('isStarted() has not been implemented.');
  }

  Future<Map<String, bool>> requestRecommendedPermissions() {
    throw UnimplementedError(
      'requestRecommendedPermissions() has not been implemented.',
    );
  }

  Future<List<PangolinNetworkCheckResult>> checkNetworkAccess({
    required List<String> hosts,
    required int port,
    required int timeoutMillis,
  }) {
    throw UnimplementedError('checkNetworkAccess() has not been implemented.');
  }

  Future<void> setTeenagerMode(bool enabled) {
    throw UnimplementedError('setTeenagerMode() has not been implemented.');
  }

  Future<void> setRewardAdHandler(PangolinRewardAdHandler? handler) {
    throw UnimplementedError('setRewardAdHandler() has not been implemented.');
  }

  Future<PangolinLoginSign> getLoginSignString({
    required String serverKey,
    required String uid,
    String? nonce,
    int? timestampSeconds,
    Map<String, String> params = const <String, String>{},
  }) {
    throw UnimplementedError('getLoginSignString() has not been implemented.');
  }

  Future<PangolinUser?> loginWithSign(String sign) {
    throw UnimplementedError('loginWithSign() has not been implemented.');
  }

  Future<PangolinUser?> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  Future<bool> isLoggedIn() {
    throw UnimplementedError('isLoggedIn() has not been implemented.');
  }

  Future<List<PangolinDrama>> requestAllDramas({
    required int page,
    required int pageSize,
    required bool orderByHot,
  }) {
    throw UnimplementedError('requestAllDramas() has not been implemented.');
  }

  Future<List<PangolinDrama>> requestRecommendedDramas({
    required int page,
    required int pageSize,
  }) {
    throw UnimplementedError(
      'requestRecommendedDramas() has not been implemented.',
    );
  }

  Future<List<PangolinDrama>> requestDramasByIds(List<int> ids) {
    throw UnimplementedError('requestDramasByIds() has not been implemented.');
  }

  Future<List<PangolinDrama>> requestDramasByCategory(
    String category, {
    required int page,
    required int pageSize,
    required int order,
  }) {
    throw UnimplementedError(
      'requestDramasByCategory() has not been implemented.',
    );
  }

  Future<List<PangolinDrama>> searchDramas(
    String query, {
    required bool fuzzy,
    required int page,
    required int pageSize,
  }) {
    throw UnimplementedError('searchDramas() has not been implemented.');
  }

  Future<List<String>> requestDramaCategories() {
    throw UnimplementedError(
      'requestDramaCategories() has not been implemented.',
    );
  }

  Future<List<PangolinDrama>> getDramaHistory({
    required int offset,
    required int count,
  }) {
    throw UnimplementedError('getDramaHistory() has not been implemented.');
  }

  Future<List<PangolinDrama>> getFavorList({
    required int offset,
    required int count,
  }) {
    throw UnimplementedError('getFavorList() has not been implemented.');
  }

  Future<void> clearDramaHistory() {
    throw UnimplementedError('clearDramaHistory() has not been implemented.');
  }

  Future<PangolinDramaLock> verifyDramaParams({
    required int total,
    required int freeSet,
    required int lockSet,
  }) {
    throw UnimplementedError('verifyDramaParams() has not been implemented.');
  }

  Future<void> openDramaDetail({
    required int dramaId,
    required PangolinDramaDetailOptions options,
  }) {
    throw UnimplementedError('openDramaDetail() has not been implemented.');
  }

  Future<void> openDramaDrawFeed({required PangolinDramaDrawOptions options}) {
    throw UnimplementedError('openDramaDrawFeed() has not been implemented.');
  }

  Future<void> pauseEmbeddedDramaDrawFeed() {
    throw UnimplementedError(
      'pauseEmbeddedDramaDrawFeed() has not been implemented.',
    );
  }

  Future<void> resumeEmbeddedDramaDrawFeed() {
    throw UnimplementedError(
      'resumeEmbeddedDramaDrawFeed() has not been implemented.',
    );
  }
}
