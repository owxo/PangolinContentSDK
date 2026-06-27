#import "PangolinContentSdkPlugin.h"

#import <UIKit/UIKit.h>

#if __has_include(<AppTrackingTransparency/AppTrackingTransparency.h>)
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#define PANGOLIN_HAS_ATT 1
#else
#define PANGOLIN_HAS_ATT 0
#endif

#if __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#define PANGOLIN_HAS_BUADSDK 1
#else
#define PANGOLIN_HAS_BUADSDK 0
#endif

#if __has_include(<PangrowthDJX/DJXSDK.h>)
#import <PangrowthDJX/DJXSDK.h>
#define PANGOLIN_HAS_DJX 1
#else
#define PANGOLIN_HAS_DJX 0
#endif

static NSString *const PangolinChannelName = @"pangolin_content_sdk";
static NSString *const PangolinDrawFeedViewType = @"pangolin_content_sdk/drama_draw_feed";
static NSString *const PangolinInfoAppIdKey = @"com.owxo.pangolin_content_sdk.PANGLE_APP_ID";
static NSString *const PangolinInfoAdAppIdKey = @"com.owxo.pangolin_content_sdk.PANGLE_AD_APP_ID";

static NSDictionary *PangolinDictionary(id value) {
  return [value isKindOfClass:NSDictionary.class] ? (NSDictionary *)value : @{};
}

static NSArray *PangolinArray(id value) {
  return [value isKindOfClass:NSArray.class] ? (NSArray *)value : @[];
}

static NSString *PangolinStringValue(id value) {
  if ([value isKindOfClass:NSString.class]) {
    return (NSString *)value;
  }
  if ([value respondsToSelector:@selector(stringValue)]) {
    return [value stringValue];
  }
  return nil;
}

static NSString *PangolinString(NSDictionary *dictionary, NSString *key) {
  return PangolinStringValue(dictionary[key]);
}

static NSInteger PangolinInteger(NSDictionary *dictionary, NSString *key, NSInteger fallback) {
  id value = dictionary[key];
  if ([value respondsToSelector:@selector(integerValue)]) {
    return [value integerValue];
  }
  return fallback;
}

static BOOL PangolinBool(NSDictionary *dictionary, NSString *key, BOOL fallback) {
  id value = dictionary[key];
  if ([value respondsToSelector:@selector(boolValue)]) {
    return [value boolValue];
  }
  return fallback;
}

static id PangolinValueForKey(id object, NSString *key) {
  if (!object || key.length == 0) {
    return nil;
  }
  @try {
    id value = [object valueForKey:key];
    return value == NSNull.null ? nil : value;
  } @catch (__unused NSException *exception) {
    return nil;
  }
}

static void PangolinSetValueForKey(id object, NSString *key, id value) {
  if (!object || key.length == 0 || !value) {
    return;
  }
  @try {
    [object setValue:value forKey:key];
  } @catch (__unused NSException *exception) {
  }
}

static id PangolinFirstValue(id object, NSArray<NSString *> *keys) {
  for (NSString *key in keys) {
    id value = PangolinValueForKey(object, key);
    if (value) {
      return value;
    }
  }
  return nil;
}

static NSDictionary *PangolinJSONObjectFromString(NSString *string) {
  if (string.length == 0) {
    return @{};
  }
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) {
    return @{};
  }
  id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  return [object isKindOfClass:NSDictionary.class] ? object : @{};
}

static NSString *PangolinDescribeObject(id object) {
  if (!object || object == NSNull.null) {
    return nil;
  }
  if ([object isKindOfClass:NSString.class]) {
    return object;
  }
  if ([NSJSONSerialization isValidJSONObject:object]) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (json.length > 0) {
      return json;
    }
  }
  return [object description];
}

static UIWindow *PangolinKeyWindow(void) {
  if (@available(iOS 13.0, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (scene.activationState != UISceneActivationStateForegroundActive ||
          ![scene isKindOfClass:UIWindowScene.class]) {
        continue;
      }
      for (UIWindow *window in ((UIWindowScene *)scene).windows) {
        if (window.isKeyWindow) {
          return window;
        }
      }
    }
  }
  return UIApplication.sharedApplication.keyWindow;
}

static UIViewController *PangolinTopViewController(UIViewController *rootViewController) {
  UIViewController *topViewController = rootViewController;
  while (topViewController.presentedViewController) {
    topViewController = topViewController.presentedViewController;
  }
  if ([topViewController isKindOfClass:UINavigationController.class]) {
    return PangolinTopViewController(((UINavigationController *)topViewController).visibleViewController);
  }
  if ([topViewController isKindOfClass:UITabBarController.class]) {
    return PangolinTopViewController(((UITabBarController *)topViewController).selectedViewController);
  }
  return topViewController;
}

static FlutterError *PangolinFlutterError(NSString *code, NSString *message, id details) {
  return [FlutterError errorWithCode:code ?: @"pangolin_error" message:message details:details];
}

@class PangolinContentSdkPlugin;

@interface PangolinDramaDrawFeedPlatformView : NSObject <FlutterPlatformView>
- (instancetype)initWithFrame:(CGRect)frame
                viewIdentifier:(int64_t)viewId
                     arguments:(id)arguments
                         plugin:(PangolinContentSdkPlugin *)plugin;
@end

@interface PangolinDramaDrawFeedFactory : NSObject <FlutterPlatformViewFactory>
- (instancetype)initWithPlugin:(PangolinContentSdkPlugin *)plugin;
@end

