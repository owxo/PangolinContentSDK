# pangolin_content_sdk_example

这是 `pangolin_content_sdk` 的 Flutter 示例 App，包含 Android 和 iOS 工程。

## Android 真机运行

```sh
flutter run
```

Android 本地配置文件：

```text
android/pangolin-local.properties
android/app/src/main/assets/SDK_Setting_*.json
```

## iOS 真机运行

先安装 Pods：

```sh
cd ios
pod install
cd ..
```

然后连接 iPhone 运行：

```sh
flutter run -d your_iphone_device_id
```

当前穿山甲播放器依赖 `TTSDKFramework/Player-SR 1.46.2.7-premium` 不包含 iOS 模拟器切片，所以这个示例需要真机运行。模拟器会在构建阶段提示 `TTSDKPlayer.xcframework/ios-x86_64-simulator` 不存在。

iOS 示例默认配置：

- AppLog AppID：`925856`
- 穿山甲 site_id：`5554773`
- SDK 配置文件：`SDK_Setting_5554773.json`
- Bundle ID：`com.szl.scmc`
- AppLog URL Scheme：`rangersapplog.d9350a5c8f9cd47e`

`ios/Runner/SDK_Setting_5554773.json` 是本地文件，会被 git 忽略。换应用时需要替换这个 JSON，并确认它在 Xcode 的 `Runner` target 里属于 `Copy Bundle Resources`。
