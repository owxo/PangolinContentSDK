package com.owxo.pangolin_content_sdk

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.bytedance.sdk.djx.base.dynamic.DynamicManager
import com.bytedance.sdk.djx.base.dynamic.DynamicModel
import com.bytedance.sdk.djx.base.dynamic.api.DynamicApi
import com.bytedance.sdk.djx.DJXSdk
import com.bytedance.sdk.djx.DJXSdkConfig
import com.bytedance.sdk.djx.IDJXPrivacyController
import com.bytedance.sdk.djx.IDJXRouter
import com.bytedance.sdk.djx.IDJXService
import com.bytedance.sdk.djx.model.DJXDrama
import com.bytedance.sdk.djx.model.DJXError
import com.bytedance.sdk.djx.model.DJXLock
import com.bytedance.sdk.djx.model.DJXOthers
import com.bytedance.sdk.djx.model.DJXUser
import com.bytedance.sdk.djx.utils.VerifierSp
import com.bytedance.sdk.openadsdk.TTAdConfig
import com.bytedance.sdk.openadsdk.TTAdConstant
import com.bytedance.sdk.openadsdk.TTAdSdk
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.lang.reflect.Modifier
import java.net.InetSocketAddress
import java.net.Socket
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject

class PangolinContentSdkPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var application: Application
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var teenagerMode: Boolean = false
    private var autoLoginOnRequest: Boolean = true
    private var pendingPermissionResult: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        application = binding.applicationContext.applicationContext as Application
        channel = MethodChannel(binding.binaryMessenger, "pangolin_content_sdk")
        channel.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "pangolin_content_sdk/drama_draw_feed",
            PangolinDramaDrawPlatformViewFactory { activity },
        )
        PangolinRewardAdBridge.attach(channel)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "isStarted" -> result.success(DJXSdk.isStartSuccess())
            "requestRecommendedPermissions" -> requestRecommendedPermissions(result)
            "checkNetworkAccess" -> checkNetworkAccess(call, result)
            "setTeenagerMode" -> {
                teenagerMode = call.arguments as? Boolean ?: false
                result.success(null)
            }
            "getLoginSignString" -> getLoginSignString(call, result)
            "login" -> login(call, result)
            "logout" -> logout(result)
            "isLogin" -> result.success(DJXSdk.isStartSuccess() && DJXSdk.service().isLogin)
            "requestAllDramas" -> requestAllDramas(call, result)
            "requestRecommendedDramas" -> requestRecommendedDramas(call, result)
            "requestDramasByIds" -> requestDramasByIds(call, result)
            "requestDramasByCategory" -> requestDramasByCategory(call, result)
            "searchDramas" -> searchDramas(call, result)
            "requestDramaCategories" -> requestDramaCategories(result)
            "getDramaHistory" -> getDramaHistory(call, result)
            "getFavorList" -> getFavorList(call, result)
            "clearDramaHistory" -> clearDramaHistory(result)
            "verifyDramaParams" -> verifyDramaParams(call, result)
            "openDramaDetail" -> openDramaDetail(call, result)
            "openDramaDrawFeed" -> openDramaDrawFeed(call, result)
            "pauseEmbeddedDramaDrawFeed" -> {
                PangolinDramaDrawPlatformViewRegistry.pauseAll()
                result.success(null)
            }
            "resumeEmbeddedDramaDrawFeed" -> {
                PangolinDramaDrawPlatformViewRegistry.resumeAll()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PangolinRewardAdBridge.detach(channel)
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val callback = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        callback.successOnMain(recommendedPermissionStatus())
        return true
    }

    private fun requestRecommendedPermissions(result: Result) {
        val missingPermissions = runtimeRecommendedPermissions()
            .filterNot(::isPermissionGranted)

        if (missingPermissions.isEmpty()) {
            result.successOnMain(recommendedPermissionStatus())
            return
        }

        val currentActivity = activity
        if (currentActivity == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.successOnMain(recommendedPermissionStatus())
            return
        }

        if (pendingPermissionResult != null) {
            result.errorOnMain(
                "pangolin_permission_request_active",
                "A permission request is already active.",
                null,
            )
            return
        }

        pendingPermissionResult = result
        currentActivity.requestPermissions(
            missingPermissions.toTypedArray(),
            PERMISSION_REQUEST_CODE,
        )
    }

    private fun checkNetworkAccess(call: MethodCall, result: Result) {
        val args = call.argumentsMap()
        val hosts = args.list("hosts")
            .mapNotNull { it as? String }
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .ifEmpty {
                listOf(
                    "csj-sp.csjdeveloper.com",
                    "toblog.ctobsnssdk.com",
                )
            }
        val port = args.int("port", 443)
        val timeoutMillis = args.int("timeoutMillis", 3000).coerceIn(500, 15000)

        Thread {
            val checks = hosts.map { host ->
                val startedAt = System.currentTimeMillis()
                try {
                    Socket().use { socket ->
                        socket.connect(InetSocketAddress(host, port), timeoutMillis)
                    }
                    mapOf(
                        "host" to host,
                        "port" to port,
                        "reachable" to true,
                        "elapsedMs" to (System.currentTimeMillis() - startedAt).toInt(),
                    )
                } catch (error: Throwable) {
                    mapOf(
                        "host" to host,
                        "port" to port,
                        "reachable" to false,
                        "elapsedMs" to (System.currentTimeMillis() - startedAt).toInt(),
                        "message" to "${error.javaClass.simpleName}: ${error.message.orEmpty()}",
                    )
                }
            }
            result.successOnMain(checks)
        }.start()
    }

    private fun initialize(call: MethodCall, result: Result) {
        val args = call.argumentsMap()
        val appId = args.string("appId")?.takeIf { it.isNotBlank() }
            ?: readManifestString("com.owxo.pangolin_content_sdk.PANGLE_APP_ID")
        val adAppId = args.string("adAppId")?.takeIf { it.isNotBlank() }
            ?: readManifestString("com.owxo.pangolin_content_sdk.PANGLE_AD_APP_ID")
            ?: appId
        val configFileName = args.string("configFileName")?.trim()
        val configFilePath = args.string("configFilePath")?.trim()?.takeIf { it.isNotBlank() }
        if (appId.isNullOrBlank()) {
            result.errorOnMain("pangolin_invalid_app_id", "appId is required.", null)
            return
        }
        if (adAppId.isNullOrBlank()) {
            result.errorOnMain("pangolin_invalid_ad_app_id", "adAppId is required.", null)
            return
        }
        if (configFileName.isNullOrBlank()) {
            result.errorOnMain("pangolin_invalid_config", "configFileName is required.", null)
            return
        }
        val settingJson = try {
            readSdkSettingJson(configFileName, configFilePath)
        } catch (error: Throwable) {
            result.successOnMain(
                mapOf(
                    "success" to false,
                    "code" to CONFIG_VALIDATION_ERROR_CODE,
                    "message" to "无法读取 SDK 配置文件 ${configFilePath ?: configFileName}：${error.message.orEmpty()}",
                ),
            )
            return
        }
        val configIssue = validateSdkSettingJson(settingJson, appId, adAppId)
        if (configIssue != null) {
            result.successOnMain(
                mapOf(
                    "success" to false,
                    "code" to CONFIG_VALIDATION_ERROR_CODE,
                    "message" to configIssue,
                ),
            )
            return
        }
        if (configFilePath != null) {
            val preloadIssue = preloadDynamicSettings(settingJson)
            if (preloadIssue != null) {
                result.successOnMain(
                    mapOf(
                        "success" to false,
                        "code" to CONFIG_VALIDATION_ERROR_CODE,
                        "message" to preloadIssue,
                    ),
                )
                return
            }
        }

        teenagerMode = args.boolean("teenagerMode", false)
        autoLoginOnRequest = args.boolean("autoLoginOnRequest", true)
        val disableVerifier = args.boolean("disableVerifier", true)
        VerifierSp.setVerifierDisabled(disableVerifier)

        if (args.boolean("initializeAdSdk", true)) {
            val adConfig = TTAdConfig.Builder()
                .appId(adAppId)
                .appName(args.string("appName") ?: "pangolin_content_sdk")
                .titleBarTheme(TTAdConstant.TITLE_BAR_THEME_DARK)
                .allowShowNotify(args.boolean("allowShowNotify", true))
                .supportMultiProcess(args.boolean("supportMultiProcess", true))
                .useTextureView(args.boolean("useTextureView", false))
                .debug(args.boolean("debug", false))
                .build()
            TTAdSdk.init(application, adConfig)
        }

        val contentConfig = DJXSdkConfig.Builder()
            .debug(args.boolean("debug", false))
            .newUser(args.boolean("newUser", true))
            .isFoldDeviceFromOuter(args.boolean("isFoldDeviceFromOuter", false))
            .isUseSdkInnerFoldDeviceMethod(args.boolean("useSdkInnerFoldDeviceMethod", true))
            .isEnableFoldableScreenAdaptation(args.boolean("enableFoldableScreenAdaptation", true))
            .disableTTPlayer(args.boolean("disableTTPlayer", false))
            .build()

        contentConfig.privacyController = object : IDJXPrivacyController() {
            override fun isTeenagerMode(): Boolean = teenagerMode
        }
        contentConfig.router = object : IDJXRouter {
            override fun onLogin(callback: IDJXService.IDJXCallback<Boolean>?) {
                if (autoLoginOnRequest) {
                    callback?.onSuccess(true, null)
                } else {
                    channel.invokeMethod("onLoginRequested", null)
                    callback?.onSuccess(false, null)
                }
            }
        }

        DJXSdk.init(application, configFileName, contentConfig)
        VerifierSp.saveSetting(disableVerifier)

        if (args.boolean("startAdSdk", true)) {
            TTAdSdk.start(object : TTAdSdk.Callback {
                override fun success() {
                    startContentSdk(result)
                }

                override fun fail(code: Int, msg: String?) {
                    result.successOnMain(
                        mapOf(
                            "success" to false,
                            "code" to code,
                            "message" to (msg ?: "Pangolin ad SDK start failed."),
                        )
                    )
                }
            })
        } else {
            startContentSdk(result)
        }
    }

    private fun startContentSdk(result: Result) {
        DJXSdk.start(
            DJXSdk.StartListener { isSuccess, message, error ->
                result.successOnMain(
                    mapOf(
                        "success" to isSuccess,
                        "code" to error?.code,
                        "message" to (message ?: error?.msg),
                    )
                )
            }
        )
    }

    private fun getLoginSignString(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        val serverKey = args.string("serverKey")
        val uid = args.string("uid")
        if (serverKey.isNullOrBlank()) {
            result.errorOnMain("pangolin_invalid_server_key", "serverKey is required.", null)
            return
        }
        if (uid.isNullOrBlank()) {
            result.errorOnMain("pangolin_invalid_uid", "uid is required.", null)
            return
        }

        val nonce = args.string("nonce")?.takeIf { it.isNotBlank() }
            ?: UUID.randomUUID().toString().replace("-", "")
        val timestampSeconds = args.long(
            "timestampSeconds",
            System.currentTimeMillis() / 1000,
        )
        val params = mutableMapOf<String, String>()
        args.map("params").forEach { entry ->
            val value = entry.value ?: return@forEach
            params[entry.key.toString()] = value.toString()
        }
        params["ouid"] = uid

        val sign = DJXSdk.service().getSignString(
            serverKey,
            nonce,
            timestampSeconds,
            params,
        )
        result.successOnMain(
            mapOf(
                "sign" to sign,
                "nonce" to nonce,
                "timestampSeconds" to timestampSeconds,
                "params" to params,
            ),
        )
    }

    private fun login(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val sign = call.argumentsMap().string("sign")
        if (sign.isNullOrBlank()) {
            result.errorOnMain("pangolin_invalid_sign", "sign is required.", null)
            return
        }
        DJXSdk.service().login(
            sign,
            object : IDJXService.IDJXCallback<DJXUser> {
                override fun onSuccess(data: DJXUser?, others: DJXOthers?) {
                    result.successOnMain(anyToMap(data))
                }

                override fun onError(error: DJXError) {
                    result.errorOnMain("pangolin_login_failed", error.msg, error.code)
                }
            },
        )
    }

    private fun logout(result: Result) {
        if (!requireStarted(result)) return
        DJXSdk.service().logout(
            object : IDJXService.IDJXCallback<DJXUser> {
                override fun onSuccess(data: DJXUser?, others: DJXOthers?) {
                    result.successOnMain(anyToMap(data))
                }

                override fun onError(error: DJXError) {
                    result.errorOnMain("pangolin_logout_failed", error.msg, error.code)
                }
            },
        )
    }

    private fun requestAllDramas(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        DJXSdk.service().requestAllDrama(
            args.int("page", 1),
            args.int("pageSize", 20),
            args.boolean("orderByHot", false),
            dramaListCallback(result),
        )
    }

    private fun requestRecommendedDramas(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        DJXSdk.service().requestAllDramaByRecommend(
            args.int("page", 1),
            args.int("pageSize", 20),
            dramaListCallback(result),
        )
    }

    private fun requestDramasByIds(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val ids = call.argumentsMap().list("ids").mapNotNull { it.asLongOrNull() }
        DJXSdk.service().requestDrama(ids, dramaListCallback(result))
    }

    private fun requestDramasByCategory(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        DJXSdk.service().requestDramaByCategory(
            args.string("category") ?: "",
            args.int("page", 1),
            args.int("pageSize", 20),
            args.int("order", 1),
            dramaListCallback(result),
        )
    }

    private fun searchDramas(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        DJXSdk.service().searchDrama(
            args.string("query") ?: "",
            args.boolean("fuzzy", true),
            args.int("page", 1),
            args.int("pageSize", 20),
            dramaListCallback(result),
        )
    }

    private fun requestDramaCategories(result: Result) {
        if (!requireStarted(result)) return
        DJXSdk.service().requestDramaCategoryList(
            object : IDJXService.IDJXCallback<MutableList<String>?> {
                override fun onSuccess(data: MutableList<String>?, others: DJXOthers?) {
                    result.successOnMain(data ?: emptyList<String>())
                }

                override fun onError(error: DJXError) {
                    result.errorOnMain("pangolin_request_failed", error.msg, error.code)
                }
            }
        )
    }

    private fun getDramaHistory(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        DJXSdk.service().getDramaHistory(
            args.int("offset", 0),
            args.int("count", 0),
            dramaListCallback(result),
        )
    }

    private fun getFavorList(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        DJXSdk.service().getFavorList(
            args.int("offset", 0),
            args.int("count", 0),
            dramaListCallback(result),
        )
    }

    private fun clearDramaHistory(result: Result) {
        if (!requireStarted(result)) return
        DJXSdk.service().clearDramaHistory(
            object : IDJXService.IDJXCallback<MutableList<out DJXDrama>?> {
                override fun onSuccess(data: MutableList<out DJXDrama>?, others: DJXOthers?) {
                    result.successOnMain(null)
                }

                override fun onError(error: DJXError) {
                    result.errorOnMain("pangolin_request_failed", error.msg, error.code)
                }
            }
        )
    }

    private fun verifyDramaParams(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val args = call.argumentsMap()
        DJXSdk.service().verifyDramaParams(
            args.int("total", 0),
            args.int("freeSet", 0),
            args.int("lockSet", 0),
            object : IDJXService.IDJXCallback<DJXLock> {
                override fun onSuccess(data: DJXLock?, others: DJXOthers?) {
                    result.successOnMain(anyToMap(data))
                }

                override fun onError(error: DJXError) {
                    result.errorOnMain("pangolin_request_failed", error.msg, error.code)
                }
            }
        )
    }

    private fun openDramaDetail(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val currentActivity = activity
        if (currentActivity == null) {
            result.errorOnMain("pangolin_no_activity", "No Android Activity is attached.", null)
            return
        }

        val args = call.argumentsMap()
        val dramaId = args.long("dramaId", 0L)
        val options = args.map("options")
        DJXSdk.service().requestDrama(
            listOf(dramaId),
            object : IDJXService.IDJXCallback<MutableList<out DJXDrama>?> {
                override fun onSuccess(data: MutableList<out DJXDrama>?, others: DJXOthers?) {
                    val drama = data?.firstOrNull()
                    if (drama == null) {
                        result.errorOnMain(
                            "pangolin_drama_not_found",
                            "Drama not found for id $dramaId.",
                            null,
                        )
                        return
                    }
                    drama.index = options.int("index", 1)
                    PangolinDramaDetailActivity.pendingDrama = drama
                    val intent = Intent(currentActivity, PangolinDramaDetailActivity::class.java)
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_FREE_SET, options.int("freeSet", 5))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_LOCK_SET, options.int("lockSet", 2))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_PLAY_DURATION_SECONDS, options.int("playDurationSeconds", 0))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_FROM_GID, options.long("fromGid", -1L))
                    intent.putExtra(
                        PangolinDramaDetailActivity.EXTRA_ENTER_FROM,
                        options.string("enterFrom") ?: PangolinDramaDetailActivity.ENTER_FROM_DEFAULT,
                    )
                    intent.putOptionalStringExtra(
                        PangolinDramaDetailActivity.EXTRA_UNLOCK_AD_MODE,
                        options["unlockAdMode"],
                    )
                    val recMap = options.primitiveMap("recMap")
                    if (recMap.isNotEmpty()) {
                        intent.putExtra(PangolinDramaDetailActivity.EXTRA_REC_MAP, recMap)
                    }
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_ENABLE_INFINITE_SCROLL, options.boolean("enableInfiniteScroll", true))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_ENABLE_CONTINUOUS_UNLOCK, options.boolean("enableContinuousUnlock", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_USE_CUSTOM_REWARD_AD, options.boolean("useCustomRewardAd", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_BACK, options.boolean("hideBack", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_TOP_INFO, options.boolean("hideTopInfo", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_BOTTOM_INFO, options.boolean("hideBottomInfo", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_LIKE_BUTTON, options.boolean("hideLikeButton", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_FAVOR_BUTTON, options.boolean("hideFavorButton", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_MORE, options.boolean("hideMore", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_REWARD_DIALOG, options.boolean("hideRewardDialog", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_CELLULAR_TOAST, options.boolean("hideCellularToast", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_DOUBLE_CLICK, options.boolean("hideDoubleClick", false))
                    intent.putExtra(PangolinDramaDetailActivity.EXTRA_HIDE_LONG_CLICK_SPEED, options.boolean("hideLongClickSpeed", false))
                    intent.putOptionalIntExtra(PangolinDramaDetailActivity.EXTRA_BOTTOM_OFFSET, options["bottomOffset"])
                    intent.putOptionalIntExtra(PangolinDramaDetailActivity.EXTRA_TOP_OFFSET, options["topOffset"])
                    intent.putOptionalIntExtra(
                        PangolinDramaDetailActivity.EXTRA_SCRIPT_TIPS_TOP_MARGIN,
                        options["scriptTipsTopMargin"],
                    )
                    intent.putOptionalIntExtra(
                        PangolinDramaDetailActivity.EXTRA_ICP_TIPS_BOTTOM_MARGIN,
                        options["icpTipsBottomMargin"],
                    )
                    currentActivity.startActivity(intent)
                    result.successOnMain(null)
                }

                override fun onError(error: DJXError) {
                    result.errorOnMain("pangolin_request_failed", error.msg, error.code)
                }
            },
        )
    }

    private fun openDramaDrawFeed(call: MethodCall, result: Result) {
        if (!requireStarted(result)) return
        val currentActivity = activity
        if (currentActivity == null) {
            result.errorOnMain("pangolin_no_activity", "No Android Activity is attached.", null)
            return
        }

        val options = call.argumentsMap().map("options")
        val intent = Intent(currentActivity, PangolinDramaDrawActivity::class.java)
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_CHANNEL_TYPE,
            options.string("channelType") ?: PangolinDramaDrawActivity.CHANNEL_RECOMMEND,
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_CONTENT_TYPE,
            options.string("contentType") ?: PangolinDramaDrawActivity.CONTENT_ONLY_DRAMA,
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_HIDE_LIKE_BUTTON,
            options.boolean("hideLikeButton", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_HIDE_FAVOR_BUTTON,
            options.boolean("hideFavorButton", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_HIDE_DRAMA_INFO,
            options.boolean("hideDramaInfo", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_HIDE_DRAMA_ENTER,
            options.boolean("hideDramaEnter", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_HIDE_CLOSE,
            options.boolean("hideClose", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_HIDE_DOUBLE_CLICK_LIKE,
            options.boolean("hideDoubleClickLike", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_HIDE_LONG_CLICK_SPEED,
            options.boolean("hideLongClickSpeed", false),
        )
        intent.putExtra(PangolinDramaDrawActivity.EXTRA_AD_OFFSET, options.int("adOffset", 0))
        intent.putExtra(PangolinDramaDrawActivity.EXTRA_DRAMA_FREE, options.int("dramaFree", 5))
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_FREE_SET,
            options.int("detailFreeSet", 5),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_LOCK_SET,
            options.int("detailLockSet", -1),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_ENABLE_CONTINUOUS_UNLOCK,
            options.boolean("enableContinuousUnlock", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_USE_CUSTOM_REWARD_AD,
            options.boolean("detailUseCustomRewardAd", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_BACK_REFRESH_ENABLED,
            options.boolean("backRefreshEnabled", true),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_BACK_REFRESH_INTERVAL_MILLIS,
            options.int("backRefreshIntervalMillis", 3000),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_FINISH_ON_BLOCKED_BACK,
            options.boolean("finishOnBlockedBack", false),
        )
        intent.putOptionalBooleanExtra(PangolinDramaDrawActivity.EXTRA_HIDE_CHANNEL_NAME, options["hideChannelName"])
        intent.putOptionalBooleanExtra(PangolinDramaDrawActivity.EXTRA_ENABLE_REFRESH, options["enableRefresh"])
        intent.putOptionalBooleanExtra(PangolinDramaDrawActivity.EXTRA_SHOW_GUIDE, options["showGuide"])
        intent.putOptionalStringExtra(PangolinDramaDrawActivity.EXTRA_PROGRESS_BAR_STYLE, options["progressBarStyle"])
        intent.putOptionalStringExtra(PangolinDramaDrawActivity.EXTRA_AD_CODE_ID, options["adCodeId"])
        intent.putOptionalStringExtra(PangolinDramaDrawActivity.EXTRA_NATIVE_AD_CODE_ID, options["nativeAdCodeId"])
        intent.putOptionalStringExtra(PangolinDramaDrawActivity.EXTRA_CUSTOM_CATEGORY, options["customCategory"])
        intent.putOptionalIntExtra(PangolinDramaDrawActivity.EXTRA_BOTTOM_OFFSET, options["bottomOffset"])
        intent.putOptionalIntExtra(PangolinDramaDrawActivity.EXTRA_REPORT_TOP_PADDING, options["reportTopPadding"])
        intent.putOptionalIntExtra(PangolinDramaDrawActivity.EXTRA_TITLE_LEFT_MARGIN, options["titleLeftMargin"])
        intent.putOptionalIntExtra(PangolinDramaDrawActivity.EXTRA_TITLE_RIGHT_MARGIN, options["titleRightMargin"])
        intent.putOptionalIntExtra(PangolinDramaDrawActivity.EXTRA_TITLE_TOP_MARGIN, options["titleTopMargin"])
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_BACK,
            options.boolean("detailHideBack", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_TOP_INFO,
            options.boolean("detailHideTopInfo", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_BOTTOM_INFO,
            options.boolean("detailHideBottomInfo", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_REWARD_DIALOG,
            options.boolean("detailHideRewardDialog", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_MORE,
            options.boolean("detailHideMore", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_CELLULAR_TOAST,
            options.boolean("detailHideCellularToast", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_INFINITE_SCROLL_ENABLED,
            options.boolean("detailInfiniteScrollEnabled", true),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_LIKE_BUTTON,
            options.boolean("detailHideLikeButton", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_FAVOR_BUTTON,
            options.boolean("detailHideFavorButton", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_DOUBLE_CLICK,
            options.boolean("detailHideDoubleClick", false),
        )
        intent.putExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_HIDE_LONG_CLICK_SPEED,
            options.boolean("detailHideLongClickSpeed", false),
        )
        intent.putOptionalIntExtra(PangolinDramaDrawActivity.EXTRA_DETAIL_BOTTOM_OFFSET, options["detailBottomOffset"])
        intent.putOptionalIntExtra(PangolinDramaDrawActivity.EXTRA_DETAIL_TOP_OFFSET, options["detailTopOffset"])
        intent.putOptionalIntExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_SCRIPT_TIPS_TOP_MARGIN,
            options["detailScriptTipsTopMargin"],
        )
        intent.putOptionalIntExtra(
            PangolinDramaDrawActivity.EXTRA_DETAIL_ICP_TIPS_BOTTOM_MARGIN,
            options["detailIcpTipsBottomMargin"],
        )
        intent.putOptionalLongExtra(PangolinDramaDrawActivity.EXTRA_TOP_DRAMA_ID, options["topDramaId"])

        currentActivity.startActivity(intent)
        result.successOnMain(null)
    }

    private fun dramaListCallback(result: Result): IDJXService.IDJXCallback<MutableList<out DJXDrama>?> {
        return object : IDJXService.IDJXCallback<MutableList<out DJXDrama>?> {
            override fun onSuccess(data: MutableList<out DJXDrama>?, others: DJXOthers?) {
                result.successOnMain((data ?: emptyList()).map(::dramaToMap))
            }

            override fun onError(error: DJXError) {
                result.errorOnMain("pangolin_request_failed", error.msg, error.code)
            }
        }
    }

    private fun requireStarted(result: Result): Boolean {
        if (!DJXSdk.isStartSuccess()) {
            result.errorOnMain(
                "pangolin_not_started",
                "Pangolin Content SDK has not started. Call initialize() first.",
                null,
            )
            return false
        }
        return true
    }

    private fun readSdkSettingJson(
        configFileName: String,
        configFilePath: String?,
    ): JSONObject {
        val raw = if (configFilePath != null) {
            File(configFilePath).readText(Charsets.UTF_8)
        } else {
            application.assets.open(configFileName).bufferedReader().use { it.readText() }
        }
        return JSONObject(raw)
    }

    private fun validateSdkSettingJson(
        json: JSONObject,
        appId: String,
        adAppId: String,
    ): String? {
        val init = json.optJSONObject("init")
            ?: return "SDK 配置文件缺少 init 节点，请重新下载配置文件。"
        val configAppId = init.optString("app_id")
        val configSiteId = init.optString("site_id")
        if (configAppId.isNotBlank() && configAppId != appId) {
            return "SDK 配置文件中的 AppLog AppID 是 $configAppId，但当前填写的是 $appId。请使用同一个应用生成的配置文件。"
        }
        if (configSiteId.isNotBlank() && configSiteId != adAppId) {
            return "SDK 配置文件中的广告/媒体 ID 是 $configSiteId，但当前填写的是 $adAppId。请使用同一个应用生成的配置文件。"
        }

        if (!json.has("license_config") || json.isNull("license_config")) {
            return "SDK 配置文件缺少 license_config。请先在穿山甲后台为包名 ${application.packageName} 完成包名录入，然后重新下载 SDK 参数配置文件。"
        }

        val licenseConfig = json.opt("license_config")
        if (licenseConfig !is JSONArray || licenseConfig.length() == 0) {
            return "SDK 配置文件的 license_config 为空或格式异常。请重新下载包含 license_config 的 SDK 参数配置文件。"
        }

        val packageNames = (0 until licenseConfig.length()).mapNotNull { index ->
            licenseConfig.optJSONObject(index)?.let { item ->
                item.optString("PackageName").ifBlank {
                    item.optString("PakageName")
                }.takeIf { it.isNotBlank() }
            }
        }
        if (packageNames.isNotEmpty() && application.packageName !in packageNames) {
            return "SDK 配置文件 license_config 的包名是 ${packageNames.joinToString()}，当前包名是 ${application.packageName}。请重新录入当前包名并下载配置文件。"
        }
        return null
    }

    private fun preloadDynamicSettings(json: JSONObject): String? {
        return try {
            val model = DynamicApi.parseModel(json)
                ?: return "SDK 配置文件解析失败，请重新下载配置文件。"
            checkDynamicLicense(model)
            DynamicManager.getInstance().setDynamicModel(model)
            null
        } catch (error: Throwable) {
            "SDK 配置文件预加载失败：${error.message.orEmpty()}"
        }
    }

    private fun checkDynamicLicense(model: DynamicModel) {
        val presenterClass = Class.forName("com.bytedance.sdk.djx.base.dynamic.DynamicPresenter")
        val instance = presenterClass.getDeclaredMethod("getInstance").apply {
            isAccessible = true
        }.invoke(null)
        presenterClass.getDeclaredMethod(
            "checkLicense",
            DynamicModel::class.java,
        ).apply {
            isAccessible = true
        }.invoke(instance, model)
    }

    private fun recommendedPermissionStatus(): Map<String, Boolean> {
        val status = runtimeRecommendedPermissions()
            .associateWith(::isPermissionGranted)
            .toMutableMap()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            status[Manifest.permission.REQUEST_INSTALL_PACKAGES] =
                application.packageManager.canRequestPackageInstalls()
        }
        return status
    }

    private fun runtimeRecommendedPermissions(): List<String> {
        val permissions = mutableListOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )
        if (Build.VERSION.SDK_INT <= 32) {
            permissions += Manifest.permission.READ_EXTERNAL_STORAGE
        }
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            permissions += Manifest.permission.WRITE_EXTERNAL_STORAGE
        }
        return permissions.distinct()
    }

    private fun isPermissionGranted(permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            application.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun dramaToMap(drama: DJXDrama): Map<String, Any?> {
        val map = anyToMap(drama).toMutableMap()
        map["id"] = drama.id
        map["index"] = drama.index
        map["title"] = drama.title
        map["total"] = drama.total
        map["coverUrl"] = dramaCoverUrl(drama)
        map["coverImages"] = drama.coverImages2?.map {
            mapOf(
                "url" to it.url,
                "backupUrl" to it.backupUrl,
                "definition" to it.definition,
            )
        }
        map["rawString"] = drama.toString()
        return map
    }

    private fun dramaCoverUrl(drama: DJXDrama): String? {
        drama.coverImage?.takeIf { it.isNotBlank() }?.let { return it }
        return drama.coverImages2
            ?.asSequence()
            ?.mapNotNull { image ->
                image.url?.takeIf { it.isNotBlank() }
                    ?: image.backupUrl?.takeIf { it.isNotBlank() }
            }
            ?.firstOrNull()
    }

    private fun anyToMap(value: Any?): Map<String, Any?> {
        if (value == null) {
            return emptyMap()
        }
        val map = mutableMapOf<String, Any?>("raw" to value.toString())
        var clazz: Class<*>? = value.javaClass
        while (clazz != null && clazz != Any::class.java) {
            clazz.declaredFields.forEach { field ->
                if (Modifier.isStatic(field.modifiers)) return@forEach
                try {
                    field.isAccessible = true
                    val fieldValue = field.get(value)
                    if (fieldValue == null || fieldValue is String || fieldValue is Number || fieldValue is Boolean) {
                        map[field.name] = fieldValue
                    }
                } catch (_: Throwable) {
                    // Ignore SDK internals that are not safe to reflect.
                }
            }
            clazz = clazz.superclass
        }
        return map
    }

    private fun MethodCall.argumentsMap(): Map<*, *> {
        return arguments as? Map<*, *> ?: emptyMap<String, Any?>()
    }

    @Suppress("DEPRECATION")
    private fun readManifestString(key: String): String? {
        return try {
            val info = application.packageManager.getApplicationInfo(
                application.packageName,
                PackageManager.GET_META_DATA,
            )
            info.metaData?.getString(key)
        } catch (_: Throwable) {
            null
        }
    }

    private fun Map<*, *>.map(key: String): Map<*, *> {
        return this[key] as? Map<*, *> ?: emptyMap<String, Any?>()
    }

    private fun Map<*, *>.list(key: String): List<*> {
        return this[key] as? List<*> ?: emptyList<Any?>()
    }

    private fun Map<*, *>.primitiveMap(key: String): HashMap<String, Any> {
        val raw = this[key] as? Map<*, *> ?: return hashMapOf()
        val result = hashMapOf<String, Any>()
        raw.forEach { entry ->
            val value = entry.value
            if (value == null || value is String || value is Number || value is Boolean) {
                result[entry.key.toString()] = value ?: ""
            }
        }
        return result
    }

    private fun Map<*, *>.string(key: String): String? {
        return this[key] as? String
    }

    private fun Map<*, *>.boolean(key: String, defaultValue: Boolean): Boolean {
        return this[key] as? Boolean ?: defaultValue
    }

    private fun Map<*, *>.int(key: String, defaultValue: Int): Int {
        return this[key].asIntOrNull() ?: defaultValue
    }

    private fun Map<*, *>.long(key: String, defaultValue: Long): Long {
        return this[key].asLongOrNull() ?: defaultValue
    }

    private fun Any?.asIntOrNull(): Int? {
        return when (this) {
            is Int -> this
            is Long -> toInt()
            is Number -> toInt()
            is String -> toIntOrNull()
            else -> null
        }
    }

    private fun Any?.asLongOrNull(): Long? {
        return when (this) {
            is Long -> this
            is Int -> toLong()
            is Number -> toLong()
            is String -> toLongOrNull()
            else -> null
        }
    }

    private fun Intent.putOptionalBooleanExtra(name: String, value: Any?) {
        if (value is Boolean) {
            putExtra(name, value)
        }
    }

    private fun Intent.putOptionalIntExtra(name: String, value: Any?) {
        value.asIntOrNull()?.let { putExtra(name, it) }
    }

    private fun Intent.putOptionalLongExtra(name: String, value: Any?) {
        value.asLongOrNull()?.let { putExtra(name, it) }
    }

    private fun Intent.putOptionalStringExtra(name: String, value: Any?) {
        if (value is String) {
            putExtra(name, value)
        }
    }

    private fun Result.successOnMain(value: Any?) {
        mainHandler.post { success(value) }
    }

    private fun Result.errorOnMain(code: String, message: String?, details: Any?) {
        mainHandler.post { error(code, message, details) }
    }

    private companion object {
        const val PERMISSION_REQUEST_CODE = 54681
        const val CONFIG_VALIDATION_ERROR_CODE = -54681
    }
}
