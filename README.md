# pangolin_content_sdk

这是一个给 Flutter 使用的穿山甲内容 SDK 封装插件，当前支持 Android 和 iOS 短剧能力。

这个插件适合这种场景：你的 Flutter App 自己做短剧首页、列表、分类、搜索等页面，但内容请求、短剧播放页、溜溜滑页面交给穿山甲原生 SDK 来处理。

## Commercial Support / 商业支持

This repository remains open-source. Paid support is available for narrowly scoped Flutter-to-native integration, MethodChannel/PlatformView, Gradle/CocoaPods, and Android/iOS SDK problems.

本仓库保持开源，同时提供边界明确的 Flutter 原生双端集成、MethodChannel/PlatformView、Gradle/CocoaPods 与 Android/iOS SDK 问题付费支持。

See [COMMERCIAL_SUPPORT.md](./COMMERCIAL_SUPPORT.md) for scope, transparent pricing, required materials, and safety boundaries.

服务范围、透明价格、所需材料和安全边界见 [COMMERCIAL_SUPPORT.md](./COMMERCIAL_SUPPORT.md)。

## 当前支持范围

- 支持 Android 和 iOS。
- 初始化穿山甲广告 SDK 和穿山甲内容 SDK。
- 支持请求短剧列表、推荐短剧、分类、搜索结果、观看历史、收藏。
- 支持从 Flutter 打开穿山甲原生短剧播放页。
- 支持从 Flutter 打开穿山甲原生溜溜滑/滑滑流页面。
- 支持内嵌溜溜滑/滑滑流原生视图。
- 支持第三方激励广告接入短剧解锁流程。
- 支持穿山甲解锁记录绑定登录接口。
- 提供一个 Flutter 示例 App，里面有 Flutter 写的短剧列表页面。

暂时还不包含：短故事、短视频、pub.dev 自动发布流程。

## 平台要求

- Android `minSdk` 21 或以上。
- AndroidX 需要开启。
- 如果你的项目还依赖旧版 support 库，需要开启 Jetifier。
- 建议使用真实 Android 手机测试。穿山甲内容 SDK demo 官方也说明不支持只用模拟器完整验证。
- iOS 最低支持 `iOS 12.0`。
- iOS 建议使用真机测试，模拟器可能无法完整验证播放、广告和部分设备权限链路。

## Android 接入

在你的 Android 项目里加入穿山甲 Maven 仓库：

```kotlin
allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google/") }
        maven { url = uri("https://maven.aliyun.com/repository/public/") }
        google()
        mavenCentral()
        maven { url = uri("https://artifact.bytedance.com/repository/Volcengine/") }
        maven { url = uri("https://artifact.bytedance.com/repository/pangle/") }
    }
}
```

如果穿山甲后台给你的应用生成了不同版本的 Maven 依赖，可以在 `android/gradle.properties` 里覆盖：

```properties
pangolinAdSdk=com.pangle.cn:mediation-sdk:5.9.0.8
pangolinDramaSdk=com.pangle.cn:pangrowth-djx-sdk-lite:2.9.0.9
pangolinBaseSdk=com.pangle.cn:pangrowth-base:2.9.0.9
```

把穿山甲后台下载的 SDK 配置 JSON 放到你的 App assets 目录，例如：

```text
android/app/src/main/assets/SDK_Setting_xxx.json
```

在 App 模块里配置 AppLog 的 URL Scheme：

```kotlin
android {
    defaultConfig {
        manifestPlaceholders["APPLOG_SCHEME"] = "rangersapplog.your_scheme"
    }
}
```

并且在启动 Activity 上注册同一个 Scheme：

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="${APPLOG_SCHEME}" />
</intent-filter>
```

如果你需要和官方 demo 的网络配置完全一致，可以在 App 的 manifest 里增加 `networkSecurityConfig`，并允许你的 SDK 配置文件里使用到的穿山甲/AppLog 域名。

## iOS 接入

iOS 需要在你的 App 的 `ios/Podfile` 顶部加入穿山甲和火山引擎 CocoaPods 源：

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/volcengine/volcengine-specs.git'
```