#if PANGOLIN_HAS_DJX
@interface PangolinContentSdkPlugin () <DJXAuthorityConfigDelegate, DJXPlayletInterfaceProtocol>
#else
@interface PangolinContentSdkPlugin ()
#endif
@property(nonatomic, strong) FlutterMethodChannel *channel;
@property(nonatomic, assign) BOOL started;
@property(nonatomic, assign) BOOL teenagerMode;
@property(nonatomic, assign) BOOL autoLoginOnRequest;
@property(nonatomic, assign) NSInteger currentUnlockEpisodeCount;
@end

@implementation PangolinContentSdkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:PangolinChannelName
                                                              binaryMessenger:registrar.messenger];
  PangolinContentSdkPlugin *instance = [[PangolinContentSdkPlugin alloc] initWithChannel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
  [registrar registerViewFactory:[[PangolinDramaDrawFeedFactory alloc] initWithPlugin:instance]
                           withId:PangolinDrawFeedViewType];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  self = [super init];
  if (self) {
    _channel = channel;
    _autoLoginOnRequest = YES;
    _currentUnlockEpisodeCount = 2;
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"initialize"]) {
    [self initialize:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"isStarted"]) {
    result(@(self.started));
  } else if ([call.method isEqualToString:@"requestRecommendedPermissions"]) {
    [self requestRecommendedPermissions:result];
  } else if ([call.method isEqualToString:@"checkNetworkAccess"]) {
    [self checkNetworkAccess:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"setTeenagerMode"]) {
    self.teenagerMode = [call.arguments respondsToSelector:@selector(boolValue)] ? [call.arguments boolValue] : NO;
    result(nil);
  } else if ([call.method isEqualToString:@"getLoginSignString"]) {
    [self getLoginSignString:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"login"]) {
    [self login:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"logout"]) {
    [self logout:result];
  } else if ([call.method isEqualToString:@"isLogin"]) {
    [self isLogin:result];
  } else if ([call.method isEqualToString:@"requestAllDramas"]) {
    [self requestAllDramas:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"requestRecommendedDramas"]) {
    [self requestRecommendedDramas:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"requestDramasByIds"]) {
    [self requestDramasByIds:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"requestDramasByCategory"]) {
    [self requestDramasByCategory:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"searchDramas"]) {
    [self searchDramas:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"requestDramaCategories"]) {
    [self requestDramaCategories:result];
  } else if ([call.method isEqualToString:@"getDramaHistory"]) {
    [self getDramaHistory:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"getFavorList"]) {
    [self getFavorList:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"clearDramaHistory"]) {
    [self clearDramaHistory:result];
  } else if ([call.method isEqualToString:@"verifyDramaParams"]) {
    [self verifyDramaParams:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"openDramaDetail"]) {
    [self openDramaDetail:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"openDramaDrawFeed"]) {
    [self openDramaDrawFeed:PangolinDictionary(call.arguments) result:result];
  } else if ([call.method isEqualToString:@"pauseEmbeddedDramaDrawFeed"] ||
             [call.method isEqualToString:@"resumeEmbeddedDramaDrawFeed"]) {
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)initialize:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(@{
    @"success" : @NO,
    @"code" : @(-1001),
    @"message" : @"iOS PangrowthX/shortplay-beta Pod is not linked. Please run pod install after configuring the iOS Podfile."
  });
  return;
#else
  NSString *configPath = [self resolvedConfigPath:arguments];
  NSLog(@"[PangolinContentSDK][iOS] initialize appId=%@ adAppId=%@ bundleId=%@ configPath=%@",
        [self resolvedAppId:arguments],
        [self resolvedAdAppId:arguments],
        NSBundle.mainBundle.bundleIdentifier,
        configPath);
  if (configPath.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:configPath]) {
    NSLog(@"[PangolinContentSDK][iOS] config JSON not found: %@", PangolinString(arguments, @"configFileName") ?: @"");
    result(@{
      @"success" : @NO,
      @"code" : @(-2),
      @"message" : [NSString stringWithFormat:@"iOS SDK config JSON not found: %@", PangolinString(arguments, @"configFileName") ?: @""]
    });
    return;
  }

  NSString *validationMessage = [self validateConfigFileAtPath:configPath arguments:arguments];
  if (validationMessage.length > 0) {
    NSLog(@"[PangolinContentSDK][iOS] config validation failed: %@", validationMessage);
    result(@{
      @"success" : @NO,
      @"code" : @(-3),
      @"message" : validationMessage
    });
    return;
  }

  self.teenagerMode = PangolinBool(arguments, @"teenagerMode", NO);
  self.autoLoginOnRequest = PangolinBool(arguments, @"autoLoginOnRequest", YES);

  DJXConfig *config = [DJXConfig new];
  config.authorityDelegate = self;
  if (PangolinBool(arguments, @"debug", NO)) {
    PangolinSetValueForKey(config, @"logLevel", @(1));
  }

  [DJXManager initializeWithConfigPath:configPath config:config];
  NSLog(@"[PangolinContentSDK][iOS] DJXManager initializeWithConfigPath called.");

  void (^startContentSdk)(void) = ^{
    [DJXManager startWithCompleteHandler:^(BOOL isSuccess, NSDictionary *_Nonnull userInfo) {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[PangolinContentSDK][iOS] DJXManager start result success=%@ userInfo=%@",
              isSuccess ? @"YES" : @"NO",
              userInfo);
        self.started = isSuccess;
        NSString *message = PangolinStringValue(userInfo[@"msg"]) ?: PangolinStringValue(userInfo[@"message"]);
        if (message.length == 0 && !isSuccess) {
          message = PangolinDescribeObject(userInfo);
        }
        id rawCode = userInfo[@"code"] ?: userInfo[@"err_code"];
        NSNumber *code = [rawCode respondsToSelector:@selector(integerValue)] ? @([rawCode integerValue]) : nil;
        result(@{
          @"success" : @(isSuccess),
          @"code" : code ?: @(isSuccess ? 0 : -1),
          @"message" : message ?: (isSuccess ? @"iOS Pangolin Content SDK started." : @"iOS Pangolin Content SDK start failed.")
        });
      });
    }];
  };

  BOOL initializeAdSdk = PangolinBool(arguments, @"initializeAdSdk", YES);
  BOOL startAdSdk = PangolinBool(arguments, @"startAdSdk", YES);
  if (!initializeAdSdk || !startAdSdk) {
    startContentSdk();
    return;
  }

