// KoneSDK.kt
// Drop-in Special Offers Fragment for Android apps
// Requirements: Android API 24+, Kotlin 1.9+
// Add dependency: implementation 'com.squareup.okhttp3:okhttp:4.12.0'

package vc.kone.sdk

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.*
import android.widget.*
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

// ─────────────────────────────────────────
// Config
// ─────────────────────────────────────────

data class KoneSDKConfig(
    val apiKey: String,
    val siteUrl: String = "https://kone.vc",
    val greeting: String = "Hi! 👋 I'm your free personal AI assistant.\n\nI can help you find the best deals, offers and recommendations.\n\nTap a quick question or ask anything!",
    val accentColor: Int = Color.parseColor("#5B6EF5"),
    val quickChips: List<Pair<String, String>> = listOf(
        "👟 Cheap shoes UK"   to "Where can I buy cheap shoes in the UK?",
        "🤖 Top AI tools"     to "Recommend top AI tools for 2025",
        "💰 Best deals today" to "What are the best online deals today?",
        "✈️ Cheap travel"    to "What are cheap travel destinations right now?",
    )
)

// ─────────────────────────────────────────
// Message model
// ─────────────────────────────────────────

private data class KoneMessage(val isAI: Boolean, val text: String)

// ─────────────────────────────────────────
// Fragment  (drop into any BottomNavigationView or TabLayout)
// ─────────────────────────────────────────

class KoneSpecialOffersFragment : Fragment() {