在 `target 'Runner' do` 里建议使用静态 framework：

```ruby
use_frameworks! :linkage => :static
```

插件的 podspec 已经声明了下面这些依赖，正常情况下宿主项目不用重复写：

```ruby
pod 'Ads-CN-Beta', '7.2.0.6', :subspecs => ['BUAdSDK', 'CSJMediation-Only', 'BUAdLive']
pod 'TTSDKFramework', '1.46.2.7-premium', :subspecs => ['LivePull', 'Player-SR']
pod 'PangrowthX', '2.9.0.5', :subspecs => ['shortplay-beta']
```

如果你的项目里已经手动接入过这些 Pod，请保持版本一致，避免出现重复依赖或符号冲突。

把穿山甲后台下载的 iOS SDK 配置 JSON 放到你的 App 工程，例如：

```text
ios/Runner/SDK_Setting_xxx.json
```

然后在 Xcode 里确认这个 JSON 已加入 `Runner` target 的 `Copy Bundle Resources`。如果没有加入，iOS 初始化会提示找不到配置文件。

在 `ios/Runner/Info.plist` 里配置 AppLog URL Scheme：

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>rangersapplog.your_scheme</string>
    </array>
  </dict>
</array>
```

如果要请求 IDFA/ATT 权限，还需要：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>用于广告归因和内容推荐优化</string>
```

请确认 iOS App 的 Bundle ID 和 SDK 配置 JSON 里的 `license_config.BundleId` 一致。例如你的 Bundle ID 是 `com.example.app`，JSON 里也必须包含同一个 Bundle ID，否则内容 SDK 会提示配置异常。

安装 iOS Pods：

```sh
cd ios
pod install
```

如果 CocoaPods 提示找不到 `PangrowthX`、`Ads-CN-Beta` 或 `TTSDKFramework`，先确认 `Podfile` 顶部已经加入 `https://github.com/volcengine/volcengine-specs.git`。

## Flutter 使用

基础用法：

```dart
final sdk = PangolinContentSdk.instance;

await sdk.requestRecommendedPermissions();
final networkChecks = await sdk.checkNetworkAccess();

final result = await sdk.initialize(
  const PangolinContentConfig(
    appId: 'your_applog_app_id',
    adAppId: 'your_pangolin_site_id',
    configFileName: 'SDK_Setting_xxx.json',
    appName: 'your_app_name',
    debug: true,
  ),
);

if (result.success) {
  final dramas = await sdk.requestRecommendedDramas(pageSize: 20);
  await sdk.openDramaDetail(dramaId: dramas.first.id);
  await sdk.openDramaDrawFeed();
}
```

如果你的 App 已经自己初始化过穿山甲广告 SDK 或 GroMore，为了避免重复初始化，可以关闭插件里的广告 SDK 初始化：

```dart
await sdk.initialize(
  const PangolinContentConfig(
    appId: 'your_applog_app_id',
    adAppId: 'your_pangolin_site_id',
    configFileName: 'SDK_Setting_xxx.json',
    initializeAdSdk: false,
    startAdSdk: false,
  ),
);
```

在 SDK 配置 JSON 里，`init.app_id` 是 AppLog AppID，`init.site_id` 是穿山甲广告/媒体 ID。接入时：

- `appId` 填 `init.app_id`
- `adAppId` 填 `init.site_id`

`PangolinContentConfig` 默认会开启穿山甲 TTPlayer，因为原生播放页和溜溜滑都需要 VOD 播放能力。如果某台设备初始化有问题，想临时排查播放器影响，可以先关闭：

```dart
const PangolinContentConfig(
  appId: 'your_applog_app_id',
  adAppId: 'your_pangolin_site_id',
  configFileName: 'SDK_Setting_xxx.json',
  disableTTPlayer: true,
);
```

## 打开短剧播放页

打开穿山甲原生短剧播放页：