#if PANGOLIN_HAS_BUADSDK
  NSString *adAppId = [self resolvedAdAppId:arguments];
  if (adAppId.length > 0) {
    BUAdSDKConfiguration *adConfig = [BUAdSDKConfiguration configuration];
    adConfig.appID = adAppId;
  }
  [BUAdSDKManager startWithAsyncCompletionHandler:^(__unused BOOL success, __unused NSError *error) {
    NSLog(@"[PangolinContentSDK][iOS] BUAdSDK start result success=%@ error=%@",
          success ? @"YES" : @"NO",
          error);
    startContentSdk();
  }];
#else
  startContentSdk();
#endif
#endif
}

- (NSString *)resolvedConfigPath:(NSDictionary *)arguments {
  NSString *configFilePath = PangolinString(arguments, @"configFilePath");
  if (configFilePath.length > 0) {
    return configFilePath;
  }
  NSString *configFileName = PangolinString(arguments, @"configFileName");
  if (configFileName.length == 0) {
    return nil;
  }
  NSString *extension = configFileName.pathExtension;
  NSString *resource = configFileName.stringByDeletingPathExtension;
  if (extension.length == 0) {
    extension = @"json";
  }
  return [NSBundle.mainBundle pathForResource:resource ofType:extension];
}

- (NSString *)resolvedAppId:(NSDictionary *)arguments {
  NSString *appId = PangolinString(arguments, @"appId");
  if (appId.length > 0) {
    return appId;
  }
  return PangolinStringValue(NSBundle.mainBundle.infoDictionary[PangolinInfoAppIdKey]);
}

- (NSString *)resolvedAdAppId:(NSDictionary *)arguments {
  NSString *adAppId = PangolinString(arguments, @"adAppId");
  if (adAppId.length > 0) {
    return adAppId;
  }
  adAppId = PangolinStringValue(NSBundle.mainBundle.infoDictionary[PangolinInfoAdAppIdKey]);
  if (adAppId.length > 0) {
    return adAppId;
  }
  return [self resolvedAppId:arguments];
}

- (NSString *)validateConfigFileAtPath:(NSString *)path arguments:(NSDictionary *)arguments {
  NSData *data = [NSData dataWithContentsOfFile:path];
  if (!data) {
    return @"Unable to read iOS SDK config JSON.";
  }
  NSError *error;
  id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  if (error || ![object isKindOfClass:NSDictionary.class]) {
    return [NSString stringWithFormat:@"iOS SDK config JSON is invalid: %@", error.localizedDescription ?: @""];
  }
  NSDictionary *json = (NSDictionary *)object;
  NSDictionary *init = PangolinDictionary(json[@"init"]);
  NSString *jsonAppId = PangolinString(init, @"app_id");
  NSString *jsonSiteId = PangolinString(init, @"site_id");
  NSString *appId = [self resolvedAppId:arguments];
  NSString *adAppId = [self resolvedAdAppId:arguments];
  if (appId.length > 0 && jsonAppId.length > 0 && ![appId isEqualToString:jsonAppId]) {
    return [NSString stringWithFormat:@"AppLog AppID mismatch. Dart appId=%@, JSON init.app_id=%@.", appId, jsonAppId];
  }
  if (adAppId.length > 0 && jsonSiteId.length > 0 && ![adAppId isEqualToString:jsonSiteId]) {
    return [NSString stringWithFormat:@"Pangolin site_id mismatch. Dart adAppId=%@, JSON init.site_id=%@.", adAppId, jsonSiteId];
  }

  NSString *bundleId = NSBundle.mainBundle.bundleIdentifier;
  for (NSDictionary *license in PangolinArray(json[@"license_config"])) {
    NSString *licenseBundleId = PangolinString(license, @"BundleId");
    NSString *packageName = PangolinString(license, @"PackageName");
    if ((licenseBundleId.length > 0 && [licenseBundleId isEqualToString:bundleId]) ||
        (packageName.length > 0 && [packageName isEqualToString:bundleId])) {
      return nil;
    }
  }
  if (bundleId.length > 0 && PangolinArray(json[@"license_config"]).count > 0) {
    return [NSString stringWithFormat:@"Bundle ID mismatch. App bundleId=%@, but SDK config license_config does not contain it.", bundleId];
  }
  return nil;
}

- (void)requestRecommendedPermissions:(FlutterResult)result {
  NSMutableDictionary *permissions = [NSMutableDictionary dictionary];
#if PANGOLIN_HAS_ATT
  if (@available(iOS 14, *)) {
    NSString *attReason = NSBundle.mainBundle.infoDictionary[@"NSUserTrackingUsageDescription"];
    if (attReason.length == 0) {
      permissions[@"appTrackingTransparency"] = @NO;
      result(permissions);
      return;
    }
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
      dispatch_async(dispatch_get_main_queue(), ^{
        permissions[@"appTrackingTransparency"] = @(status == ATTrackingManagerAuthorizationStatusAuthorized);
        result(permissions);
      });
    }];
    return;
  }
#endif
  permissions[@"appTrackingTransparency"] = @YES;
  result(permissions);
}

