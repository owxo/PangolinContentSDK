import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pangolin_content_sdk_platform_interface.dart';
import 'src/pangolin_content_models.dart';

/// MethodChannel implementation for Android.
class MethodChannelPangolinContentSdk extends PangolinContentSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('pangolin_content_sdk');

  PangolinRewardAdHandler? _rewardAdHandler;
  bool _nativeMethodHandlerRegistered = false;

  @override
  Future<PangolinSdkStartResult> initialize(
    PangolinContentConfig config,
  ) async {
    final result = await methodChannel.invokeMapMethod<Object?, Object?>(
      'initialize',
      config.toMap(),
    );
    return PangolinSdkStartResult.fromMap(result ?? <Object?, Object?>{});
  }

  @override
  Future<bool> isStarted() async {
    return await methodChannel.invokeMethod<bool>('isStarted') ?? false;
  }

  @override
  Future<Map<String, bool>> requestRecommendedPermissions() async {
    final map = await methodChannel.invokeMapMethod<String, bool>(
      'requestRecommendedPermissions',
    );
    return map ?? const <String, bool>{};
  }

  @override
  Future<List<PangolinNetworkCheckResult>> checkNetworkAccess({
    required List<String> hosts,
    required int port,
    required int timeoutMillis,
  }) async {
    final list = await methodChannel.invokeListMethod<Object?>(
      'checkNetworkAccess',
      <String, Object?>{
        'hosts': hosts,
        'port': port,
        'timeoutMillis': timeoutMillis,
      },
    );
    return (list ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(PangolinNetworkCheckResult.fromMap)
        .toList();
  }

  @override
  Future<void> setTeenagerMode(bool enabled) {
    return methodChannel.invokeMethod<void>('setTeenagerMode', enabled);
  }

  @override
  Future<void> setRewardAdHandler(PangolinRewardAdHandler? handler) async {
    _ensureNativeMethodHandlerRegistered();
    _rewardAdHandler = handler;
  }

  @override
  Future<PangolinLoginSign> getLoginSignString({
    required String serverKey,
    required String uid,
    String? nonce,
    int? timestampSeconds,
    Map<String, String> params = const <String, String>{},
  }) async {
    final map = await methodChannel.invokeMapMethod<Object?, Object?>(
      'getLoginSignString',
      <String, Object?>{
        'serverKey': serverKey,
        'uid': uid,
        'nonce': nonce,
        'timestampSeconds': timestampSeconds,
        'params': params,
      },
    );
    return PangolinLoginSign.fromMap(map ?? <Object?, Object?>{});
  }

  @override
  Future<PangolinUser?> loginWithSign(String sign) async {
    final map = await methodChannel.invokeMapMethod<Object?, Object?>(
      'login',
      <String, Object?>{'sign': sign},
    );
    if (map == null) {
      return null;
    }
    return PangolinUser.fromMap(map);
  }

  @override
  Future<PangolinUser?> logout() async {
    final map = await methodChannel.invokeMapMethod<Object?, Object?>('logout');
    if (map == null) {
      return null;
    }
    return PangolinUser.fromMap(map);
  }

  @override
  Future<bool> isLoggedIn() async {
    return await methodChannel.invokeMethod<bool>('isLogin') ?? false;
  }

  @override
  Future<List<PangolinDrama>> requestAllDramas({
    required int page,
    required int pageSize,
    required bool orderByHot,
  }) {
    return _requestDramaList('requestAllDramas', <String, Object?>{
      'page': page,
      'pageSize': pageSize,
      'orderByHot': orderByHot,
    });
  }

  @override
  Future<List<PangolinDrama>> requestRecommendedDramas({
    required int page,
    required int pageSize,
  }) {
    return _requestDramaList('requestRecommendedDramas', <String, Object?>{
      'page': page,
      'pageSize': pageSize,
    });
  }

  @override
  Future<List<PangolinDrama>> requestDramasByIds(List<int> ids) {
    return _requestDramaList('requestDramasByIds', <String, Object?>{
      'ids': ids,
    });
  }

  @override
  Future<List<PangolinDrama>> requestDramasByCategory(
    String category, {
    required int page,
    required int pageSize,
    required int order,
  }) {
    return _requestDramaList('requestDramasByCategory', <String, Object?>{
      'category': category,
      'page': page,
      'pageSize': pageSize,
      'order': order,
    });
  }

  @override
  Future<List<PangolinDrama>> searchDramas(
    String query, {
    required bool fuzzy,
    required int page,
    required int pageSize,
  }) {
    return _requestDramaList('searchDramas', <String, Object?>{
      'query': query,
      'fuzzy': fuzzy,
      'page': page,
      'pageSize': pageSize,
    });
  }

  @override
  Future<List<String>> requestDramaCategories() async {
    final categories = await methodChannel.invokeListMethod<String>(
      'requestDramaCategories',
    );
    return categories ?? const <String>[];
  }

  @override
  Future<List<PangolinDrama>> getDramaHistory({
    required int offset,
    required int count,
  }) {
    return _requestDramaList('getDramaHistory', <String, Object?>{
      'offset': offset,
      'count': count,
    });
  }

  @override
  Future<List<PangolinDrama>> getFavorList({
    required int offset,
    required int count,
  }) {
    return _requestDramaList('getFavorList', <String, Object?>{
      'offset': offset,
      'count': count,
    });
  }

  @override
  Future<void> clearDramaHistory() {
    return methodChannel.invokeMethod<void>('clearDramaHistory');
  }

  @override
  Future<PangolinDramaLock> verifyDramaParams({
    required int total,
    required int freeSet,
    required int lockSet,
  }) async {
    final map = await methodChannel.invokeMapMethod<Object?, Object?>(
      'verifyDramaParams',
      <String, Object?>{'total': total, 'freeSet': freeSet, 'lockSet': lockSet},
    );
    return PangolinDramaLock.fromMap(map ?? <Object?, Object?>{});
  }

  @override
  Future<void> openDramaDetail({
    required int dramaId,
    required PangolinDramaDetailOptions options,
  }) {
    return methodChannel.invokeMethod<void>(
      'openDramaDetail',
      <String, Object?>{'dramaId': dramaId, 'options': options.toMap()},
    );
  }

  @override
  Future<void> openDramaDrawFeed({required PangolinDramaDrawOptions options}) {
    return methodChannel.invokeMethod<void>(
      'openDramaDrawFeed',
      <String, Object?>{'options': options.toMap()},
    );
  }

  Future<List<PangolinDrama>> _requestDramaList(
    String method,
    Map<String, Object?> arguments,
  ) async {
    final list = await methodChannel.invokeListMethod<Object?>(
      method,
      arguments,
    );
    return (list ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(PangolinDrama.fromMap)
        .toList(growable: false);
  }

  Future<Object?> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onRewardAdRequested':
        final handler = _rewardAdHandler;
        if (handler == null) {
          return const PangolinRewardAdResult.unavailable(
            errorMessage: 'No reward ad handler registered.',
          ).toMap();
        }
        try {
          final arguments =
              call.arguments as Map<Object?, Object?>? ?? <Object?, Object?>{};
          final result = await handler(
            PangolinRewardAdRequest.fromMap(arguments),
          );
          return result.toMap();
        } catch (error) {
          return PangolinRewardAdResult.unavailable(
            errorMessage: error.toString(),
          ).toMap();
        }
      default:
        throw PlatformException(
          code: 'pangolin_not_implemented',
          message: 'Unknown native method ${call.method}.',
        );
    }
  }

  void _ensureNativeMethodHandlerRegistered() {
    if (_nativeMethodHandlerRegistered) {
      return;
    }
    methodChannel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeMethodHandlerRegistered = true;
  }
}
