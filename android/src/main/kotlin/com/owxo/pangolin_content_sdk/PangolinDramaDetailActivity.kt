package com.owxo.pangolin_content_sdk

import android.app.AlertDialog
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import com.bytedance.sdk.djx.DJXSdk
import com.bytedance.sdk.djx.IDJXWidget
import com.bytedance.sdk.djx.interfaces.listener.IDJXDramaUnlockListener
import com.bytedance.sdk.djx.model.DJXDrama
import com.bytedance.sdk.djx.model.DJXDramaDetailConfig
import com.bytedance.sdk.djx.model.DJXDramaUnlockAdMode
import com.bytedance.sdk.djx.model.DJXDramaUnlockInfo
import com.bytedance.sdk.djx.model.DJXDramaUnlockMethod
import com.bytedance.sdk.djx.model.DJXUnlockModeType
import com.bytedance.sdk.djx.params.DJXWidgetDramaDetailParams

class PangolinDramaDetailActivity : FragmentActivity() {
    companion object {
        var pendingDrama: DJXDrama? = null

        const val EXTRA_FREE_SET = "pangolin_free_set"
        const val EXTRA_LOCK_SET = "pangolin_lock_set"
        const val EXTRA_PLAY_DURATION_SECONDS = "pangolin_play_duration_seconds"
        const val EXTRA_FROM_GID = "pangolin_from_gid"
        const val EXTRA_ENTER_FROM = "pangolin_enter_from"
        const val EXTRA_REC_MAP = "pangolin_rec_map"
        const val EXTRA_UNLOCK_AD_MODE = "pangolin_unlock_ad_mode"
        const val EXTRA_ENABLE_INFINITE_SCROLL = "pangolin_enable_infinite_scroll"
        const val EXTRA_ENABLE_CONTINUOUS_UNLOCK = "pangolin_enable_continuous_unlock"
        const val EXTRA_HIDE_BACK = "pangolin_hide_back"
        const val EXTRA_HIDE_TOP_INFO = "pangolin_hide_top_info"
        const val EXTRA_HIDE_BOTTOM_INFO = "pangolin_hide_bottom_info"
        const val EXTRA_HIDE_LIKE_BUTTON = "pangolin_hide_like_button"
        const val EXTRA_HIDE_FAVOR_BUTTON = "pangolin_hide_favor_button"
        const val EXTRA_HIDE_MORE = "pangolin_hide_more"
        const val EXTRA_HIDE_REWARD_DIALOG = "pangolin_hide_reward_dialog"
        const val EXTRA_HIDE_CELLULAR_TOAST = "pangolin_hide_cellular_toast"
        const val EXTRA_HIDE_DOUBLE_CLICK = "pangolin_hide_double_click"
        const val EXTRA_HIDE_LONG_CLICK_SPEED = "pangolin_hide_long_click_speed"
        const val EXTRA_BOTTOM_OFFSET = "pangolin_bottom_offset"
        const val EXTRA_TOP_OFFSET = "pangolin_top_offset"
        const val EXTRA_SCRIPT_TIPS_TOP_MARGIN = "pangolin_script_tips_top_margin"
        const val EXTRA_ICP_TIPS_BOTTOM_MARGIN = "pangolin_icp_tips_bottom_margin"
        const val EXTRA_USE_CUSTOM_REWARD_AD = "pangolin_use_custom_reward_ad"

        const val AD_MODE_COMMON = "common"
        const val AD_MODE_SPECIFIC = "specific"
        const val ENTER_FROM_DEFAULT = "default"
        const val ENTER_FROM_SKIT_MIXED = "skitMixed"
        const val ENTER_FROM_DRAMA_HOME_RECENTLY_WATCHED = "dramaHomeRecentlyWatched"
        const val ENTER_FROM_DRAMA_HOME = "dramaHome"
        const val ENTER_FROM_DRAMA_HISTORY = "dramaHistory"
        const val ENTER_FROM_DRAMA_CARD = "dramaCard"
    }

