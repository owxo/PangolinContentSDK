/// Configuration used to initialize Pangolin ad SDK and Pangolin Content SDK.
class PangolinContentConfig {
  const PangolinContentConfig({
    required this.configFileName,
    this.configFilePath,
    this.appId = '',
    this.adAppId,
    this.appName = 'pangolin_content_sdk',
    this.debug = false,
    this.initializeAdSdk = true,
    this.startAdSdk = true,
    this.newUser = true,
    this.teenagerMode = false,
    this.autoLoginOnRequest = true,
    this.supportMultiProcess = true,
    this.allowShowNotify = true,
    this.useTextureView = false,
    this.useSdkInnerFoldDeviceMethod = true,
    this.enableFoldableScreenAdaptation = true,
    this.isFoldDeviceFromOuter = false,
    this.disableVerifier = true,
    this.disableTTPlayer = false,
  });

  /// Pangolin media app id.
  ///
  /// If empty on Android, the plugin tries to read
  /// `com.owxo.pangolin_content_sdk.PANGLE_APP_ID` from manifest metadata.
  final String appId;

  /// Pangolin ad/media id passed to `TTAdConfig.appId`.
  ///
  /// Content SDK setting JSON commonly contains both `site_id` and AppLog
  /// `app_id`; use `site_id` here when it differs from [appId].
  final String? adAppId;

  /// SDK setting JSON file name.
  ///
  /// Android reads it from app assets. iOS reads it from the main bundle.
  final String configFileName;

  /// Runtime downloaded SDK setting JSON file path.
  ///
  /// Android keeps [configFileName] as the SDK-facing config name and uses this
  /// path to preload the dynamic SDK settings before startup.
  final String? configFilePath;

  /// App name passed to Pangolin ad SDK.
  final String appName;

  final bool debug;
  final bool initializeAdSdk;
  final bool startAdSdk;
  final bool newUser;
  final bool teenagerMode;
  final bool autoLoginOnRequest;
  final bool supportMultiProcess;
  final bool allowShowNotify;
  final bool useTextureView;
  final bool useSdkInnerFoldDeviceMethod;
  final bool enableFoldableScreenAdaptation;
  final bool isFoldDeviceFromOuter;
  final bool disableVerifier;

  /// Disables Pangolin's TTPlayer runtime.
  ///
  /// Keep this disabled for normal playback. Set it to true only when you need
  /// to isolate initialization issues on a problematic device.
  final bool disableTTPlayer;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'appId': appId,
      'adAppId': adAppId,
      'configFileName': configFileName,
      'configFilePath': configFilePath,
      'appName': appName,
      'debug': debug,
      'initializeAdSdk': initializeAdSdk,
      'startAdSdk': startAdSdk,
      'newUser': newUser,
      'teenagerMode': teenagerMode,
      'autoLoginOnRequest': autoLoginOnRequest,
      'supportMultiProcess': supportMultiProcess,
      'allowShowNotify': allowShowNotify,
      'useTextureView': useTextureView,
      'useSdkInnerFoldDeviceMethod': useSdkInnerFoldDeviceMethod,
      'enableFoldableScreenAdaptation': enableFoldableScreenAdaptation,
      'isFoldDeviceFromOuter': isFoldDeviceFromOuter,
      'disableVerifier': disableVerifier,
      'disableTTPlayer': disableTTPlayer,
    };
  }
}

class PangolinSdkStartResult {
  const PangolinSdkStartResult({
    required this.success,
    this.message,
    this.code,
  });

  factory PangolinSdkStartResult.fromMap(Map<Object?, Object?> map) {
    return PangolinSdkStartResult(
      success: map['success'] == true,
      message: map['message'] as String?,
      code: _asInt(map['code']),
    );
  }

  final bool success;
  final String? message;
  final int? code;
}

class PangolinNetworkCheckResult {
  const PangolinNetworkCheckResult({
    required this.host,
    required this.port,
    required this.reachable,
    this.elapsedMs,
    this.message,
  });

  factory PangolinNetworkCheckResult.fromMap(Map<Object?, Object?> map) {
    return PangolinNetworkCheckResult(
      host: map['host'] as String? ?? '',
      port: _asInt(map['port']) ?? 443,
      reachable: map['reachable'] == true,
      elapsedMs: _asInt(map['elapsedMs']),
      message: map['message'] as String?,
    );
  }

