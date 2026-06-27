package com.owxo.pangolin_content_sdk

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.ContextWrapper
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import com.bytedance.sdk.djx.DJXSdk
import com.bytedance.sdk.djx.IDJXWidget
import com.bytedance.sdk.djx.interfaces.listener.IDJXDrawListener
import com.bytedance.sdk.djx.interfaces.listener.IDJXDramaUnlockListener
import com.bytedance.sdk.djx.model.DJXDrama
import com.bytedance.sdk.djx.model.DJXDramaDetailConfig
import com.bytedance.sdk.djx.model.DJXDramaUnlockAdMode
import com.bytedance.sdk.djx.model.DJXDramaUnlockInfo
import com.bytedance.sdk.djx.model.DJXDramaUnlockMethod
import com.bytedance.sdk.djx.model.DJXUnlockModeType
import com.bytedance.sdk.djx.params.DJXWidgetDrawParams
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PangolinDramaDrawPlatformViewFactory(
    private val activityProvider: () -> Activity?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return PangolinDramaDrawPlatformView(
            context = context,
            viewId = viewId,
            options = args as? Map<*, *> ?: emptyMap<String, Any?>(),
            activityProvider = activityProvider,
        )
    }
}

internal object PangolinDramaDrawPlatformViewRegistry {
    private val views = linkedSetOf<PangolinDramaDrawPlatformView>()

    fun register(view: PangolinDramaDrawPlatformView) {
        views.add(view)
    }

    fun unregister(view: PangolinDramaDrawPlatformView) {
        views.remove(view)
    }

    fun pauseAll() {
        views.toList().forEach { it.setPlaybackPaused(true) }
    }

    fun resumeAll() {
        views.toList().forEach { it.setPlaybackPaused(false) }
    }
}