```dart
await PangolinContentSdk.instance.openDramaDetail(
  dramaId: dramaId,
  options: const PangolinDramaDetailOptions(
    index: 1,
    freeSet: 5,
    lockSet: 2,
    playDurationSeconds: 0,
    enterFrom: PangolinDramaEnterFrom.defaultSource,
    enableInfiniteScroll: true,
  ),
);
```

常用播放页参数：

| 控制区域 | 参数 |
| --- | --- |
| 播放入口 | `index`, `playDurationSeconds`, `fromGid`, `enterFrom`, `recMap` |
| 解锁规则 | `freeSet`, `lockSet`, `unlockAdMode`, `enableContinuousUnlock`, `useCustomRewardAd` |
| 播放页 UI | `hideBack`, `hideTopInfo`, `hideBottomInfo`, `hideLikeButton`, `hideFavorButton`, `hideMore`, `hideRewardDialog`, `hideCellularToast`, `hideDoubleClick`, `hideLongClickSpeed` |
| 播放页布局 | `bottomOffset`, `topOffset`, `scriptTipsTopMargin`, `icpTipsBottomMargin` |
| 播放页行为 | `enableInfiniteScroll` |

`enterFrom` 对应穿山甲 `DJXDramaEnterFrom`，目前支持 `defaultSource`、`skitMixed`、`dramaHomeRecentlyWatched`、`dramaHome`、`dramaHistory`、`dramaCard`。`recMap` 用于推荐透传，只放字符串、数字、布尔值这类简单字段。

## 打开溜溜滑

打开穿山甲原生溜溜滑页面：

```dart
await PangolinContentSdk.instance.openDramaDrawFeed(
  options: const PangolinDramaDrawOptions(
    channelType: PangolinDramaDrawChannelType.recommend,
    contentType: PangolinDramaDrawContentType.onlyDrama,
    hideChannelName: true,
    hideDramaInfo: false,
    hideDramaEnter: true,
    dramaFree: 5,
    detailFreeSet: 5,
    detailLockSet: -1,
    detailUseCustomRewardAd: true,
    backRefreshEnabled: false,
    finishOnBlockedBack: true,
  ),
);
```

溜溜滑页面和里面的播放器 UI 是穿山甲原生 SDK 管理的。Flutter 可以控制 SDK 暴露出来的参数，但不能完全替换穿山甲内部播放器页面。

插件默认 `dramaFree` 和 `detailFreeSet` 都为 `5`，也就是溜溜滑短剧流和进入后的播放页默认前 5 集免费。你也可以在 `PangolinDramaDrawOptions` 里改成其他集数。

`hideDramaInfo: false` 会显示溜溜滑底部短剧信息；如果设置成 `true`，底部短剧信息会被隐藏。

如果不希望点击“下一集/进入详情”跳到新的原生详情页，可以设置 `hideDramaEnter: true`。如果希望 Android 返回键直接退出溜溜滑，而不是触发 SDK 的 `backRefresh()`，可以设置 `backRefreshEnabled: false`；当 SDK 当前状态拦截返回导致无反应时，可以配合 `finishOnBlockedBack: true` 强制关闭当前溜溜滑页。

常用可控参数：

| 控制区域 | 参数 |
| --- | --- |
| 内容来源 | `channelType`, `contentType`, `customCategory`, `topDramaId` |
| 广告 | `adCodeId`, `nativeAdCodeId`, `adOffset` |
| 入口页 UI | `hideChannelName`, `hideLikeButton`, `hideFavorButton`, `hideDramaInfo`, `hideDramaEnter`, `hideClose`, `hideDoubleClickLike`, `hideLongClickSpeed`, `enableRefresh`, `showGuide`, `progressBarStyle` |
| 入口页布局 | `bottomOffset`, `reportTopPadding`, `titleLeftMargin`, `titleRightMargin`, `titleTopMargin` |
| 免费和解锁规则 | `dramaFree`, `detailFreeSet`, `detailLockSet`, `enableContinuousUnlock`, `detailUseCustomRewardAd` |
| 详情页 UI | `detailHideBack`, `detailHideTopInfo`, `detailHideBottomInfo`, `detailHideRewardDialog`, `detailHideMore`, `detailHideCellularToast`, `detailHideLikeButton`, `detailHideFavorButton`, `detailHideDoubleClick`, `detailHideLongClickSpeed` |
| 详情页行为和布局 | `detailInfiniteScrollEnabled`, `detailBottomOffset`, `detailTopOffset`, `detailScriptTipsTopMargin`, `detailIcpTipsBottomMargin` |
| 返回行为 | `backRefreshEnabled`, `backRefreshIntervalMillis`, `finishOnBlockedBack` |