    companion object {
        private const val ARG_API_KEY   = "api_key"
        private const val ARG_SITE_URL  = "site_url"
        private const val API_ENDPOINT  = "https://go.kone.vc/mcp/chat"

        fun newInstance(config: KoneSDKConfig): KoneSpecialOffersFragment {
            return KoneSpecialOffersFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_API_KEY, config.apiKey)
                    putString(ARG_SITE_URL, config.siteUrl)
                }
                this.config = config
            }
        }
    }

    var config = KoneSDKConfig(apiKey = "")
    private val messages = mutableListOf<KoneMessage>()
    private var responseId: String? = null
    private var isLoading = false
    private val client = OkHttpClient()

    // Views
    private lateinit var landingScroll: ScrollView
    private lateinit var chatContainer: LinearLayout
    private lateinit var messagesLayout: LinearLayout
    private lateinit var chatScroll: ScrollView
    private lateinit var inputField: EditText
    private lateinit var sendBtn: ImageButton

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val ctx = requireContext()
        val root = FrameLayout(ctx).apply { setBackgroundColor(Color.parseColor("#0D0D10")) }

        buildLandingScreen(ctx, root)
        buildChatScreen(ctx, root)
        showLanding()
        return root
    }

    // ─── Landing ───

    private fun buildLandingScreen(ctx: Context, root: FrameLayout) {
        landingScroll = ScrollView(ctx).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        val outerStack = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // Hero
        outerStack.addView(makeHero(ctx))
        // Label
        outerStack.addView(makeSectionLabel(ctx, "QUICK QUESTIONS"))
        // Chips
        val chipsStack = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            val pad = dp(ctx, 16)
            setPadding(pad, 0, pad, dp(ctx, 12))
        }
        config.quickChips.forEach { (label, question) ->
            chipsStack.addView(makeChipButton(ctx, label, question))
        }
        outerStack.addView(chipsStack)
        // CTA
        outerStack.addView(makeCtaButton(ctx))
        // Footer
        outerStack.addView(makeKoneFooter(ctx))

        landingScroll.addView(outerStack)
        root.addView(landingScroll)
    }

    private fun makeHero(ctx: Context): LinearLayout {
        val col = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            val pad = dp(ctx, 24)
            setPadding(pad, pad, pad, dp(ctx, 16))
        }

        val iconView = FrameLayout(ctx).apply {
            val size = dp(ctx, 56)
            layoutParams = LinearLayout.LayoutParams(size, size).apply { bottomMargin = dp(ctx, 14) }
            setBackgroundColor(config.accentColor)
            background = roundedBg(config.accentColor, 14f.dpF(ctx))
        }
        iconView.addView(TextView(ctx).apply {
            text = "AI"
            textSize = 16f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        })
        col.addView(iconView)

        col.addView(TextView(ctx).apply {
            text = "Your free personal\nAI assistant"
            textSize = 20f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(Color.parseColor("#EEEDF2"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(ctx, 8) }
        })

        col.addView(TextView(ctx).apply {
            text = "Find deals, offers & recommendations"
            textSize = 12f
            setTextColor(Color.parseColor("#55535F"))
            gravity = Gravity.CENTER
        })

        return col
    }

    private fun makeSectionLabel(ctx: Context, text: String) = TextView(ctx).apply {
        this.text = text
        textSize = 10f
        setTypeface(null, android.graphics.Typeface.BOLD)
        setTextColor(Color.parseColor("#55535F"))
        letterSpacing = 0.12f
        val h = dp(ctx, 16); val v = dp(ctx, 8)
        setPadding(h, v, h, v)
    }

    private fun makeChipButton(ctx: Context, label: String, question: String): Button {
        return Button(ctx).apply {
            text = label
            textSize = 13f
            setTextColor(Color.parseColor("#9896A8"))
            background = roundedStrokeBg(Color.parseColor("#1C1C22"), Color.parseColor("#333340"), 10f.dpF(ctx))
            gravity = Gravity.START or Gravity.CENTER_VERTICAL
            val hPad = dp(ctx, 14); val vPad = dp(ctx, 12)
            setPadding(hPad, vPad, hPad, vPad)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(ctx, 48)
            ).apply { bottomMargin = dp(ctx, 8) }
            isAllCaps = false
            setOnClickListener { openChat(question) }
        }
    }

    private fun makeCtaButton(ctx: Context): FrameLayout {
        val wrapper = FrameLayout(ctx).apply {
            val p = dp(ctx, 16)
            setPadding(p, 0, p, dp(ctx, 8))
        }
        wrapper.addView(Button(ctx).apply {
            text = "💬  Ask your own question"
            textSize = 14f
            setTextColor(Color.WHITE)
            background = roundedBg(config.accentColor, 12f.dpF(ctx))
            isAllCaps = false
            setOnClickListener { openChat() }
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                dp(ctx, 52)
            )
        })
        return wrapper
    }

    // ─── Chat ───

    private fun buildChatScreen(ctx: Context, root: FrameLayout) {
        chatContainer = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.parseColor("#0D0D10"))
        }

        chatContainer.addView(makeChatHeader(ctx))

        chatScroll = ScrollView(ctx).apply {
            layoutParams = LinearLayout.LayoutParams(0, 0, 1f)
        }
        messagesLayout = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            val p = dp(ctx, 12)
            setPadding(p, p, p, p)
        }
        chatScroll.addView(messagesLayout)
        chatContainer.addView(chatScroll)

        chatContainer.addView(makeInputBar(ctx))
        chatContainer.addView(makeKoneFooter(ctx))

        root.addView(chatContainer)
    }

    private fun makeChatHeader(ctx: Context): LinearLayout {
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.parseColor("#141418"))
            val p = dp(ctx, 12)
            setPadding(p, p, p, p)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(ctx, 56)
            )
        }

        val backBtn = ImageButton(ctx).apply {
            setImageResource(android.R.drawable.ic_menu_revert)
            setColorFilter(Color.parseColor("#9896A8"))
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { showLanding() }
            layoutParams = LinearLayout.LayoutParams(dp(ctx, 40), dp(ctx, 40))
        }
        row.addView(backBtn)

        val av = FrameLayout(ctx).apply {
            val s = dp(ctx, 32)
            layoutParams = LinearLayout.LayoutParams(s, s).apply { marginStart = dp(ctx, 6) }
            background = roundedBg(config.accentColor, 8f.dpF(ctx))
        }
        av.addView(TextView(ctx).apply {
            text = "AI"
            textSize = 10f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        })
        row.addView(av)

        row.addView(TextView(ctx).apply {
            text = "Your free personal AI assistant"
            textSize = 13f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(Color.parseColor("#EEEDF2"))
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(ctx, 10)
            }
        })
        return row
    }

    private fun makeInputBar(ctx: Context): LinearLayout {
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.parseColor("#141418"))
            val p = dp(ctx, 10)
            setPadding(p, p, p, p)
        }

        inputField = EditText(ctx).apply {
            hint = "Ask me anything…"
            setHintTextColor(Color.parseColor("#55535F"))
            setTextColor(Color.parseColor("#EEEDF2"))
            setBackgroundColor(Color.parseColor("#1C1C22"))
            background = roundedStrokeBg(Color.parseColor("#1C1C22"), Color.parseColor("#333340"), 10f.dpF(ctx))
            val p = dp(ctx, 10)
            setPadding(p, p, p, p)
            maxLines = 3
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        row.addView(inputField)

        sendBtn = ImageButton(ctx).apply {
            setImageResource(android.R.drawable.ic_menu_send)
            setColorFilter(Color.WHITE)
            background = roundedBg(config.accentColor, 10f.dpF(ctx))
            val s = dp(ctx, 42)
            layoutParams = LinearLayout.LayoutParams(s, s).apply { marginStart = dp(ctx, 8) }
            setOnClickListener { handleSend() }
        }
        row.addView(sendBtn)
        return row
    }

    // ─── Actions ───

    private fun openChat(initialQuestion: String? = null) {
        landingScroll.visibility = View.GONE
        chatContainer.visibility = View.VISIBLE
        if (messages.isEmpty()) {
            addMessage(KoneMessage(isAI = true, text = config.greeting))
        }
        initialQuestion?.let {
            view?.postDelayed({ sendMessage(it) }, 200)
        }
    }

    private fun showLanding() {
        chatContainer.visibility = View.GONE
        landingScroll.visibility = View.VISIBLE
    }

    private fun handleSend() {
        val text = inputField.text.toString().trim()
        if (text.isEmpty()) return
        inputField.setText("")
        sendMessage(text)
    }

    private fun sendMessage(prompt: String) {
        if (isLoading) return
        isLoading = true
        sendBtn.isEnabled = false
        addMessage(KoneMessage(isAI = false, text = prompt))

        lifecycleScope.launch {
            try {
                val body = JSONObject().apply {
                    put("prompt", prompt)
                    put("url", config.siteUrl)
                    put("api_key", config.apiKey)
                    responseId?.let { put("response_id", it) }
                }
                val reqBody = body.toString().toRequestBody("application/json".toMediaType())
                val req = Request.Builder().url(API_ENDPOINT).post(reqBody).build()

                val result = withContext(Dispatchers.IO) { client.newCall(req).execute() }
                val json = JSONObject(result.body?.string() ?: "{}")
                responseId = json.optString("response_id").ifEmpty { null }
                val msg = json.optString("message").ifEmpty {
                    json.optString("response").ifEmpty {
                        json.optString("text").ifEmpty { json.toString() }
                    }
                }
                withContext(Dispatchers.Main) { addMessage(KoneMessage(isAI = true, text = msg)) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { addMessage(KoneMessage(isAI = true, text = "⚠️ Error: ${e.message}")) }
            } finally {
                withContext(Dispatchers.Main) { isLoading = false; sendBtn.isEnabled = true }
            }
        }
    }

    private fun addMessage(msg: KoneMessage) {
        messages.add(msg)
        val ctx = requireContext()
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = if (msg.isAI) Gravity.START else Gravity.END
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(ctx, 10) }
        }

        if (msg.isAI) {
            val av = FrameLayout(ctx).apply {
                val s = dp(ctx, 24)
                layoutParams = LinearLayout.LayoutParams(s, s).apply { marginEnd = dp(ctx, 8) }
                background = roundedBg(config.accentColor, 6f.dpF(ctx))
            }
            av.addView(TextView(ctx).apply {
                text = "AI"; textSize = 8f
                setTypeface(null, android.graphics.Typeface.BOLD)
                setTextColor(Color.WHITE); gravity = Gravity.CENTER
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
            })
            row.addView(av)
        }

        row.addView(TextView(ctx).apply {
            text = msg.text; textSize = 13f
            setTextColor(Color.parseColor("#EEEDF2"))
            background = roundedBg(
                if (msg.isAI) Color.parseColor("#1C1C22") else config.accentColor,
                12f.dpF(ctx)
            )
            val p = dp(ctx, 10)
            setPadding(dp(ctx, 12), p, dp(ctx, 12), p)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { weight = 0f }
        })

        messagesLayout.addView(row)
        chatScroll.post { chatScroll.fullScroll(View.FOCUS_DOWN) }
    }

    private fun makeKoneFooter(ctx: Context) = Button(ctx).apply {
        text = "More AI agents ↗"
        textSize = 11f
        setTextColor(Color.parseColor("#55535F"))
        setBackgroundColor(Color.TRANSPARENT)
        isAllCaps = false
        setOnClickListener { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://kone.vc/apps.html"))) }
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, dp(ctx, 40)
        )
    }

    // ─── Drawing helpers ───

    private fun roundedBg(color: Int, radius: Float): android.graphics.drawable.GradientDrawable {
        return android.graphics.drawable.GradientDrawable().apply {
            setColor(color); cornerRadius = radius
        }
    }

    private fun roundedStrokeBg(fill: Int, stroke: Int, radius: Float): android.graphics.drawable.GradientDrawable {
        return android.graphics.drawable.GradientDrawable().apply {
            setColor(fill); cornerRadius = radius
            setStroke(2, stroke)
        }
    }

    private fun dp(ctx: Context, dp: Int) = (dp * ctx.resources.displayMetrics.density).toInt()
    private fun Float.dpF(ctx: Context) = this * ctx.resources.displayMetrics.density
}