- (void)checkNetworkAccess:(NSDictionary *)arguments result:(FlutterResult)result {
  NSArray *hosts = PangolinArray(arguments[@"hosts"]);
  NSInteger port = PangolinInteger(arguments, @"port", 443);
  NSInteger timeoutMillis = PangolinInteger(arguments, @"timeoutMillis", 3000);
  if (hosts.count == 0) {
    result(@[]);
    return;
  }

  NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
  configuration.timeoutIntervalForRequest = MAX(timeoutMillis, 500) / 1000.0;
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
  dispatch_group_t group = dispatch_group_create();
  NSMutableArray<NSDictionary *> *checks = [NSMutableArray arrayWithCapacity:hosts.count];
  NSLock *lock = [NSLock new];

  for (id hostValue in hosts) {
    NSString *host = PangolinStringValue(hostValue);
    if (host.length == 0) {
      continue;
    }
    NSString *urlString = [NSString stringWithFormat:@"https://%@%@/", host, port == 443 ? @"" : [NSString stringWithFormat:@":%ld", (long)port]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDate *start = NSDate.date;
    dispatch_group_enter(group);
    [[session dataTaskWithURL:url completionHandler:^(__unused NSData *data, __unused NSURLResponse *response, NSError *error) {
      NSInteger elapsed = (NSInteger)([NSDate.date timeIntervalSinceDate:start] * 1000);
      NSDictionary *item = @{
        @"host" : host,
        @"port" : @(port),
        @"reachable" : @(error == nil),
        @"elapsedMs" : @(elapsed),
        @"message" : error.localizedDescription ?: @""
      };
      [lock lock];
      [checks addObject:item];
      [lock unlock];
      dispatch_group_leave(group);
    }] resume];
  }

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    result(checks);
  });
}

- (void)getLoginSignString:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSString *serverKey = PangolinString(arguments, @"serverKey");
  NSString *uid = PangolinString(arguments, @"uid");
  if (serverKey.length == 0 || uid.length == 0) {
    result(PangolinFlutterError(@"pangolin_invalid_argument", @"serverKey and uid are required.", nil));
    return;
  }
  NSString *nonce = PangolinString(arguments, @"nonce");
  if (nonce.length == 0) {
    nonce = [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""].lowercaseString;
    if (nonce.length > 16) {
      nonce = [nonce substringToIndex:16];
    }
  }
  NSTimeInterval timestamp = PangolinInteger(arguments, @"timestampSeconds", 0);
  if (timestamp <= 0) {
    timestamp = NSDate.date.timeIntervalSince1970;
  }
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:PangolinDictionary(arguments[@"params"])];
  params[@"ouid"] = uid;
  NSString *sign = [DJXManager getSignWithPaySecretKey:serverKey nonce:nonce timeStamp:timestamp params:params];
  result(@{
    @"sign" : sign ?: @"",
    @"nonce" : nonce,
    @"timestampSeconds" : @((NSInteger)timestamp),
    @"params" : params
  });
#endif
}

- (void)login:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSString *sign = PangolinString(arguments, @"sign");
  if (sign.length == 0) {
    result(PangolinFlutterError(@"pangolin_invalid_argument", @"sign is required.", nil));
    return;
  }
  [DJXManager loginWithParamsString:sign completionBlock:^(__unused BOOL loginStatus, NSDictionary *_Nonnull userInfo) {
    result(userInfo ?: @{});
  }];
#endif
}

- (void)logout:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  [DJXManager logoutWithCompletionBlock:^(__unused BOOL loginStatus, NSDictionary *_Nonnull userInfo) {
    result(userInfo ?: @{});
  }];
#endif
}

- (void)isLogin:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(@NO);
#else
  result(@([DJXManager isLogin]));
#endif
}

- (void)requestAllDramas:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSInteger page = PangolinInteger(arguments, @"page", 1);
  NSInteger pageSize = PangolinInteger(arguments, @"pageSize", 20);
  NSInteger order = PangolinBool(arguments, @"orderByHot", NO) ? 2 : 0;
  [[DJXPlayletManager shareInstance] requestAllPlayletListWithOrder:order
                                                            success:^(NSArray<DJXPlayletInfoModel *> *_Nonnull playletList, __unused NSDictionary<NSString *, NSObject *> *_Nonnull info) {
                                                              result([self mappedPlayletList:playletList page:page pageSize:pageSize]);
                                                            }
                                                            failure:^(NSError *_Nonnull error) {
                                                              result([self flutterErrorFromNSError:error]);
                                                            }];
#endif
}

- (void)requestRecommendedDramas:(NSDictionary *)arguments result:(FlutterResult)result {
  NSMutableDictionary *request = [arguments mutableCopy];
  request[@"orderByHot"] = @YES;
  [self requestAllDramas:request result:result];
}

- (void)requestDramasByIds:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSArray *ids = PangolinArray(arguments[@"ids"]);
  [[DJXPlayletManager shareInstance] requestPlayletListWithPlayletId:ids
                                                             success:^(NSArray<DJXPlayletInfoModel *> *_Nonnull playletList) {
                                                               result([self mappedPlayletList:playletList page:1 pageSize:0]);
                                                             }
                                                             failure:^(NSError *_Nonnull error) {
                                                               result([self flutterErrorFromNSError:error]);
                                                             }];
#endif
}

- (void)requestDramasByCategory:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSString *category = PangolinString(arguments, @"category");
  NSInteger page = PangolinInteger(arguments, @"page", 1);
  NSInteger pageSize = PangolinInteger(arguments, @"pageSize", 20);
  NSInteger order = PangolinInteger(arguments, @"order", 1);
  [[DJXPlayletManager shareInstance] requestCategoryPlayletLisWithCategory:category
                                                                      page:page
                                                                       num:pageSize
                                                                     order:order
                                                                   success:^(NSArray<DJXPlayletInfoModel *> *_Nonnull playletList) {
                                                                     result([self mappedPlayletList:playletList page:1 pageSize:0]);
                                                                   }
                                                                   failure:^(NSError *_Nonnull error) {
                                                                     result([self flutterErrorFromNSError:error]);
                                                                   }];