  final String host;
  final int port;
  final bool reachable;
  final int? elapsedMs;
  final String? message;
}

typedef PangolinRewardAdHandler =
    Future<PangolinRewardAdResult> Function(PangolinRewardAdRequest request);

class PangolinRewardAdRequest {
  const PangolinRewardAdRequest({
    required this.scene,
    required this.dramaId,
    this.index,
    this.extra = const <String, Object?>{},
  });

  factory PangolinRewardAdRequest.fromMap(Map<Object?, Object?> map) {
    return PangolinRewardAdRequest(
      scene: _asString(map['scene']) ?? '',
      dramaId: _asInt(map['dramaId']) ?? 0,
      index: _asInt(map['index']),
      extra: _objectMap(map['extra']),
    );
  }

  final String scene;
  final int dramaId;
  final int? index;
  final Map<String, Object?> extra;
}

class PangolinRewardAdResult {
  const PangolinRewardAdResult({
    required this.rewarded,
    this.shown = true,
    this.ecpm,
    this.errorMessage,
    this.extra = const <String, Object?>{},
  });

  const PangolinRewardAdResult.rewarded({
    this.ecpm,
    this.extra = const <String, Object?>{},
  }) : rewarded = true,
       shown = true,
       errorMessage = null;

  const PangolinRewardAdResult.notRewarded({
    this.ecpm,
    this.errorMessage,
    this.extra = const <String, Object?>{},
  }) : rewarded = false,
       shown = true;

  const PangolinRewardAdResult.unavailable({
    this.errorMessage,
    this.extra = const <String, Object?>{},
  }) : rewarded = false,
       shown = false,
       ecpm = null;

  final bool rewarded;
  final bool shown;
  final String? ecpm;
  final String? errorMessage;
  final Map<String, Object?> extra;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'rewarded': rewarded,
      'shown': shown,
      'ecpm': ecpm,
      'errorMessage': errorMessage,
      'extra': extra,
    };
  }
}

class PangolinLoginSign {
  const PangolinLoginSign({
    required this.sign,
    required this.nonce,
    required this.timestampSeconds,
    required this.params,
  });

  factory PangolinLoginSign.fromMap(Map<Object?, Object?> map) {
    return PangolinLoginSign(
      sign: _asString(map['sign']) ?? '',
      nonce: _asString(map['nonce']) ?? '',
      timestampSeconds: _asInt(map['timestampSeconds']) ?? 0,
      params: _stringMap(map['params']),
    );
  }

  final String sign;
  final String nonce;
  final int timestampSeconds;
  final Map<String, String> params;
}

class PangolinUser {
  const PangolinUser({this.uid, this.raw = const <String, Object?>{}});

  factory PangolinUser.fromMap(Map<Object?, Object?> map) {
    final raw = <String, Object?>{
      for (final entry in map.entries) entry.key.toString(): entry.value,
    };
    return PangolinUser(
      uid: _firstString(raw, const <String>[
        'uid',
        'ouid',
        'userId',
        'user_id',
        'id',
      ]),
      raw: raw,
    );
  }

  final String? uid;
  final Map<String, Object?> raw;
}

class PangolinDrama {
  const PangolinDrama({
    required this.id,
    this.index = 1,
    this.title,
    this.total,
    this.coverUrl,
    this.category,
    this.description,
    this.raw = const <String, Object?>{},
  });

  factory PangolinDrama.fromMap(Map<Object?, Object?> map) {
    final raw = <String, Object?>{
      for (final entry in map.entries) entry.key.toString(): entry.value,
    };

    return PangolinDrama(
      id: _asInt(raw['id']) ?? 0,
      index: _asInt(raw['index']) ?? 1,
      title: _asString(raw['title']),
      total: _asInt(raw['total']),
      coverUrl: _firstImageUrl(raw, const <String>[
        'coverUrl',
        'cover_url',
        'coverImage',
        'cover_image',
        'cover',
        'poster',
        'posterUrl',
        'poster_url',
        'image',
        'imageUrl',
        'image_url',
        'thumb',
        'thumbUrl',
        'thumb_url',
      ]),
      category: _firstString(raw, const <String>[
        'category',
        'categoryName',
        'type',
      ]),
      description: _firstString(raw, const <String>[
        'description',
        'desc',
        'intro',
        'summary',
      ]),
      raw: raw,
    );
  }