internal class PangolinDramaDrawPlatformView(
    context: Context,
    viewId: Int,
    private val options: Map<*, *>,
    private val activityProvider: () -> Activity?,
) : PlatformView {
    private val tag = "pangolin_content_sdk_draw_$viewId"
    private val container = FrameLayout(context).apply {
        id = View.generateViewId()
        setBackgroundColor(android.graphics.Color.BLACK)
    }
    private var widget: IDJXWidget? = null
    private var playbackPaused = false

    init {
        val fragmentActivity = activityProvider() as? FragmentActivity
        if (fragmentActivity == null) {
            showMessage(context, "宿主 Activity 不支持内容推荐组件")
        } else if (!DJXSdk.isStartSuccess()) {
            showMessage(context, "内容推荐初始化中")
        } else {
            widget = DJXSdk.factory().createDraw(buildDrawParams(fragmentActivity))
            fragmentActivity.supportFragmentManager.beginTransaction()
                .replace(container.id, widget!!.fragment, tag)
                .commitAllowingStateLoss()
        }
        PangolinDramaDrawPlatformViewRegistry.register(this)
    }

    override fun getView(): View = container

    override fun dispose() {
        PangolinDramaDrawPlatformViewRegistry.unregister(this)
        val fragmentActivity = activityProvider() as? FragmentActivity
        val fragment = fragmentActivity?.supportFragmentManager?.findFragmentByTag(tag)
        if (fragment != null) {
            fragmentActivity.supportFragmentManager.beginTransaction()
                .remove(fragment)
                .commitAllowingStateLoss()
        }
        widget?.destroy()
        widget = null
    }

    internal fun setPlaybackPaused(paused: Boolean) {
        if (playbackPaused == paused) {
            return
        }
        playbackPaused = paused
        applyPlaybackLifecycle()
    }

    private fun applyPlaybackLifecycle() {
        val fragmentActivity = activityProvider() as? FragmentActivity ?: return
        val fragment = fragmentActivity.supportFragmentManager.findFragmentByTag(tag) ?: return
        if (fragment.lifecycle.currentState == Lifecycle.State.DESTROYED) {
            return
        }
        val maxState = if (playbackPaused) Lifecycle.State.STARTED else Lifecycle.State.RESUMED
        try {
            fragmentActivity.supportFragmentManager.beginTransaction()
                .setMaxLifecycle(fragment, maxState)
                .commitAllowingStateLoss()
        } catch (_: Throwable) {
            // The SDK fragment can be between attach/remove states during fast tab switches.
        }
    }

    private fun showMessage(context: Context, message: String) {
        container.addView(
            TextView(context).apply {
                text = message
                setTextColor(android.graphics.Color.WHITE)
                textSize = 16f
                gravity = android.view.Gravity.CENTER
            },
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    private fun buildDrawParams(activity: FragmentActivity): DJXWidgetDrawParams {
        val channelType = channelType()
        return DJXWidgetDrawParams.obtain().apply {
            adOffset(options.int("adOffset", 0))
            drawContentType(contentType())
            drawChannelType(channelType)
            hideChannelName(
                options.booleanOrNull("hideChannelName")
                    ?: (channelType == DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_RECOMMEND),
            )
            hideLikeButton(options.boolean("hideLikeButton", false))
            hideFavorButton(options.boolean("hideFavorButton", false))
            hideDramaInfo(options.boolean("hideDramaInfo", false))
            hideDramaEnter(options.boolean("hideDramaEnter", false))
            hideDoubleClickLike(options.boolean("hideDoubleClickLike", false))
            hideLongClickSpeed(options.boolean("hideLongClickSpeed", false))
            hideClose(options.boolean("hideClose", true), View.OnClickListener {})
            dramaFree(options.int("dramaFree", 5))
            topDramaId(options.long("topDramaId", -1L))
            detailConfig(buildDetailConfig(activity))
            listener(object : IDJXDrawListener() {})

            options.booleanOrNull("enableRefresh")?.let { enableRefresh(it) }
            options.booleanOrNull("showGuide")?.let { showGuide(it) }
            options.string("progressBarStyle")?.let { progressBarStyle(progressBarStyle(it)) }
            options.string("adCodeId")?.takeIf { it.isNotBlank() }?.let { adCodeId(it) }
            options.string("nativeAdCodeId")?.takeIf { it.isNotBlank() }?.let { nativeAdCodeId(it) }
            options.string("customCategory")?.takeIf { it.isNotBlank() }?.let { customCategory(it) }
            options.intOrNull("bottomOffset")?.let { bottomOffset(it) }
            options.intOrNull("reportTopPadding")?.let { reportTopPadding(it.toFloat()) }
            options.intOrNull("titleLeftMargin")?.let { titleLeftMargin(it) }
            options.intOrNull("titleRightMargin")?.let { titleRightMargin(it) }
            options.intOrNull("titleTopMargin")?.let { titleTopMargin(it) }
        }
    }

    private fun buildDetailConfig(activity: FragmentActivity): DJXDramaDetailConfig {
        val lockSet = options.int("detailLockSet", -1)
        val enableContinuousUnlock = options.boolean("enableContinuousUnlock", false)
        val useCustomRewardAd = options.boolean("detailUseCustomRewardAd", false)
        val unlockListener = buildUnlockListener(
            activity = activity,
            lockSet = lockSet,
            enableContinuousUnlock = enableContinuousUnlock,
            useCustomRewardAd = useCustomRewardAd,
        )
        return DJXDramaDetailConfig.obtain(
            if (useCustomRewardAd) {
                DJXDramaUnlockAdMode.MODE_SPECIFIC
            } else {
                DJXDramaUnlockAdMode.MODE_COMMON
            },
            options.int("detailFreeSet", 5),
            unlockListener,
        ).apply {
            hideBack(options.boolean("detailHideBack", false), View.OnClickListener { view ->
                handleDetailBack(activity, view)
            })
            hideTopInfo(options.boolean("detailHideTopInfo", false))
            hideBottomInfo(options.boolean("detailHideBottomInfo", false))
            hideRewardDialog(useCustomRewardAd || options.boolean("detailHideRewardDialog", false))
            hideMore(options.boolean("detailHideMore", false))
            hideCellularToast(options.boolean("detailHideCellularToast", false))
            infiniteScrollEnabled(options.boolean("detailInfiniteScrollEnabled", true))
            hideLikeButton(options.boolean("detailHideLikeButton", false))
            hideFavorButton(options.boolean("detailHideFavorButton", false))
            hideDoubleClick(options.boolean("detailHideDoubleClick", false))
            hideLongClickSpeed(options.boolean("detailHideLongClickSpeed", false))
            options.intOrNull("detailBottomOffset")?.let { setBottomOffset(it) }
            options.intOrNull("detailTopOffset")?.let { setTopOffset(it) }
            options.intOrNull("detailScriptTipsTopMargin")?.let { setScriptTipsTopMargin(it) }
            options.intOrNull("detailIcpTipsBottomMargin")?.let { setIcpTipsBottomMargin(it) }
        }
    }

    private fun handleDetailBack(activity: FragmentActivity, view: View) {
        val sourceActivity = view.ownerActivity()
        if (sourceActivity != null && sourceActivity !== activity) {
            sourceActivity.finish()
            return
        }
        val currentWidget = widget
        if (currentWidget == null) {
            if (options.boolean("finishOnBlockedBack", false)) {
                activity.finish()
            }
            return
        }
        currentWidget.backRefresh()
    }

    private fun buildUnlockListener(
        activity: FragmentActivity,
        lockSet: Int,
        enableContinuousUnlock: Boolean,
        useCustomRewardAd: Boolean,
    ): IDJXDramaUnlockListener {
        if (useCustomRewardAd) {
            return object : IDJXDramaUnlockListener {
                override fun unlockFlowStart(
                    drama: DJXDrama,
                    callback: IDJXDramaUnlockListener.UnlockCallback,
                    map: Map<String, Any>?,
                ) {
                    showUnlockDialog(activity, drama, callback, lockSet, enableContinuousUnlock)
                }

                override fun unlockFlowEnd(
                    drama: DJXDrama,
                    errCode: IDJXDramaUnlockListener.UnlockErrorStatus?,
                    map: Map<String, Any>?,
                ) = Unit

                override fun showCustomAd(
                    drama: DJXDrama,
                    callback: IDJXDramaUnlockListener.CustomAdCallback,
                ) {
                    PangolinRewardAdBridge.requestRewardAd(
                        "draw_detail",
                        drama,
                        callback,
                        activityProvider() ?: container.context,
                    )
                }
            }
        }

        return object : IDJXDramaUnlockListener {
            override fun unlockFlowStart(
                drama: DJXDrama,
                callback: IDJXDramaUnlockListener.UnlockCallback,
                map: Map<String, Any>?,
            ) {
                showUnlockDialog(activity, drama, callback, lockSet, enableContinuousUnlock)
            }

            override fun unlockFlowEnd(
                drama: DJXDrama,
                errCode: IDJXDramaUnlockListener.UnlockErrorStatus?,
                map: Map<String, Any>?,
            ) = Unit
        }
    }

    private fun showUnlockDialog(
        activity: FragmentActivity,
        drama: DJXDrama,
        callback: IDJXDramaUnlockListener.UnlockCallback,
        lockSet: Int,
        enableContinuousUnlock: Boolean,
    ) {
        val unlockType =
            if (enableContinuousUnlock) DJXUnlockModeType.UNLOCKTYPE_CONTINUES else DJXUnlockModeType.UNLOCKTYPE_DEFAULT
        AlertDialog.Builder(activity)
            .setMessage("观看激励广告后继续观看")
            .setPositiveButton("观看广告") { _, _ ->
                callback.onConfirm(
                    DJXDramaUnlockInfo(
                        drama.id,
                        lockSet,
                        DJXDramaUnlockMethod.METHOD_AD,
                        false,
                        unlockType = unlockType,
                    ),
                )
            }
            .setNegativeButton("取消") { _, _ ->
                callback.onConfirm(
                    DJXDramaUnlockInfo(
                        drama.id,
                        lockSet,
                        DJXDramaUnlockMethod.METHOD_AD,
                        cancelUnlock = true,
                    ),
                )
            }
            .show()
    }

    private fun channelType(): Int {
        return when (options.string("channelType")) {
            PangolinDramaDrawActivity.CHANNEL_THEATER ->
                DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_THEATER
            PangolinDramaDrawActivity.CHANNEL_RECOMMEND_THEATER ->
                DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_RECOMMEND_THEATER
            else -> DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_RECOMMEND
        }
    }

    private fun contentType(): Int {
        return when (options.string("contentType")) {
            PangolinDramaDrawActivity.CONTENT_ONLY_DRAMA ->
                DJXWidgetDrawParams.DRAW_CONTENT_TYPE_ONLY_DRAMA
            else -> DJXWidgetDrawParams.DRAW_CONTENT_TYPE_ONLY_DRAMA
        }
    }

    private fun progressBarStyle(value: String): Int {
        return when (value) {
            PangolinDramaDrawActivity.PROGRESS_STYLE_DARK ->
                DJXWidgetDrawParams.PROGRESS_BAR_STYLE_DARK
            else -> DJXWidgetDrawParams.PROGRESS_BAR_STYLE_LIGHT
        }
    }
}

private fun Map<*, *>.string(key: String): String? = this[key] as? String

private fun Map<*, *>.boolean(key: String, default: Boolean): Boolean =
    booleanOrNull(key) ?: default

private fun Map<*, *>.booleanOrNull(key: String): Boolean? = this[key] as? Boolean

private fun View.ownerActivity(): Activity? {
    var currentContext = context
    while (currentContext is ContextWrapper) {
        if (currentContext is Activity) {
            return currentContext
        }
        currentContext = currentContext.baseContext
    }
    return currentContext as? Activity
}

private fun Map<*, *>.int(key: String, default: Int): Int =
    intOrNull(key) ?: default

private fun Map<*, *>.intOrNull(key: String): Int? {
    return when (val value = this[key]) {
        is Int -> value
        is Number -> value.toInt()
        is String -> value.toIntOrNull()
        else -> null
    }
}

private fun Map<*, *>.long(key: String, default: Long): Long {
    return when (val value = this[key]) {
        is Long -> value
        is Number -> value.toLong()
        is String -> value.toLongOrNull()
        else -> null
    } ?: default
}