#endif
}

- (void)searchDramas:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSString *query = PangolinString(arguments, @"query");
  BOOL fuzzy = PangolinBool(arguments, @"fuzzy", YES);
  NSInteger page = PangolinInteger(arguments, @"page", 1);
  NSInteger pageSize = PangolinInteger(arguments, @"pageSize", 20);
  [[DJXPlayletManager shareInstance] requestCategoryPlayletLisWithSearchWord:query
                                                                     isFuzzy:fuzzy
                                                                        page:page
                                                                         num:pageSize
                                                                     success:^(NSArray<DJXPlayletInfoModel *> *_Nonnull playletList, __unused BOOL hasMore) {
                                                                       result([self mappedPlayletList:playletList page:1 pageSize:0]);
                                                                     }
                                                                     failure:^(NSError *_Nonnull error) {
                                                                       result([self flutterErrorFromNSError:error]);
                                                                     }];
#endif
}

- (void)requestDramaCategories:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  [[DJXPlayletManager shareInstance] requestCategoryList:^(NSArray<NSString *> *_Nonnull categoryList) {
    result(categoryList ?: @[]);
  } failure:^(NSError *_Nonnull error) {
    result([self flutterErrorFromNSError:error]);
  }];
#endif
}

- (void)getDramaHistory:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSInteger page = MAX(PangolinInteger(arguments, @"offset", 1), 1);
  NSInteger count = PangolinInteger(arguments, @"count", 20);
  [[DJXPlayletManager shareInstance] requestPlayletHistoryListWithPage:page
                                                                   num:count > 0 ? count : 20
                                                               success:^(NSArray<DJXPlayletInfoModel *> *_Nonnull playletList) {
                                                                 result([self mappedPlayletList:playletList page:1 pageSize:0]);
                                                               }
                                                               failure:^(NSError *_Nonnull error) {
                                                                 result([self flutterErrorFromNSError:error]);
                                                               }];
#endif
}

- (void)getFavorList:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSInteger page = MAX(PangolinInteger(arguments, @"offset", 1), 1);
  NSInteger count = PangolinInteger(arguments, @"count", 20);
  [[DJXPlayletManager shareInstance] requestCollectionList:page
                                                  pageSize:count > 0 ? count : 20
                                                   success:^(NSArray<DJXPlayletInfoModel *> *_Nonnull playletList, __unused BOOL hasMore) {
                                                     result([self mappedPlayletList:playletList page:1 pageSize:0]);
                                                   }
                                                   failure:^(NSError *_Nonnull error) {
                                                     result([self flutterErrorFromNSError:error]);
                                                   }];
#endif
}

- (void)clearDramaHistory:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  [[DJXPlayletManager shareInstance] requestPlayletHistoryCleanWithCompletion:^{
    result(nil);
  } failure:^(NSError *_Nonnull error) {
    result([self flutterErrorFromNSError:error]);
  }];
#endif
}

- (void)verifyDramaParams:(NSDictionary *)arguments result:(FlutterResult)result {
  NSInteger total = PangolinInteger(arguments, @"total", 0);
  NSInteger freeSet = MAX(PangolinInteger(arguments, @"freeSet", 0), 0);
  NSInteger lockSet = PangolinInteger(arguments, @"lockSet", 0);
  if (total > 0) {
    freeSet = MIN(freeSet, total);
  }
  result(@{@"freeSet" : @(freeSet), @"lockSet" : @(lockSet)});
}

- (void)openDramaDetail:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSInteger dramaId = PangolinInteger(arguments, @"dramaId", 0);
  NSDictionary *options = PangolinDictionary(arguments[@"options"]);
  if (dramaId <= 0) {
    result(PangolinFlutterError(@"pangolin_invalid_argument", @"dramaId is required.", nil));
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *presenter = [self topViewController];
    if (!presenter) {
      result(PangolinFlutterError(@"pangolin_no_presenter", @"Unable to find iOS view controller to present Pangolin playlet page.", nil));
      return;
    }
    DJXPlayletConfig *config = [self playletConfigWithDetailOptions:options dramaId:dramaId];
    DJXDrawVideoViewController *viewController = [[DJXPlayletManager shareInstance] playletViewControllerWithParams:config];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [presenter presentViewController:viewController animated:YES completion:^{
      result(nil);
    }];
  });
#endif
}

- (void)openDramaDrawFeed:(NSDictionary *)arguments result:(FlutterResult)result {
#if !PANGOLIN_HAS_DJX
  result(PangolinFlutterError(@"pangolin_sdk_missing", @"PangrowthX SDK is not linked.", nil));
#else
  NSDictionary *options = PangolinDictionary(arguments[@"options"]);
  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *presenter = [self topViewController];
    if (!presenter) {
      result(PangolinFlutterError(@"pangolin_no_presenter", @"Unable to find iOS view controller to present Pangolin draw feed page.", nil));
      return;
    }
    DJXDrawVideoViewController *viewController = [self drawFeedViewControllerWithOptions:options frame:UIScreen.mainScreen.bounds];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [presenter presentViewController:viewController animated:YES completion:^{
      result(nil);
    }];
  });
#endif
}