  final int id;
  final int index;
  final String? title;
  final int? total;
  final String? coverUrl;
  final String? category;
  final String? description;
  final Map<String, Object?> raw;
}

class PangolinDramaDetailOptions {
  const PangolinDramaDetailOptions({
    this.index = 1,
    this.freeSet = 5,
    this.lockSet = 2,
    this.playDurationSeconds = 0,
    this.fromGid,
    this.enterFrom = PangolinDramaEnterFrom.defaultSource,
    this.recMap = const <String, Object?>{},
    this.unlockAdMode,
    this.enableInfiniteScroll = true,
    this.enableContinuousUnlock = false,
    this.hideBack = false,
    this.hideTopInfo = false,
    this.hideBottomInfo = false,
    this.hideLikeButton = false,
    this.hideFavorButton = false,
    this.hideMore = false,
    this.hideRewardDialog = false,
    this.hideCellularToast = false,
    this.hideDoubleClick = false,
    this.hideLongClickSpeed = false,
    this.bottomOffset,
    this.topOffset,
    this.scriptTipsTopMargin,
    this.icpTipsBottomMargin,
    this.useCustomRewardAd = false,
  });

  final int index;
  final int freeSet;
  final int lockSet;
  final int playDurationSeconds;
  final int? fromGid;
  final PangolinDramaEnterFrom enterFrom;
  final Map<String, Object?> recMap;
  final PangolinDramaUnlockAdMode? unlockAdMode;
  final bool enableInfiniteScroll;
  final bool enableContinuousUnlock;
  final bool hideBack;
  final bool hideTopInfo;
  final bool hideBottomInfo;
  final bool hideLikeButton;
  final bool hideFavorButton;
  final bool hideMore;
  final bool hideRewardDialog;
  final bool hideCellularToast;
  final bool hideDoubleClick;
  final bool hideLongClickSpeed;
  final int? bottomOffset;
  final int? topOffset;
  final int? scriptTipsTopMargin;
  final int? icpTipsBottomMargin;
  final bool useCustomRewardAd;

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'index': index,
      'freeSet': freeSet,
      'lockSet': lockSet,
      'playDurationSeconds': playDurationSeconds,
      'fromGid': fromGid,
      'enterFrom': enterFrom._value,
      'recMap': recMap,
      'unlockAdMode': unlockAdMode?._value,
      'enableInfiniteScroll': enableInfiniteScroll,
      'enableContinuousUnlock': enableContinuousUnlock,
      'hideBack': hideBack,
      'hideTopInfo': hideTopInfo,
      'hideBottomInfo': hideBottomInfo,
      'hideLikeButton': hideLikeButton,
      'hideFavorButton': hideFavorButton,
      'hideMore': hideMore,
      'hideRewardDialog': hideRewardDialog,
      'hideCellularToast': hideCellularToast,
      'hideDoubleClick': hideDoubleClick,
      'hideLongClickSpeed': hideLongClickSpeed,
      'useCustomRewardAd': useCustomRewardAd,
    };
    void addIfPresent(String key, Object? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    addIfPresent('bottomOffset', bottomOffset);
    addIfPresent('topOffset', topOffset);
    addIfPresent('scriptTipsTopMargin', scriptTipsTopMargin);
    addIfPresent('icpTipsBottomMargin', icpTipsBottomMargin);
    return map;
  }
}

enum PangolinDramaUnlockAdMode { common, specific }

enum PangolinDramaEnterFrom {
  defaultSource,
  skitMixed,
  dramaHomeRecentlyWatched,
  dramaHome,
  dramaHistory,
  dramaCard,
}

enum PangolinDramaDrawChannelType { recommend, theater, recommendTheater }

enum PangolinDramaDrawContentType { onlyDrama }

enum PangolinDramaDrawProgressBarStyle { light, dark }