## 接入第三方激励广告

如果你要用 AdMob、GroMore、优量汇、快手等第三方激励广告解锁短剧，需要先注册一个 Flutter 广告处理器：

```dart
PangolinContentSdk.instance.setRewardAdHandler((request) async {
  // request.scene 可能是 detail 或 draw_detail
  // request.dramaId 是当前短剧 id
  // request.index 是当前集数

  final rewarded = await yourThirdPartyRewardAd.show();

  if (rewarded) {
    return const PangolinRewardAdResult.rewarded();
  }

  return const PangolinRewardAdResult.notRewarded(
    errorMessage: '用户未完整观看广告',
  );
});
```

然后在打开短剧详情页时开启：

```dart
await PangolinContentSdk.instance.openDramaDetail(
  dramaId: dramaId,
  options: const PangolinDramaDetailOptions(
    useCustomRewardAd: true,
    unlockAdMode: PangolinDramaUnlockAdMode.specific,
  ),
);
```

在溜溜滑里开启：

```dart
await PangolinContentSdk.instance.openDramaDrawFeed(
  options: const PangolinDramaDrawOptions(
    detailUseCustomRewardAd: true,
  ),
);
```

当穿山甲短剧 SDK 需要展示激励广告时，会回调 Flutter；Flutter 展示第三方广告后，把是否奖励成功返回给穿山甲 SDK。`PangolinRewardAdResult.rewarded()` 表示广告完整观看并允许解锁，`PangolinRewardAdResult.notRewarded()` 表示广告展示了但没有奖励，`PangolinRewardAdResult.unavailable()` 表示广告不可用或加载失败。

`useCustomRewardAd: true` 会自动让原生侧使用 `MODE_SPECIFIC`。你也可以显式设置 `unlockAdMode: PangolinDramaUnlockAdMode.specific`。

## 绑定解锁记录

穿山甲文档里的解锁记录绑定接口也已经封装。登录时可以这样调用：

```dart
await PangolinContentSdk.instance.loginWithUid(
  uid: 'your_user_id',
  serverKey: 'your_server_key',
);
```

也可以自己生成签名后登录：

```dart
final loginSign = await PangolinContentSdk.instance.getLoginSignString(
  uid: 'your_user_id',
  serverKey: 'your_server_key',
);

await PangolinContentSdk.instance.loginWithSign(loginSign.sign);
```

退出登录：

```dart
await PangolinContentSdk.instance.logout();
```

检查登录状态：

```dart
final loggedIn = await PangolinContentSdk.instance.isLoggedIn();
```

`serverKey` 比较敏感。正式项目更推荐在你自己的服务端生成签名，再把签名传给 App 调用 `loginWithSign`，避免把真实 `serverKey` 暴露在客户端包里。

## Android Manifest 配置

你也可以在 Android manifest 里通过 metadata 提供 AppLog AppID 和穿山甲广告/媒体 ID：

```xml
<meta-data
    android:name="com.owxo.pangolin_content_sdk.PANGLE_APP_ID"
    android:value="your_applog_app_id" />
<meta-data
    android:name="com.owxo.pangolin_content_sdk.PANGLE_AD_APP_ID"
    android:value="your_pangolin_site_id" />
```