#if PANGOLIN_HAS_DJX
- (DJXPlayletConfig *)playletConfigWithDetailOptions:(NSDictionary *)options dramaId:(NSInteger)dramaId {
  DJXPlayletConfig *config = [DJXPlayletConfig new];
  config.skitId = dramaId;
  config.episode = PangolinInteger(options, @"index", 1);
  config.freeEpisodesCount = PangolinInteger(options, @"freeSet", 5);
  config.unlockEpisodesCountUsingAD = PangolinInteger(options, @"lockSet", 2);
  config.playletUnlockADMode = [self unlockAdModeFromOptions:options useCustomRewardKey:@"useCustomRewardAd"];
  config.closeInfiniteScroll = !PangolinBool(options, @"enableInfiniteScroll", YES);
  if (PangolinInteger(options, @"playDurationSeconds", 0) > 0) {
    config.playStartTime = PangolinInteger(options, @"playDurationSeconds", 0);
  }
  if (PangolinValueForKey(options, @"topOffset")) {
    config.fromTopMargin = PangolinInteger(options, @"topOffset", 0);
  }
  if (PangolinBool(options, @"hideBack", NO)) {
    config.hideBackButton = YES;
  }
  if (PangolinBool(options, @"hideMore", NO)) {
    config.hideMoreButton = YES;
  }
  if (PangolinBool(options, @"hideRewardDialog", NO)) {
    config.hideRewardDialog = YES;
  }
  if (PangolinBool(options, @"useCustomRewardAd", NO)) {
    self.currentUnlockEpisodeCount = MAX(PangolinInteger(options, @"lockSet", 2), 1);
    config.interfaceDelegate = self;
  }
  [self applyCommonDetailOptions:options toPlayletConfig:config];
  return config;
}

- (DJXDrawVideoViewController *)drawFeedViewControllerWithOptions:(NSDictionary *)options frame:(CGRect)frame {
  CGSize viewSize = frame.size;
  if (viewSize.width <= 0 || viewSize.height <= 0) {
    viewSize = UIScreen.mainScreen.bounds.size;
  }

  DJXDrawVideoViewController *viewController = [[DJXDrawVideoViewController alloc] initWithConfigBuilder:^(DJXDrawVideoVCConfig *_Nonnull config) {
    DJXPlayletConfig *playletConfig = [DJXPlayletConfig new];
    playletConfig.playletUnlockADMode = [self unlockAdModeFromOptions:options useCustomRewardKey:@"detailUseCustomRewardAd"];
    playletConfig.freeEpisodesCount = PangolinInteger(options, @"dramaFree", 5);
    NSInteger unlockCount = PangolinInteger(options, @"detailLockSet", -1);
    playletConfig.unlockEpisodesCountUsingAD = unlockCount > 0 ? unlockCount : 2;
    if (PangolinBool(options, @"detailUseCustomRewardAd", NO)) {
      self.currentUnlockEpisodeCount = MAX(playletConfig.unlockEpisodesCountUsingAD, 1);
      playletConfig.interfaceDelegate = self;
    }
    [self applyDrawDetailOptions:options toPlayletConfig:playletConfig];
    config.playletConfig = playletConfig;
    config.drawVCTabOptions = [self drawTabOptionsFromOptions:options];
    config.viewSize = viewSize;
    config.shouldHideTabBarView = YES;
    PangolinSetValueForKey(config, @"shouldHideCloseButton", @(PangolinBool(options, @"hideClose", NO)));
    PangolinSetValueForKey(config, @"hideChannelName", @(PangolinBool(options, @"hideChannelName", NO)));
    PangolinSetValueForKey(config, @"hideDramaInfo", @(PangolinBool(options, @"hideDramaInfo", NO)));
    PangolinSetValueForKey(config, @"hidePlayletInfo", @(PangolinBool(options, @"hideDramaInfo", NO)));
    PangolinSetValueForKey(config, @"hideDramaEnter", @(PangolinBool(options, @"hideDramaEnter", NO)));
    PangolinSetValueForKey(config, @"topSkitId", @(PangolinInteger(options, @"topDramaId", 0)));
  }];
  return viewController;
}

- (NSInteger)unlockAdModeFromOptions:(NSDictionary *)options useCustomRewardKey:(NSString *)customRewardKey {
  NSString *mode = PangolinString(options, @"unlockAdMode");
  if (PangolinBool(options, customRewardKey, NO) || [mode isEqualToString:@"specific"]) {
    return DJXPlayletUnlockADMode_Specific;
  }
  return DJXPlayletUnlockADMode_Common;
}

- (DJXDrawVideoVCTabOptions)drawTabOptionsFromOptions:(NSDictionary *)options {
  NSString *channelType = PangolinString(options, @"channelType");
  if ([channelType isEqualToString:@"theater"]) {
    return DJXDrawVideoVCTabOptions_theater;
  }
  if ([channelType isEqualToString:@"recommendTheater"]) {
    return DJXDrawVideoVCTabOptions_theater | DJXDrawVideoVCTabOptions_playlet_feed;
  }
  return DJXDrawVideoVCTabOptions_playlet_feed;
}

