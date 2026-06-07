package com.owxo.pangolin_content_sdk

import android.app.AlertDialog
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
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

class PangolinDramaDrawActivity : FragmentActivity() {
    companion object {
        const val EXTRA_CHANNEL_TYPE = "pangolin_draw_channel_type"
        const val EXTRA_CONTENT_TYPE = "pangolin_draw_content_type"
        const val EXTRA_HIDE_CHANNEL_NAME = "pangolin_draw_hide_channel_name"
        const val EXTRA_HIDE_LIKE_BUTTON = "pangolin_draw_hide_like_button"
        const val EXTRA_HIDE_FAVOR_BUTTON = "pangolin_draw_hide_favor_button"
        const val EXTRA_HIDE_DRAMA_INFO = "pangolin_draw_hide_drama_info"
        const val EXTRA_HIDE_DRAMA_ENTER = "pangolin_draw_hide_drama_enter"
        const val EXTRA_HIDE_CLOSE = "pangolin_draw_hide_close"
        const val EXTRA_HIDE_DOUBLE_CLICK_LIKE = "pangolin_draw_hide_double_click_like"
        const val EXTRA_HIDE_LONG_CLICK_SPEED = "pangolin_draw_hide_long_click_speed"
        const val EXTRA_ENABLE_REFRESH = "pangolin_draw_enable_refresh"
        const val EXTRA_SHOW_GUIDE = "pangolin_draw_show_guide"
        const val EXTRA_PROGRESS_BAR_STYLE = "pangolin_draw_progress_bar_style"
        const val EXTRA_AD_CODE_ID = "pangolin_draw_ad_code_id"
        const val EXTRA_NATIVE_AD_CODE_ID = "pangolin_draw_native_ad_code_id"
        const val EXTRA_CUSTOM_CATEGORY = "pangolin_draw_custom_category"
        const val EXTRA_AD_OFFSET = "pangolin_draw_ad_offset"
        const val EXTRA_BOTTOM_OFFSET = "pangolin_draw_bottom_offset"
        const val EXTRA_REPORT_TOP_PADDING = "pangolin_draw_report_top_padding"
        const val EXTRA_TITLE_LEFT_MARGIN = "pangolin_draw_title_left_margin"
        const val EXTRA_TITLE_RIGHT_MARGIN = "pangolin_draw_title_right_margin"
        const val EXTRA_TITLE_TOP_MARGIN = "pangolin_draw_title_top_margin"
        const val EXTRA_DRAMA_FREE = "pangolin_draw_drama_free"
        const val EXTRA_DETAIL_FREE_SET = "pangolin_draw_detail_free_set"
        const val EXTRA_DETAIL_LOCK_SET = "pangolin_draw_detail_lock_set"
        const val EXTRA_DETAIL_HIDE_BACK = "pangolin_draw_detail_hide_back"
        const val EXTRA_DETAIL_HIDE_TOP_INFO = "pangolin_draw_detail_hide_top_info"
        const val EXTRA_DETAIL_HIDE_BOTTOM_INFO = "pangolin_draw_detail_hide_bottom_info"
        const val EXTRA_DETAIL_HIDE_REWARD_DIALOG = "pangolin_draw_detail_hide_reward_dialog"
        const val EXTRA_DETAIL_HIDE_MORE = "pangolin_draw_detail_hide_more"
        const val EXTRA_DETAIL_HIDE_CELLULAR_TOAST = "pangolin_draw_detail_hide_cellular_toast"
        const val EXTRA_DETAIL_INFINITE_SCROLL_ENABLED = "pangolin_draw_detail_infinite_scroll_enabled"
        const val EXTRA_DETAIL_HIDE_LIKE_BUTTON = "pangolin_draw_detail_hide_like_button"
        const val EXTRA_DETAIL_HIDE_FAVOR_BUTTON = "pangolin_draw_detail_hide_favor_button"
        const val EXTRA_DETAIL_HIDE_DOUBLE_CLICK = "pangolin_draw_detail_hide_double_click"
        const val EXTRA_DETAIL_HIDE_LONG_CLICK_SPEED = "pangolin_draw_detail_hide_long_click_speed"
        const val EXTRA_DETAIL_BOTTOM_OFFSET = "pangolin_draw_detail_bottom_offset"
        const val EXTRA_DETAIL_TOP_OFFSET = "pangolin_draw_detail_top_offset"
        const val EXTRA_DETAIL_SCRIPT_TIPS_TOP_MARGIN = "pangolin_draw_detail_script_tips_top_margin"
        const val EXTRA_DETAIL_ICP_TIPS_BOTTOM_MARGIN = "pangolin_draw_detail_icp_tips_bottom_margin"
        const val EXTRA_TOP_DRAMA_ID = "pangolin_draw_top_drama_id"
        const val EXTRA_ENABLE_CONTINUOUS_UNLOCK = "pangolin_draw_enable_continuous_unlock"
        const val EXTRA_DETAIL_USE_CUSTOM_REWARD_AD = "pangolin_draw_detail_use_custom_reward_ad"
        const val EXTRA_BACK_REFRESH_ENABLED = "pangolin_draw_back_refresh_enabled"
        const val EXTRA_BACK_REFRESH_INTERVAL_MILLIS = "pangolin_draw_back_refresh_interval_millis"
        const val EXTRA_FINISH_ON_BLOCKED_BACK = "pangolin_draw_finish_on_blocked_back"

        const val CHANNEL_RECOMMEND = "recommend"
        const val CHANNEL_THEATER = "theater"
        const val CHANNEL_RECOMMEND_THEATER = "recommendTheater"
        const val CONTENT_ONLY_DRAMA = "onlyDrama"
        const val PROGRESS_STYLE_LIGHT = "light"
        const val PROGRESS_STYLE_DARK = "dark"
    }

