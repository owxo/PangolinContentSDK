package com.owxo.pangolin_content_sdk

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.ContextWrapper
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import com.bytedance.sdk.djx.DJXRewardAdResult
import com.bytedance.sdk.djx.interfaces.listener.IDJXDramaUnlockListener
import com.bytedance.sdk.djx.model.DJXDrama
import io.flutter.plugin.common.MethodChannel

object PangolinRewardAdBridge {
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile
    private var channel: MethodChannel? = null

    fun attach(channel: MethodChannel) {
        this.channel = channel
    }

    fun detach(channel: MethodChannel) {
        if (this.channel == channel) {
            this.channel = null
        }
    }

    fun requestRewardAd(
        scene: String,
        drama: DJXDrama,
        callback: IDJXDramaUnlockListener.CustomAdCallback,
        context: Context? = null,
    ) {
        val activeChannel = channel
        if (activeChannel == null) {
            mainHandler.post { callback.onError() }
            return
        }

        val arguments = mapOf(
            "scene" to scene,
            "dramaId" to drama.id,
            "index" to drama.index,
            "extra" to mapOf(
                "title" to drama.title,
                "total" to drama.total,
            ),
        )

        mainHandler.post {
            activeChannel.invokeMethod(
                "onRewardAdRequested",
                arguments,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        handleRewardResult(result, callback, context)
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        mainHandler.post { callback.onError() }
                    }

                    override fun notImplemented() {
                        mainHandler.post { callback.onError() }
                    }
                },
            )
        }
    }

    private fun handleRewardResult(
        result: Any?,
        callback: IDJXDramaUnlockListener.CustomAdCallback,
        context: Context?,
    ) {
        val resultMap = result as? Map<*, *>
        val shown = resultMap.boolean("shown", defaultValue = false)
        val rewarded = resultMap.boolean("rewarded", defaultValue = false)
        val ecpm = resultMap.string("ecpm").orEmpty()
        val errorMessage = resultMap.string("errorMessage").orEmpty()
        val extra = resultMap.map("extra").toStringMap()

        mainHandler.post {
            if (!shown) {
                showUnavailableMessage(context, errorMessage)
                callback.onError()
                return@post
            }
            callback.onShow(ecpm)
            callback.onRewardVerify(DJXRewardAdResult(rewarded, extra))
        }
    }

    private fun Map<*, *>?.boolean(key: String, defaultValue: Boolean): Boolean {
        val value = this?.get(key)
        return when (value) {
            is Boolean -> value
            is Number -> value.toInt() != 0
            is String -> value.equals("true", ignoreCase = true) || value == "1"
            else -> defaultValue
        }
    }

    private fun Map<*, *>?.string(key: String): String? {
        return this?.get(key)?.toString()
    }

    private fun Map<*, *>?.map(key: String): Map<*, *>? {
        return this?.get(key) as? Map<*, *>
    }

    private fun showUnavailableMessage(context: Context?, errorMessage: String) {
        val message = errorMessage.ifBlank { "歇歇吧，广告太忙了" }
        val activity = context?.ownerActivity()
        if (activity == null || activity.isFinishing || activity.isDestroyed) {
            context?.applicationContext?.let {
                Toast.makeText(it, message, Toast.LENGTH_SHORT).show()
            }
            return
        }
        AlertDialog.Builder(activity)
            .setMessage(message)
            .setPositiveButton("知道了", null)
            .show()
    }

    private tailrec fun Context.ownerActivity(): Activity? {
        return when (this) {
            is Activity -> this
            is ContextWrapper -> baseContext.ownerActivity()
            else -> null
        }
    }

    private fun Map<*, *>?.toStringMap(): Map<String, Any> {
        if (this == null) return emptyMap()
        return entries.mapNotNull { entry ->
            val value = entry.value
            if (value == null || value is String || value is Number || value is Boolean) {
                entry.key.toString() to (value ?: "")
            } else {
                null
            }
        }.toMap()
    }
}
