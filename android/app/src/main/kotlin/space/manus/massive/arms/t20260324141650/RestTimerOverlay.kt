package space.manus.massive.arms.t20260324141650

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Bolha flutuante com o tempo restante do descanso, visível sobre outros apps.
 */
object RestTimerOverlay {
    private const val PREFS = "rest_overlay"
    private const val KEY_X = "x"
    private const val KEY_Y = "y"

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var view: View? = null
    private var timeView: TextView? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var endsAtMillis: Long = 0L
    private val tick = object : Runnable {
        override fun run() {
            if (view == null) return
            val left = endsAtMillis - System.currentTimeMillis()
            if (left <= 0L) {
                hide()
                return
            }
            render(left)
            handler.postDelayed(this, 200L)
        }
    }

    fun hasPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    fun show(context: Context, endsAt: Long) {
        handler.post { showOnMain(context.applicationContext, endsAt) }
    }

    fun hide() {
        handler.post { hideOnMain() }
    }

    private fun showOnMain(context: Context, endsAt: Long) {
        if (!hasPermission(context)) return
        endsAtMillis = endsAt
        if (endsAtMillis <= System.currentTimeMillis()) {
            hideOnMain()
            return
        }

        if (view != null) {
            handler.removeCallbacks(tick)
            handler.post(tick)
            return
        }

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager = wm
        val overlay = buildView(context)
        view = overlay
        val params = buildParams(context)
        layoutParams = params
        try {
            wm.addView(overlay, params)
            handler.removeCallbacks(tick)
            handler.post(tick)
        } catch (_: Exception) {
            recycle()
        }
    }

    private fun hideOnMain() {
        handler.removeCallbacks(tick)
        val overlay = view ?: return
        try {
            windowManager?.removeView(overlay)
        } catch (_: Exception) {
            // Já removida.
        }
        recycle()
    }

    private fun recycle() {
        view = null
        timeView = null
        layoutParams = null
        windowManager = null
    }

    private fun buildParams(context: Context): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val metrics = context.resources.displayMetrics
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val defaultX = metrics.widthPixels - dp(context, 132)
        val defaultY = (metrics.heightPixels * 0.58f).roundToInt()
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = prefs.getInt(KEY_X, defaultX)
            y = prefs.getInt(KEY_Y, defaultY)
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun buildView(context: Context): View {
        val density = context.resources.displayMetrics.density
        fun d(v: Int) = (v * density).roundToInt()

        val label = TextView(context).apply {
            text = "DESCANSO"
            setTextColor(Color.parseColor("#A78BFA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f)
            letterSpacing = 0.12f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        val time = TextView(context).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER
            includeFontPadding = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                fontFeatureSettings = "tnum"
            }
        }
        timeView = time

        val bubble = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(d(18), d(12), d(18), d(12))
            minimumWidth = d(108)
            elevation = d(10).toFloat()
            background = GradientDrawable().apply {
                cornerRadius = d(22).toFloat()
                setColor(Color.parseColor("#F216161A"))
                setStroke(d(2), Color.parseColor("#8B5CF6"))
            }
            addView(label)
            addView(
                time,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { topMargin = d(2) },
            )
            contentDescription = "Cronômetro de descanso"
        }

        val slop = ViewConfiguration.get(context).scaledTouchSlop
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragging = false

        bubble.setOnTouchListener { _, event ->
            val params = layoutParams ?: return@setOnTouchListener false
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = params.x
                    startY = params.y
                    dragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (!dragging && (abs(dx) > slop || abs(dy) > slop)) {
                        dragging = true
                    }
                    if (dragging) {
                        params.x = startX + dx.roundToInt()
                        params.y = max(0, startY + dy.roundToInt())
                        try {
                            windowManager?.updateViewLayout(bubble, params)
                        } catch (_: Exception) {
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (dragging) {
                        persistPosition(context, params.x, params.y)
                    } else if (event.actionMasked == MotionEvent.ACTION_UP) {
                        openApp(context)
                    }
                    true
                }
                else -> false
            }
        }
        return bubble
    }

    private fun render(leftMs: Long) {
        val totalSeconds = max(0L, (leftMs + 999L) / 1000L)
        val minutes = totalSeconds / 60L
        val seconds = totalSeconds % 60L
        val text = "%02d:%02d".format(minutes, seconds)
        timeView?.text = text
        timeView?.setTextColor(
            if (totalSeconds <= 10L) Color.parseColor("#F59E0B") else Color.WHITE,
        )
        view?.contentDescription = "Descanso restante $text"
    }

    private fun persistPosition(context: Context, x: Int, y: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_X, x)
            .putInt(KEY_Y, y)
            .apply()
    }

    private fun openApp(context: Context) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
        }
    }

    private fun dp(context: Context, value: Int): Int {
        return (value * context.resources.displayMetrics.density).roundToInt()
    }
}