    private var widget: IDJXWidget? = null
    private var lastBackTime: Long = -1L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!DJXSdk.isStartSuccess()) {
            finish()
            return
        }

        val container = FrameLayout(this)
        container.id = View.generateViewId()
        setContentView(
            container,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )

        widget = DJXSdk.factory().createDraw(buildDrawParams())
        supportFragmentManager.beginTransaction()
            .replace(container.id, widget!!.fragment)
            .commitAllowingStateLoss()
    }

    private fun buildDrawParams(): DJXWidgetDrawParams {
        val channelType = channelType()
        return DJXWidgetDrawParams.obtain().apply {
            adOffset(intent.getIntExtra(EXTRA_AD_OFFSET, 0))
            drawContentType(contentType())
            drawChannelType(channelType)
            hideChannelName(
                intent.booleanExtraOrDefault(
                    EXTRA_HIDE_CHANNEL_NAME,
                    channelType == DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_RECOMMEND,
                ),
            )
            hideLikeButton(intent.getBooleanExtra(EXTRA_HIDE_LIKE_BUTTON, false))
            hideFavorButton(intent.getBooleanExtra(EXTRA_HIDE_FAVOR_BUTTON, false))
            hideDramaInfo(intent.getBooleanExtra(EXTRA_HIDE_DRAMA_INFO, false))
            hideDramaEnter(intent.getBooleanExtra(EXTRA_HIDE_DRAMA_ENTER, false))
            hideDoubleClickLike(intent.getBooleanExtra(EXTRA_HIDE_DOUBLE_CLICK_LIKE, false))
            hideLongClickSpeed(intent.getBooleanExtra(EXTRA_HIDE_LONG_CLICK_SPEED, false))
            hideClose(
                intent.getBooleanExtra(EXTRA_HIDE_CLOSE, false),
                View.OnClickListener { finish() },
            )
            dramaFree(intent.getIntExtra(EXTRA_DRAMA_FREE, 5))
            topDramaId(intent.getLongExtra(EXTRA_TOP_DRAMA_ID, -1L))
            detailConfig(buildDetailConfig())
            listener(object : IDJXDrawListener() {})

            if (intent.hasExtra(EXTRA_ENABLE_REFRESH)) {
                enableRefresh(intent.getBooleanExtra(EXTRA_ENABLE_REFRESH, true))
            }
            if (intent.hasExtra(EXTRA_SHOW_GUIDE)) {
                showGuide(intent.getBooleanExtra(EXTRA_SHOW_GUIDE, true))
            }
            if (intent.hasExtra(EXTRA_PROGRESS_BAR_STYLE)) {
                progressBarStyle(progressBarStyle())
            }
            intent.getStringExtra(EXTRA_AD_CODE_ID)
                ?.takeIf { it.isNotBlank() }
                ?.let { adCodeId(it) }
            intent.getStringExtra(EXTRA_NATIVE_AD_CODE_ID)
                ?.takeIf { it.isNotBlank() }
                ?.let { nativeAdCodeId(it) }
            intent.getStringExtra(EXTRA_CUSTOM_CATEGORY)
                ?.takeIf { it.isNotBlank() }
                ?.let { customCategory(it) }
            if (intent.hasExtra(EXTRA_BOTTOM_OFFSET)) {
                bottomOffset(intent.getIntExtra(EXTRA_BOTTOM_OFFSET, 0))
            }
            if (intent.hasExtra(EXTRA_REPORT_TOP_PADDING)) {
                reportTopPadding(intent.getIntExtra(EXTRA_REPORT_TOP_PADDING, 0).toFloat())
            }
            if (intent.hasExtra(EXTRA_TITLE_LEFT_MARGIN)) {
                titleLeftMargin(intent.getIntExtra(EXTRA_TITLE_LEFT_MARGIN, 0))
            }
            if (intent.hasExtra(EXTRA_TITLE_RIGHT_MARGIN)) {
                titleRightMargin(intent.getIntExtra(EXTRA_TITLE_RIGHT_MARGIN, 0))
            }
            if (intent.hasExtra(EXTRA_TITLE_TOP_MARGIN)) {
                titleTopMargin(intent.getIntExtra(EXTRA_TITLE_TOP_MARGIN, 0))
            }
        }
    }

    private fun buildDetailConfig(): DJXDramaDetailConfig {
        val freeSet = intent.getIntExtra(EXTRA_DETAIL_FREE_SET, -1)
        val lockSet = intent.getIntExtra(EXTRA_DETAIL_LOCK_SET, -1)
        val enableContinuousUnlock = intent.getBooleanExtra(EXTRA_ENABLE_CONTINUOUS_UNLOCK, false)
        val unlockListener = buildUnlockListener(
            lockSet = lockSet,
            enableContinuousUnlock = enableContinuousUnlock,
            useCustomRewardAd = intent.getBooleanExtra(EXTRA_DETAIL_USE_CUSTOM_REWARD_AD, false),
        )
        return DJXDramaDetailConfig.obtain(
            DJXDramaUnlockAdMode.MODE_COMMON,
            freeSet,
            unlockListener,
        ).apply {
            hideBack(
                intent.getBooleanExtra(EXTRA_DETAIL_HIDE_BACK, false),
                View.OnClickListener { finish() },
            )
            hideTopInfo(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_TOP_INFO, false))
            hideBottomInfo(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_BOTTOM_INFO, false))
            hideRewardDialog(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_REWARD_DIALOG, false))
            hideMore(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_MORE, false))
            hideCellularToast(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_CELLULAR_TOAST, false))
            infiniteScrollEnabled(intent.getBooleanExtra(EXTRA_DETAIL_INFINITE_SCROLL_ENABLED, true))
            hideLikeButton(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_LIKE_BUTTON, false))
            hideFavorButton(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_FAVOR_BUTTON, false))
            hideDoubleClick(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_DOUBLE_CLICK, false))
            hideLongClickSpeed(intent.getBooleanExtra(EXTRA_DETAIL_HIDE_LONG_CLICK_SPEED, false))
            if (intent.hasExtra(EXTRA_DETAIL_BOTTOM_OFFSET)) {
                setBottomOffset(intent.getIntExtra(EXTRA_DETAIL_BOTTOM_OFFSET, 0))
            }
            if (intent.hasExtra(EXTRA_DETAIL_TOP_OFFSET)) {
                setTopOffset(intent.getIntExtra(EXTRA_DETAIL_TOP_OFFSET, 0))
            }
            if (intent.hasExtra(EXTRA_DETAIL_SCRIPT_TIPS_TOP_MARGIN)) {
                setScriptTipsTopMargin(intent.getIntExtra(EXTRA_DETAIL_SCRIPT_TIPS_TOP_MARGIN, 0))
            }
            if (intent.hasExtra(EXTRA_DETAIL_ICP_TIPS_BOTTOM_MARGIN)) {
                setIcpTipsBottomMargin(intent.getIntExtra(EXTRA_DETAIL_ICP_TIPS_BOTTOM_MARGIN, 0))
            }
        }
    }

    private fun buildUnlockListener(
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
                    showUnlockDialog(drama, callback, lockSet, enableContinuousUnlock)
                }

                override fun unlockFlowEnd(
                    drama: DJXDrama,
                    errCode: IDJXDramaUnlockListener.UnlockErrorStatus?,
                    map: Map<String, Any>?,
                ) {
                    // Pangolin owns the post-unlock UI in draw feed.
                }

                override fun showCustomAd(
                    drama: DJXDrama,
                    callback: IDJXDramaUnlockListener.CustomAdCallback,
                ) {
                    PangolinRewardAdBridge.requestRewardAd("draw_detail", drama, callback)
                }
            }
        }

        return object : IDJXDramaUnlockListener {
            override fun unlockFlowStart(
                drama: DJXDrama,
                callback: IDJXDramaUnlockListener.UnlockCallback,
                map: Map<String, Any>?,
            ) {
                showUnlockDialog(drama, callback, lockSet, enableContinuousUnlock)
            }

            override fun unlockFlowEnd(
                drama: DJXDrama,
                errCode: IDJXDramaUnlockListener.UnlockErrorStatus?,
                map: Map<String, Any>?,
            ) {
                // Pangolin owns the post-unlock UI in draw feed.
            }
        }
    }

    private fun showUnlockDialog(
        drama: DJXDrama,
        callback: IDJXDramaUnlockListener.UnlockCallback,
        lockSet: Int,
        enableContinuousUnlock: Boolean,
    ) {
        val unlockType =
            if (enableContinuousUnlock) DJXUnlockModeType.UNLOCKTYPE_CONTINUES else DJXUnlockModeType.UNLOCKTYPE_DEFAULT
        AlertDialog.Builder(this@PangolinDramaDrawActivity)
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
        return when (intent.getStringExtra(EXTRA_CHANNEL_TYPE)) {
            CHANNEL_THEATER -> DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_THEATER
            CHANNEL_RECOMMEND_THEATER -> DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_RECOMMEND_THEATER
            else -> DJXWidgetDrawParams.DRAW_CHANNEL_TYPE_RECOMMEND
        }
    }

    private fun contentType(): Int {
        return when (intent.getStringExtra(EXTRA_CONTENT_TYPE)) {
            CONTENT_ONLY_DRAMA -> DJXWidgetDrawParams.DRAW_CONTENT_TYPE_ONLY_DRAMA
            else -> DJXWidgetDrawParams.DRAW_CONTENT_TYPE_ONLY_DRAMA
        }
    }

    private fun progressBarStyle(): Int {
        return when (intent.getStringExtra(EXTRA_PROGRESS_BAR_STYLE)) {
            PROGRESS_STYLE_DARK -> DJXWidgetDrawParams.PROGRESS_BAR_STYLE_DARK
            else -> DJXWidgetDrawParams.PROGRESS_BAR_STYLE_LIGHT
        }
    }

    override fun onBackPressed() {
        val currentWidget = widget
        if (currentWidget == null) {
            super.onBackPressed()
            return
        }
        if (!currentWidget.canBackPress()) {
            if (intent.getBooleanExtra(EXTRA_FINISH_ON_BLOCKED_BACK, false)) {
                finish()
            }
            return
        }
        if (!intent.getBooleanExtra(EXTRA_BACK_REFRESH_ENABLED, true)) {
            super.onBackPressed()
            return
        }
        val current = SystemClock.elapsedRealtime()
        val interval = intent.getIntExtra(EXTRA_BACK_REFRESH_INTERVAL_MILLIS, 3000)
            .coerceAtLeast(0)
        if (current - lastBackTime > interval) {
            lastBackTime = current
            currentWidget.backRefresh()
            return
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        widget?.destroy()
        widget = null
        super.onDestroy()
    }

    private fun android.content.Intent.booleanExtraOrDefault(
        name: String,
        defaultValue: Boolean,
    ): Boolean {
        return if (hasExtra(name)) getBooleanExtra(name, defaultValue) else defaultValue
    }
}