- (void)applyDrawDetailOptions:(NSDictionary *)options toPlayletConfig:(DJXPlayletConfig *)config {
  NSMutableDictionary *detailOptions = [NSMutableDictionary dictionary];
  detailOptions[@"enableInfiniteScroll"] = @(PangolinBool(options, @"detailInfiniteScrollEnabled", YES));
  detailOptions[@"hideBack"] = @(PangolinBool(options, @"detailHideBack", NO));
  detailOptions[@"hideTopInfo"] = @(PangolinBool(options, @"detailHideTopInfo", NO));
  detailOptions[@"hideBottomInfo"] = @(PangolinBool(options, @"detailHideBottomInfo", NO));
  detailOptions[@"hideRewardDialog"] = @(PangolinBool(options, @"detailHideRewardDialog", NO));
  detailOptions[@"hideMore"] = @(PangolinBool(options, @"detailHideMore", NO));
  detailOptions[@"hideCellularToast"] = @(PangolinBool(options, @"detailHideCellularToast", NO));
  detailOptions[@"hideLikeButton"] = @(PangolinBool(options, @"detailHideLikeButton", NO));
  detailOptions[@"hideFavorButton"] = @(PangolinBool(options, @"detailHideFavorButton", NO));
  detailOptions[@"hideDoubleClick"] = @(PangolinBool(options, @"detailHideDoubleClick", NO));
  detailOptions[@"hideLongClickSpeed"] = @(PangolinBool(options, @"detailHideLongClickSpeed", NO));
  if (options[@"detailBottomOffset"]) {
    detailOptions[@"bottomOffset"] = options[@"detailBottomOffset"];
  }
  if (options[@"detailTopOffset"]) {
    detailOptions[@"topOffset"] = options[@"detailTopOffset"];
  }
  if (options[@"detailScriptTipsTopMargin"]) {
    detailOptions[@"scriptTipsTopMargin"] = options[@"detailScriptTipsTopMargin"];
  }
  if (options[@"detailIcpTipsBottomMargin"]) {
    detailOptions[@"icpTipsBottomMargin"] = options[@"detailIcpTipsBottomMargin"];
  }
  [self applyCommonDetailOptions:detailOptions toPlayletConfig:config];
}

- (void)applyCommonDetailOptions:(NSDictionary *)options toPlayletConfig:(DJXPlayletConfig *)config {
  config.closeInfiniteScroll = !PangolinBool(options, @"enableInfiniteScroll", YES);
  if (PangolinBool(options, @"hideBack", NO)) {
    config.hideBackButton = YES;
  }
  if (PangolinBool(options, @"hideMore", NO)) {
    config.hideMoreButton = YES;
  }
  if (PangolinBool(options, @"hideRewardDialog", NO)) {
    config.hideRewardDialog = YES;
  }
  PangolinSetValueForKey(config, @"hideTopInfo", @(PangolinBool(options, @"hideTopInfo", NO)));
  PangolinSetValueForKey(config, @"hideBottomInfo", @(PangolinBool(options, @"hideBottomInfo", NO)));
  PangolinSetValueForKey(config, @"hideLikeButton", @(PangolinBool(options, @"hideLikeButton", NO)));
  PangolinSetValueForKey(config, @"hideFavorButton", @(PangolinBool(options, @"hideFavorButton", NO)));
  PangolinSetValueForKey(config, @"hideCellularToast", @(PangolinBool(options, @"hideCellularToast", NO)));
  PangolinSetValueForKey(config, @"hideDoubleClick", @(PangolinBool(options, @"hideDoubleClick", NO)));
  PangolinSetValueForKey(config, @"hideLongClickSpeed", @(PangolinBool(options, @"hideLongClickSpeed", NO)));
  PangolinSetValueForKey(config, @"bottomOffset", PangolinValueForKey(options, @"bottomOffset"));
  PangolinSetValueForKey(config, @"fromTopMargin", PangolinValueForKey(options, @"topOffset"));
  PangolinSetValueForKey(config, @"scriptTipsTopMargin", PangolinValueForKey(options, @"scriptTipsTopMargin"));
  PangolinSetValueForKey(config, @"icpTipsBottomMargin", PangolinValueForKey(options, @"icpTipsBottomMargin"));
}

- (NSArray<NSDictionary *> *)mappedPlayletList:(NSArray *)playletList page:(NSInteger)page pageSize:(NSInteger)pageSize {
  NSArray *list = playletList ?: @[];
  NSInteger start = 0;
  NSInteger end = list.count;
  if (pageSize > 0) {
    start = MAX(page - 1, 0) * pageSize;
    end = MIN(start + pageSize, (NSInteger)list.count);
  }
  if (start >= list.count || start >= end) {
    return @[];
  }
  NSMutableArray<NSDictionary *> *mapped = [NSMutableArray arrayWithCapacity:end - start];
  for (NSInteger index = start; index < end; index += 1) {
    [mapped addObject:[self mappedPlaylet:list[index]]];
  }
  return mapped;
}

- (NSDictionary *)mappedPlaylet:(id)model {
  NSMutableDictionary *raw = [NSMutableDictionary dictionary];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  SEL jsonSelector = NSSelectorFromString(@"BUYY_modelToJSONString");
  if ([model respondsToSelector:jsonSelector]) {
    NSString *jsonString = [model performSelector:jsonSelector];
    [raw addEntriesFromDictionary:PangolinJSONObjectFromString(jsonString)];
  }
#pragma clang diagnostic pop
  NSArray<NSString *> *idKeys = @[@"shortplay_id", @"shortplayId", @"skitId", @"playletId", @"id"];
  NSArray<NSString *> *episodeKeys = @[@"current_episode", @"currentEpisode", @"episode", @"index"];
  NSArray<NSString *> *titleKeys = @[@"title", @"name", @"shortplay_name", @"playletName"];
  NSArray<NSString *> *totalKeys = @[@"total", @"total_episode", @"totalEpisode", @"episodeCount"];
  NSArray<NSString *> *coverKeys = @[@"cover_url", @"coverUrl", @"coverImage", @"cover", @"poster", @"image", @"thumb"];
  raw[@"id"] = @([PangolinFirstValue(model, idKeys) integerValue]);
  raw[@"index"] = @([PangolinFirstValue(model, episodeKeys) integerValue] ?: 1);
  id title = PangolinFirstValue(model, titleKeys);
  if (title) {
    raw[@"title"] = title;
  }
  id total = PangolinFirstValue(model, totalKeys);
  if (total) {
    raw[@"total"] = total;
  }
  id cover = PangolinFirstValue(model, coverKeys);
  if (cover) {
    raw[@"coverUrl"] = cover;
  }
  id category = PangolinFirstValue(model, @[@"category", @"categoryName", @"type"]);
  if (category) {
    raw[@"category"] = category;
  }
  id desc = PangolinFirstValue(model, @[@"description", @"desc", @"intro", @"summary"]);
  if (desc) {
    raw[@"description"] = desc;
  }
  return raw;
}

