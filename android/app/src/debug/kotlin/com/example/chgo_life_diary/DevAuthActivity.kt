package com.example.chgo_life_diary

import android.content.Intent
import android.net.Uri
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.security.SecureRandom

/** Only compiled into debug. No URI, verifier or credential logging. */
class DevAuthActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var ready = false

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        CommonSessionVault.install(this, engine)
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "life_diary/dev_auth")
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    ready = true
                    result.success(null)
                    deliver(intent)
                }
                "pkce" -> {
                    fun encode(bytes: ByteArray) = Base64.encodeToString(bytes,
                        Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
                    val verifier = encode(ByteArray(32).also { SecureRandom().nextBytes(it) })
                    result.success(mapOf("verifier" to verifier, "challenge" to
                        encode(MessageDigest.getInstance("SHA-256").digest(verifier.toByteArray(Charsets.US_ASCII)))))
                }
                "openBrowser" -> {
                    val uri = Uri.parse(call.arguments as? String ?: "")
                    if (uri.scheme != "http" || uri.host != "127.0.0.1" || uri.port != 8000 ||
                        uri.path != "/api/v1/mobile/life-diary/authorize") {
                        result.error("invalid", "Invalid browser destination", null)
                    } else {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("browser", "Browser unavailable", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (ready) deliver(intent)
    }

    private fun deliver(source: Intent) {
        if (source.action != Intent.ACTION_VIEW) return
        val value = source.dataString ?: return
        source.data = null // Consume once; Dart owns validation and transaction matching.
        channel?.invokeMethod("callback", value)
    }
}