class PangolinDramaDrawOptions {
  const PangolinDramaDrawOptions({
    this.channelType = PangolinDramaDrawChannelType.recommend,
    this.contentType = PangolinDramaDrawContentType.onlyDrama,
    this.hideChannelName,
    this.hideLikeButton = false,
    this.hideFavorButton = false,
    this.hideDramaInfo = false,
    this.hideDramaEnter = false,
    this.hideClose = false,
    this.hideDoubleClickLike = false,
    this.hideLongClickSpeed = false,
    this.enableRefresh,
    this.showGuide,
    this.progressBarStyle,
    this.adCodeId,
    this.nativeAdCodeId,
    this.customCategory,
    this.adOffset = 0,
    this.bottomOffset,
    this.reportTopPadding,
    this.titleLeftMargin,
    this.titleRightMargin,
    this.titleTopMargin,
    this.dramaFree = 5,
    this.detailFreeSet = 5,
    this.detailLockSet = -1,
    this.detailHideBack = false,
    this.detailHideTopInfo = false,
    this.detailHideBottomInfo = false,
    this.detailHideRewardDialog = false,
    this.detailHideMore = false,
    this.detailHideCellularToast = false,
    this.detailInfiniteScrollEnabled = true,
    this.detailHideLikeButton = false,
    this.detailHideFavorButton = false,
    this.detailHideDoubleClick = false,
    this.detailHideLongClickSpeed = false,
    this.detailBottomOffset,
    this.detailTopOffset,
    this.detailScriptTipsTopMargin,
    this.detailIcpTipsBottomMargin,
    this.topDramaId,
    this.enableContinuousUnlock = false,
    this.detailUseCustomRewardAd = false,
    this.backRefreshEnabled = true,
    this.backRefreshIntervalMillis = 3000,
    this.finishOnBlockedBack = false,
  });

  final PangolinDramaDrawChannelType channelType;
  final PangolinDramaDrawContentType contentType;

  /// When null, Android uses Pangolin's common default: hide channel name for
  /// the recommend channel and show it for theater-style channels.
  final bool? hideChannelName;

  final bool hideLikeButton;
  final bool hideFavorButton;
  final bool hideDramaInfo;
  final bool hideDramaEnter;
  final bool hideClose;
  final bool hideDoubleClickLike;
  final bool hideLongClickSpeed;
  final bool? enableRefresh;
  final bool? showGuide;
  final PangolinDramaDrawProgressBarStyle? progressBarStyle;
  final String? adCodeId;
  final String? nativeAdCodeId;
  final String? customCategory;
  final int adOffset;
  final int? bottomOffset;
  final int? reportTopPadding;
  final int? titleLeftMargin;
  final int? titleRightMargin;
  final int? titleTopMargin;
  final int dramaFree;
  final int detailFreeSet;
  final int detailLockSet;
  final bool detailHideBack;
  final bool detailHideTopInfo;
  final bool detailHideBottomInfo;
  final bool detailHideRewardDialog;
  final bool detailHideMore;
  final bool detailHideCellularToast;
  final bool detailInfiniteScrollEnabled;
  final bool detailHideLikeButton;
  final bool detailHideFavorButton;
  final bool detailHideDoubleClick;
  final bool detailHideLongClickSpeed;
  final int? detailBottomOffset;
  final int? detailTopOffset;
  final int? detailScriptTipsTopMargin;
  final int? detailIcpTipsBottomMargin;
  final int? topDramaId;
  final bool enableContinuousUnlock;
  final bool detailUseCustomRewardAd;
  final bool backRefreshEnabled;
  final int backRefreshIntervalMillis;
  final bool finishOnBlockedBack;

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'channelType': channelType._channelValue,
      'contentType': contentType._contentValue,
      'hideLikeButton': hideLikeButton,
      'hideFavorButton': hideFavorButton,
      'hideDramaInfo': hideDramaInfo,
      'hideDramaEnter': hideDramaEnter,
      'hideClose': hideClose,
      'hideDoubleClickLike': hideDoubleClickLike,
      'hideLongClickSpeed': hideLongClickSpeed,
      'adOffset': adOffset,
      'dramaFree': dramaFree,
      'detailFreeSet': detailFreeSet,
      'detailLockSet': detailLockSet,
      'detailHideBack': detailHideBack,
      'detailHideTopInfo': detailHideTopInfo,
      'detailHideBottomInfo': detailHideBottomInfo,
      'detailHideRewardDialog': detailHideRewardDialog,
      'detailHideMore': detailHideMore,
      'detailHideCellularToast': detailHideCellularToast,
      'detailInfiniteScrollEnabled': detailInfiniteScrollEnabled,
      'detailHideLikeButton': detailHideLikeButton,
      'detailHideFavorButton': detailHideFavorButton,
      'detailHideDoubleClick': detailHideDoubleClick,
      'detailHideLongClickSpeed': detailHideLongClickSpeed,
      'enableContinuousUnlock': enableContinuousUnlock,
      'detailUseCustomRewardAd': detailUseCustomRewardAd,
      'backRefreshEnabled': backRefreshEnabled,
      'backRefreshIntervalMillis': backRefreshIntervalMillis,
      'finishOnBlockedBack': finishOnBlockedBack,
    };
    void addIfPresent(String key, Object? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    addIfPresent('hideChannelName', hideChannelName);
    addIfPresent('enableRefresh', enableRefresh);
    addIfPresent('showGuide', showGuide);
    addIfPresent('progressBarStyle', progressBarStyle?._styleValue);
    addIfPresent('adCodeId', adCodeId);
    addIfPresent('nativeAdCodeId', nativeAdCodeId);
    addIfPresent('customCategory', customCategory);
    addIfPresent('bottomOffset', bottomOffset);
    addIfPresent('reportTopPadding', reportTopPadding);
    addIfPresent('titleLeftMargin', titleLeftMargin);
    addIfPresent('titleRightMargin', titleRightMargin);
    addIfPresent('titleTopMargin', titleTopMargin);
    addIfPresent('detailBottomOffset', detailBottomOffset);
    addIfPresent('detailTopOffset', detailTopOffset);
    addIfPresent('detailScriptTipsTopMargin', detailScriptTipsTopMargin);
    addIfPresent('detailIcpTipsBottomMargin', detailIcpTipsBottomMargin);
    addIfPresent('topDramaId', topDramaId);
    return map;
  }
}