- (FlutterError *)flutterErrorFromNSError:(NSError *)error {
  return PangolinFlutterError(
      @"pangolin_request_failed",
      error.localizedDescription ?: @"Pangolin iOS SDK request failed.",
      @{@"code" : @(error.code), @"domain" : error.domain ?: @""});
}

- (UIViewController *)topViewController {
  return PangolinTopViewController(PangolinKeyWindow().rootViewController);
}

- (BOOL)isOnlyICPNumber {
  return NO;
}

- (BOOL)turnOnTeenMode {
  return self.teenagerMode;
}

- (BOOL)allowAccessIDFA {
#if PANGOLIN_HAS_ATT
  if (@available(iOS 14, *)) {
    return [ATTrackingManager trackingAuthorizationStatus] == ATTrackingManagerAuthorizationStatusAuthorized;
  }
#endif
  return YES;
}

- (void)nextPlayletWillPlay:(DJXPlayletInfoModel *)infoModel {
}

- (void)clickEnterView:(nonnull DJXPlayletInfoModel *)infoModel {
}

- (void)playletDetailUnlockFlowStart:(DJXPlayletInfoModel *)infoModel
                   unlockInfoHandler:(void (^)(DJXPlayletUnlockModel *_Nonnull))unlockInfoHandler
                            extraInfo:(NSDictionary *_Nullable)extraInfo {
  DJXPlayletUnlockModel *unlockInfo = [[DJXPlayletUnlockModel alloc] init];
  unlockInfo.playletId = infoModel.shortplay_id;
  unlockInfo.unlockEpisodeCount = MAX(self.currentUnlockEpisodeCount, 1);
  if (PangolinValueForKey(extraInfo, @"isContinuityUnlock")) {
    PangolinSetValueForKey(unlockInfo, @"unlockModeType", PangolinValueForKey(extraInfo, @"unlockModeType"));
  }
  unlockInfoHandler(unlockInfo);
}

- (void)playletDetailUnlockFlowShowCustomAD:(DJXPlayletInfoModel *)infoModel
                               onADWillShow:(void (^)(NSString *cpm))onADWillShow
                      onADRewardDidVerified:(void (^)(DJXRewardAdResult *_Nonnull))onADRewardDidVerified {
  if (onADWillShow) {
    onADWillShow(@"0");
  }
  NSDictionary *arguments = @{
    @"scene" : @"ios_playlet_detail",
    @"dramaId" : @(infoModel.shortplay_id),
    @"index" : @(infoModel.current_episode),
    @"extra" : @{
      @"title" : infoModel.title ?: @"",
    }
  };
  [self.channel invokeMethod:@"onRewardAdRequested"
                   arguments:arguments
                      result:^(id response) {
                        NSDictionary *map = PangolinDictionary(response);
                        DJXRewardAdResult *adResult = [[DJXRewardAdResult alloc] init];
                        adResult.success = PangolinBool(map, @"rewarded", NO);
                        adResult.cpm = PangolinString(map, @"ecpm") ?: @"0";
                        if (onADRewardDidVerified) {
                          onADRewardDidVerified(adResult);
                        }
                      }];
}

- (void)playletDetailUnlockFlowEnd:(DJXPlayletInfoModel *)infoModel
                            success:(BOOL)success
                              error:(NSError *)error
                          extraInfo:(NSDictionary *_Nullable)extraInfo {
}
#endif

@end

@implementation PangolinDramaDrawFeedFactory {
  PangolinContentSdkPlugin *_plugin;
}

- (instancetype)initWithPlugin:(PangolinContentSdkPlugin *)plugin {
  self = [super init];
  if (self) {
    _plugin = plugin;
  }
  return self;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
  return FlutterStandardMessageCodec.sharedInstance;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id)args {
  return [[PangolinDramaDrawFeedPlatformView alloc] initWithFrame:frame
                                                   viewIdentifier:viewId
                                                        arguments:args
                                                            plugin:_plugin];
}

@end

@implementation PangolinDramaDrawFeedPlatformView {
  UIView *_view;
#if PANGOLIN_HAS_DJX
  DJXDrawVideoViewController *_viewController;
#endif
}

- (instancetype)initWithFrame:(CGRect)frame
                viewIdentifier:(int64_t)viewId
                     arguments:(id)arguments
                         plugin:(PangolinContentSdkPlugin *)plugin {
  self = [super init];
  if (self) {
    _view = [[UIView alloc] initWithFrame:frame];
    _view.backgroundColor = UIColor.blackColor;
#if PANGOLIN_HAS_DJX
    NSDictionary *options = PangolinDictionary(arguments);
    _viewController = [plugin drawFeedViewControllerWithOptions:options frame:frame];
    UIViewController *parent = [plugin topViewController];
    if (parent) {
      [parent addChildViewController:_viewController];
      _viewController.view.frame = _view.bounds;
      _viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      [_view addSubview:_viewController.view];
      [_viewController didMoveToParentViewController:parent];
    }
#endif
  }
  return self;
}

- (UIView *)view {
  return _view;
}

- (void)dealloc {
#if PANGOLIN_HAS_DJX
  [_viewController willMoveToParentViewController:nil];
  [_viewController.view removeFromSuperview];
  [_viewController removeFromParentViewController];
#endif
}

@end