    private var widget: IDJXWidget? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val drama = pendingDrama
        pendingDrama = null
        if (drama == null || !DJXSdk.isStartSuccess()) {
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

        val freeSet = intent.getIntExtra(EXTRA_FREE_SET, 5)
        val lockSet = intent.getIntExtra(EXTRA_LOCK_SET, 2)
        val enableContinuousUnlock = intent.getBooleanExtra(EXTRA_ENABLE_CONTINUOUS_UNLOCK, false)
        val useCustomRewardAd = intent.getBooleanExtra(EXTRA_USE_CUSTOM_REWARD_AD, false)
        val unlockListener = buildUnlockListener(
            lockSet = lockSet,
            enableContinuousUnlock = enableContinuousUnlock,
            useCustomRewardAd = useCustomRewardAd,
        )
        val detailConfig = DJXDramaDetailConfig.obtain(
            unlockAdMode(useCustomRewardAd),
            freeSet,
            unlockListener,
        ).apply {
            infiniteScrollEnabled(intent.getBooleanExtra(EXTRA_ENABLE_INFINITE_SCROLL, true))
            hideLikeButton(intent.getBooleanExtra(EXTRA_HIDE_LIKE_BUTTON, false))
            hideFavorButton(intent.getBooleanExtra(EXTRA_HIDE_FAVOR_BUTTON, false))
            hideRewardDialog(intent.getBooleanExtra(EXTRA_HIDE_REWARD_DIALOG, false))
            hideBack(intent.getBooleanExtra(EXTRA_HIDE_BACK, false), View.OnClickListener { finish() })
            hideTopInfo(intent.getBooleanExtra(EXTRA_HIDE_TOP_INFO, false))
            hideBottomInfo(intent.getBooleanExtra(EXTRA_HIDE_BOTTOM_INFO, false))
            hideMore(intent.getBooleanExtra(EXTRA_HIDE_MORE, false))
            hideCellularToast(intent.getBooleanExtra(EXTRA_HIDE_CELLULAR_TOAST, false))
            hideDoubleClick(intent.getBooleanExtra(EXTRA_HIDE_DOUBLE_CLICK, false))
            hideLongClickSpeed(intent.getBooleanExtra(EXTRA_HIDE_LONG_CLICK_SPEED, false))
            if (intent.hasExtra(EXTRA_BOTTOM_OFFSET)) {
                setBottomOffset(intent.getIntExtra(EXTRA_BOTTOM_OFFSET, 0))
            }
            if (intent.hasExtra(EXTRA_TOP_OFFSET)) {
                setTopOffset(intent.getIntExtra(EXTRA_TOP_OFFSET, 0))
            }
            if (intent.hasExtra(EXTRA_SCRIPT_TIPS_TOP_MARGIN)) {
                setScriptTipsTopMargin(intent.getIntExtra(EXTRA_SCRIPT_TIPS_TOP_MARGIN, 0))
            }
            if (intent.hasExtra(EXTRA_ICP_TIPS_BOTTOM_MARGIN)) {
                setIcpTipsBottomMargin(intent.getIntExtra(EXTRA_ICP_TIPS_BOTTOM_MARGIN, 0))
            }
        }

        val fromGid = intent.getLongExtra(EXTRA_FROM_GID, -1L)
        val detailParams = DJXWidgetDramaDetailParams.obtain(drama.id, drama.index, detailConfig)
            .currentDuration(intent.getIntExtra(EXTRA_PLAY_DURATION_SECONDS, 0) * 1000)
            .fromGid(if (fromGid > 0) fromGid.toString() else "-1")
            .from(enterFrom())
        recMap().takeIf { it.isNotEmpty() }?.let { detailParams.recMap(it) }
        widget = DJXSdk.factory().createDramaDetail(
            detailParams,
        )

        supportFragmentManager.beginTransaction()
            .replace(container.id, widget!!.fragment)
            .commitAllowingStateLoss()
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
                    // No-op: the default Pangolin flow owns the reward lifecycle UI.
                }

                override fun showCustomAd(
                    drama: DJXDrama,
                    callback: IDJXDramaUnlockListener.CustomAdCallback,
                ) {
                    PangolinRewardAdBridge.requestRewardAd("detail", drama, callback)
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
                // No-op: the default Pangolin flow owns the reward lifecycle UI.
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
        AlertDialog.Builder(this@PangolinDramaDetailActivity)
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

    private fun unlockAdMode(useCustomRewardAd: Boolean): DJXDramaUnlockAdMode {
        return when (intent.getStringExtra(EXTRA_UNLOCK_AD_MODE)) {
            AD_MODE_SPECIFIC -> DJXDramaUnlockAdMode.MODE_SPECIFIC
            AD_MODE_COMMON -> DJXDramaUnlockAdMode.MODE_COMMON
            else -> if (useCustomRewardAd) {
                DJXDramaUnlockAdMode.MODE_SPECIFIC
            } else {
                DJXDramaUnlockAdMode.MODE_COMMON
            }
        }
    }

    private fun enterFrom(): DJXWidgetDramaDetailParams.DJXDramaEnterFrom {
        return when (intent.getStringExtra(EXTRA_ENTER_FROM)) {
            ENTER_FROM_SKIT_MIXED -> DJXWidgetDramaDetailParams.DJXDramaEnterFrom.SKIT_MIXED
            ENTER_FROM_DRAMA_HOME_RECENTLY_WATCHED ->
                DJXWidgetDramaDetailParams.DJXDramaEnterFrom.DRAMA_HOME_RECENTLY_WATCHED
            ENTER_FROM_DRAMA_HOME -> DJXWidgetDramaDetailParams.DJXDramaEnterFrom.DRAMA_HOME
            ENTER_FROM_DRAMA_HISTORY -> DJXWidgetDramaDetailParams.DJXDramaEnterFrom.DRAMA_HISTORY
            ENTER_FROM_DRAMA_CARD -> DJXWidgetDramaDetailParams.DJXDramaEnterFrom.DRAMA_CARD
            else -> DJXWidgetDramaDetailParams.DJXDramaEnterFrom.DEFAULT
        }
    }

    @Suppress("DEPRECATION")
    private fun recMap(): Map<String, Any> {
        val raw = intent.getSerializableExtra(EXTRA_REC_MAP) as? Map<*, *>
            ?: return emptyMap()
        return raw.mapNotNull { entry ->
            val value = entry.value
            if (value == null || value is String || value is Number || value is Boolean) {
                entry.key.toString() to (value ?: "")
            } else {
                null
            }
        }.toMap()
    }

    override fun onDestroy() {
        widget?.destroy()
        widget = null
        super.onDestroy()
    }
}