如果使用这种方式，请确认你的 App 在调用 `initialize` 前，穿山甲广告 SDK 已经成功启动。短剧解锁依赖穿山甲广告曝光能力。

## 本地示例

当前仓库里的示例 App 已包含 Android 和 iOS 工程。iOS 示例已配置 Bundle ID、AppLog URL Scheme、SDK 配置 JSON 资源引用和 CocoaPods 依赖。

Android 示例会从下面这个文件读取本地 Android 包名等配置：

```text
example/android/pangolin-local.properties
```

这个文件和 `SDK_Setting_*.json` 都会被 git 忽略。真实的 AppID、包名、SDK 配置 JSON、server key 不要提交到公开仓库。

在真实 Android 手机上运行示例：

```sh
cd example
flutter run
```

在真实 iPhone 上运行 iOS 示例：

```sh
cd example
flutter run -d your_iphone_device_id
```

iOS 模拟器限制：当前接入的 `TTSDKFramework/Player-SR 1.46.2.7-premium` 里 `TTSDKPlayer.xcframework` 只有真机 `ios-arm64` 切片，没有 `ios-x86_64-simulator` 或 `ios-arm64-simulator` 切片。因此 iOS 示例需要真机运行，模拟器会在 Xcode 构建阶段失败。

iOS 示例默认使用：

- AppLog AppID：`925856`
- 穿山甲 site_id：`5554773`
- SDK 配置文件：`SDK_Setting_5554773.json`
- Bundle ID：`com.szl.scmc`
- AppLog URL Scheme：`rangersapplog.d9350a5c8f9cd47e`

本地的 `example/ios/Runner/SDK_Setting_5554773.json` 会被 git 忽略。换成你自己的 iOS 应用时，需要替换 JSON，并确认 Xcode 里已加入 `Runner` target 的 `Copy Bundle Resources`。

你可以用 `--dart-define` 给示例传入初始化信息：

```sh
flutter run \
  --dart-define=PANGLE_APP_ID=your_applog_app_id \
  --dart-define=PANGLE_AD_APP_ID=your_pangolin_site_id \
  --dart-define=PANGLE_CONFIG_FILE=SDK_Setting_xxx.json
```

## 常见问题排查

如果初始化返回 `unknown:java.net.SocketException: Connection reset`，先看 Logcat，不要急着改 AppID。如果 Logcat 里有 `TTAdSdk Init done success`，说明穿山甲广告 SDK 已经启动成功，失败通常发生在内容 SDK 获取 token 的阶段，比如 `InitToken`、`request_token = 0` 或 `Failed to connect to toblog.ctobsnssdk.com`。

建议按下面顺序检查：

- 使用真实 Android 手机测试，不要只用模拟器。
- 换一个网络试试，比如手机热点、移动数据、另一个 Wi-Fi。
- 关闭代理、VPN、防火墙规则，避免字节/AppLog 的 HTTPS 请求被重置。
- 点击示例 App 里的网络诊断按钮。如果 `csj-sp.csjdeveloper.com:443` 或 `toblog.ctobsnssdk.com:443` 访问失败，先修手机网络，SDK 没有这条网络链路就拿不到 token。
- 确认 App 包名、AppLog AppID、穿山甲广告/媒体 ID、`SDK_Setting_*.json` 都来自穿山甲后台的同一个应用。
- 如果 Logcat 里出现 `license_config:null`、`Can not find license`，或者 SDK 提示配置文件异常，需要在穿山甲后台重新填写真实 Android 包名，然后重新下载 SDK 配置 JSON。JSON 里必须有非空的 `license_config`，并且包名要和你的 App 一致。
- 可选转化权限、Provider 警告和 token 网络失败分开看。它们可能影响转化或下载能力，但不等于 `InitToken` 阶段的 `Connection reset`。

## 有用的穿山甲文档

- <https://www.csjplatform.com/supportcenter/28549>
- <https://www.csjplatform.com/supportcenter/28147>
- <https://www.csjplatform.com/supportcenter/28148>
- <https://www.csjplatform.com/supportcenter/27862>