extension on PangolinDramaDrawChannelType {
  String get _channelValue {
    return switch (this) {
      PangolinDramaDrawChannelType.recommend => 'recommend',
      PangolinDramaDrawChannelType.theater => 'theater',
      PangolinDramaDrawChannelType.recommendTheater => 'recommendTheater',
    };
  }
}

extension on PangolinDramaUnlockAdMode {
  String get _value {
    return switch (this) {
      PangolinDramaUnlockAdMode.common => 'common',
      PangolinDramaUnlockAdMode.specific => 'specific',
    };
  }
}

extension on PangolinDramaEnterFrom {
  String get _value {
    return switch (this) {
      PangolinDramaEnterFrom.defaultSource => 'default',
      PangolinDramaEnterFrom.skitMixed => 'skitMixed',
      PangolinDramaEnterFrom.dramaHomeRecentlyWatched =>
        'dramaHomeRecentlyWatched',
      PangolinDramaEnterFrom.dramaHome => 'dramaHome',
      PangolinDramaEnterFrom.dramaHistory => 'dramaHistory',
      PangolinDramaEnterFrom.dramaCard => 'dramaCard',
    };
  }
}

extension on PangolinDramaDrawContentType {
  String get _contentValue {
    return switch (this) {
      PangolinDramaDrawContentType.onlyDrama => 'onlyDrama',
    };
  }
}

extension on PangolinDramaDrawProgressBarStyle {
  String get _styleValue {
    return switch (this) {
      PangolinDramaDrawProgressBarStyle.light => 'light',
      PangolinDramaDrawProgressBarStyle.dark => 'dark',
    };
  }
}

class PangolinDramaLock {
  const PangolinDramaLock({this.freeSet, this.lockSet, this.raw});

  factory PangolinDramaLock.fromMap(Map<Object?, Object?> map) {
    return PangolinDramaLock(
      freeSet: _asInt(map['freeSet']),
      lockSet: _asInt(map['lockSet']),
      raw: map['raw']?.toString(),
    );
  }

  final int? freeSet;
  final int? lockSet;
  final String? raw;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

String? _asString(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) {
    return const <String, Object?>{};
  }
  return <String, Object?>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }
  return <String, String>{
    for (final entry in value.entries)
      if (entry.value != null) entry.key.toString(): entry.value.toString(),
  };
}

String? _firstString(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = _asString(map[key]);
    if (value != null) {
      return value;
    }
  }
  return null;
}

String? _firstImageUrl(Map<String, Object?> map, List<String> keys) {
  final value = _firstString(map, keys)?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  if (value.startsWith('//')) {
    return 'https:$value';
  }
  return value;
}
