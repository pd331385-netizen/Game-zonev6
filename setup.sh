#!/bin/bash
# GameZone project generator v4
set -e
mkdir -p "."
cat > "settings.gradle.kts" <<'GZEOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "GameZone"
include(":app")
GZEOF
mkdir -p "."
cat > "build.gradle.kts" <<'GZEOF'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.20" apply false
}
GZEOF
mkdir -p "."
cat > "gradle.properties" <<'GZEOF'
org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
GZEOF
mkdir -p "app"
cat > "app/build.gradle.kts" <<'GZEOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.example.gamezone"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.gamezone"
        minSdk = 29
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("dev.rikka.shizuku:api:13.1.5")
    implementation("dev.rikka.shizuku:provider:13.1.5")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
}
GZEOF
mkdir -p "app/src/main"
cat > "app/src/main/AndroidManifest.xml" <<'GZEOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.KILL_BACKGROUND_PROCESSES" />
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
        tools:ignore="ProtectedPermissions" />
    <uses-permission android:name="android.permission.WRITE_SETTINGS"
        tools:ignore="ProtectedPermissions" />

    <queries>
        <package android:name="moe.shizuku.privileged.api" />
        <intent>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent>
    </queries>

    <application
        android:allowBackup="true"
        android:icon="@android:drawable/sym_def_app_icon"
        android:label="GameZone"
        android:theme="@android:style/Theme.Material.NoActionBar">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <provider
            android:name="rikka.shizuku.ShizukuProvider"
            android:authorities="${applicationId}.shizuku"
            android:enabled="true"
            android:exported="true"
            android:multiprocess="false"
            android:permission="android.permission.INTERACT_ACROSS_USERS_FULL" />

        <service
            android:name=".GameModeService"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="game_mode_dnd_thermal_monitor" />
        </service>
    </application>
</manifest>
GZEOF
mkdir -p "app/src/main/java/com/example/gamezone"
cat > "app/src/main/java/com/example/gamezone/MainActivity.kt" <<'GZEOF'
package com.example.gamezone

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import rikka.shizuku.Shizuku

class MainActivity : ComponentActivity() {
    private val tick = mutableIntStateOf(0)
    private val permListener = Shizuku.OnRequestPermissionResultListener { _, _ ->
        tick.intValue = tick.intValue + 1
    }
    private val binderListener = Shizuku.OnBinderReceivedListener {
        tick.intValue = tick.intValue + 1
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            Shizuku.addRequestPermissionResultListener(permListener)
            Shizuku.addBinderReceivedListenerSticky(binderListener)
        } catch (e: Throwable) {
        }
        setContent {
            MaterialTheme(colorScheme = darkColorScheme()) {
                Surface(Modifier.fillMaxSize()) { GameScreen(tick.intValue) }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        tick.intValue++   // सेटिंग्स से लौटने पर परमिशन दोबारा जाँचने के लिए
    }

    override fun onDestroy() {
        try {
            Shizuku.removeRequestPermissionResultListener(permListener)
            Shizuku.removeBinderReceivedListener(binderListener)
        } catch (e: Throwable) {
        }
        super.onDestroy()
    }
}

data class GameApp(val label: String, val pkg: String, val icon: ImageBitmap)

@Composable
fun GameScreen(tick: Int) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val on by GameModeService.running.collectAsState()
    val thermal by GameModeService.thermalStatus.collectAsState()
    val cleanMsg by GameModeService.cleanMsg.collectAsState()
    var games by remember { mutableStateOf<List<GameApp>>(emptyList()) }
    var today by remember { mutableStateOf<Map<String, Long>>(emptyMap()) }
    var week by remember { mutableStateOf<Map<String, Long>>(emptyMap()) }

    val dndOk = ctx.getSystemService(NotificationManager::class.java).isNotificationPolicyAccessGranted
    val overlayOk = Settings.canDrawOverlays(ctx)
    val usageOk = Booster.hasUsageAccess(ctx)
    val writeOk = Settings.System.canWrite(ctx)
    val pkgUri = Uri.parse("package:${ctx.packageName}")
    val prefs = ctx.getSharedPreferences("gz", Context.MODE_PRIVATE)
    var strict by remember { mutableStateOf(prefs.getBoolean("strict", false)) }
    var showTips by remember { mutableStateOf(false) }
    val shizukuInstalled = ctx.packageManager.getLaunchIntentForPackage(SHIZUKU_PKG) != null
    val shizukuRunning = Shell.running()
    val shizukuOk = Shell.available()

    LaunchedEffect(Unit) { games = withContext(Dispatchers.IO) { loadGames(ctx) } }

    LaunchedEffect(tick) {
        if (Booster.hasUsageAccess(ctx)) {
            val (t, w) = withContext(Dispatchers.IO) {
                Booster.usageMinutes(ctx, Booster.startOfToday()) to
                    Booster.usageMinutes(ctx, System.currentTimeMillis() - 7L * 24 * 3600 * 1000)
            }
            today = t
            week = w
        }
    }

    val notifPermission = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { startGameMode(ctx, null) }

    if (showTips) TipsDialog { showTips = false }

    LazyVerticalGrid(
        columns = GridCells.Fixed(3),
        modifier = Modifier.fillMaxSize().statusBarsPadding().padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item(span = { GridItemSpan(maxLineSpan) }) {
            Text("GameZone", style = MaterialTheme.typography.headlineMedium)
        }

        // गेमिंग मोड स्विच
        item(span = { GridItemSpan(maxLineSpan) }) {
            Card(Modifier.fillMaxWidth()) {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text("गेमिंग मोड", style = MaterialTheme.typography.titleMedium)
                        Text(
                            if (on) "ON: DND, रैम सफाई, ओवरले, हीट गार्ड चालू" else "OFF",
                            style = MaterialTheme.typography.bodySmall
                        )
                        if (on) Text("फोन: ${thermalLabel(thermal)}", style = MaterialTheme.typography.bodySmall)
                        if (on && overlayOk) Text("💡 गेम में दाएँ किनारे (बीच) की हल्की पट्टी पर बाएँ स्वाइप करो", style = MaterialTheme.typography.labelSmall)
                    }
                    Switch(checked = on, onCheckedChange = { checked ->
                        if (checked) {
                            val needsNotif = Build.VERSION.SDK_INT >= 33 &&
                                ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                                PackageManager.PERMISSION_GRANTED
                            if (needsNotif) notifPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
                            else startGameMode(ctx, null)
                        } else {
                            ctx.startService(
                                Intent(ctx, GameModeService::class.java).setAction(GameModeService.ACTION_STOP)
                            )
                        }
                    })
                }
            }
        }

        // परमिशन्स
        item(span = { GridItemSpan(maxLineSpan) }) {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp)) {
                    Text("परमिशन्स (एक बार देनी हैं)", style = MaterialTheme.typography.titleSmall)
                    PermRow("DND (नोटिफिकेशन म्यूट)", dndOk) {
                        ctx.startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                    }
                    PermRow("ओवरले (गेम के ऊपर तापमान/बैटरी)", overlayOk) {
                        ctx.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkgUri))
                    }
                    PermRow("यूसेज एक्सेस (गेम का समय)", usageOk) {
                        ctx.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    }
                    PermRow("चमक कंट्रोल (गर्म होने पर घटाना)", writeOk) {
                        ctx.startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, pkgUri))
                    }
                }
            }
        }

        // Shizuku: असली force-stop और Game Mode
        item(span = { GridItemSpan(maxLineSpan) }) {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp)) {
                    Text("असली बूस्ट (Shizuku)", style = MaterialTheme.typography.titleSmall)
                    when {
                        shizukuOk -> {
                            Text("✅ तैयार: असली force-stop और Game Mode Performance चालू",
                                style = MaterialTheme.typography.bodySmall)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("सख्त सफाई (force-stop)", Modifier.weight(1f),
                                    style = MaterialTheme.typography.bodySmall)
                                Switch(checked = strict, onCheckedChange = { v ->
                                    strict = v
                                    prefs.edit().putBoolean("strict", v).apply()
                                })
                            }
                            Text("ध्यान: बंद किए ऐप्स (जैसे WhatsApp) नया मैसेज तभी दिखाएँगे जब उन्हें दोबारा खोलो",
                                style = MaterialTheme.typography.labelSmall)
                        }
                        shizukuRunning -> {
                            Text("Shizuku चालू है, बस परमिशन चाहिए", style = MaterialTheme.typography.bodySmall)
                            Button(onClick = { Shell.requestPermission() }) { Text("परमिशन दो") }
                        }
                        shizukuInstalled -> {
                            Text("Shizuku इंस्टॉल है पर चालू नहीं। खोलकर 'Start via Wireless debugging' दबाओ",
                                style = MaterialTheme.typography.bodySmall)
                            Button(onClick = {
                                ctx.packageManager.getLaunchIntentForPackage(SHIZUKU_PKG)?.let { ctx.startActivity(it) }
                            }) { Text("Shizuku खोलो") }
                        }
                        else -> {
                            Text("Shizuku इंस्टॉल नहीं है (मुफ्त ऐप)", style = MaterialTheme.typography.bodySmall)
                            Button(onClick = {
                                ctx.startActivity(Intent(Intent.ACTION_VIEW,
                                    Uri.parse("https://play.google.com/store/apps/details?id=$SHIZUKU_PKG")))
                            }) { Text("Shizuku इंस्टॉल करो") }
                        }
                    }
                }
            }
        }

        // रैम सफाई
        item(span = { GridItemSpan(maxLineSpan) }) {
            Column {
                Button(onClick = {
                    scope.launch {
                        GameModeService.cleanMsg.value = "रैम साफ हो रही है..."
                        GameModeService.cleanMsg.value = Booster.cleanBackground(ctx, null)
                    }
                }) { Text("🧹 बैकग्राउंड ऐप्स साफ करो") }
                OutlinedButton(onClick = { showTips = true }) { Text("🚀 FPS बढ़ाने के असली टिप्स") }
                if (cleanMsg.isNotEmpty()) Text(cleanMsg, style = MaterialTheme.typography.bodySmall)
            }
        }

        item(span = { GridItemSpan(maxLineSpan) }) {
            val total = games.sumOf { today[it.pkg] ?: 0L }
            Text(
                if (usageOk) "मेरे गेम्स (आज कुल: ${fmt(total)})" else "मेरे गेम्स",
                style = MaterialTheme.typography.titleMedium
            )
        }

        items(games, key = { it.pkg }) { game ->
            Column(
                Modifier.clickable {
                    // टैप करते ही गेमिंग मोड ON; Shizuku हो तो Game Mode Performance; फिर गेम खुलेगा
                    if (startGameMode(ctx, game.pkg)) {
                        scope.launch {
                            withContext(Dispatchers.IO) { Shell.setGameMode(game.pkg, "performance") }
                            ctx.packageManager.getLaunchIntentForPackage(game.pkg)?.let { ctx.startActivity(it) }
                        }
                    }
                },
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Image(game.icon, game.label, Modifier.size(56.dp))
                Text(game.label, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.labelSmall)
                if (usageOk) Text(
                    "आज ${fmt(today[game.pkg] ?: 0L)}\nहफ्ता ${fmt(week[game.pkg] ?: 0L)}",
                    style = MaterialTheme.typography.labelSmall,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

const val SHIZUKU_PKG = "moe.shizuku.privileged.api"

@Composable
fun TipsDialog(onClose: () -> Unit) {
    val tips = listOf(
        "गेम की सेटिंग में ग्राफिक्स 'Smooth' रखो, रेज़ॉल्यूशन और शैडो कम करो। FPS बढ़ाने का यह सबसे असरदार तरीका है।",
        "फोन की सेटिंग्स > डिस्प्ले में रिफ्रेश रेट हाई (90/120Hz) रखो। 60Hz पर लॉक हो तो गेम उससे ऊपर नहीं जाएगा।",
        "Battery saver / Power saving मोड बंद रखो। यह CPU की स्पीड घटा देता है।",
        "फोन को ठंडा रखो: कवर हटाओ, चार्जिंग के साथ मत खेलो, धूप से बचो। गर्म होने पर फोन खुद FPS घटा देता है, यही सबसे बड़ी वजह है।",
        "स्टोरेज में कम से कम 10% जगह खाली रखो और गेम/सिस्टम अपडेट रखो।",
        "ऑनलाइन गेम में Wi-Fi (5GHz) बेहतर है और राउटर के पास बैठो। इससे पिंग/लैग घटता है।",
        "Android 12+ फोन में Game Mode / Game Dashboard होता है (Samsung में Game Launcher)। वहाँ गेम के लिए Performance चुनो। Shizuku चालू हो तो GameZone यह खुद कर देता है।"
    )
    AlertDialog(
        onDismissRequest = onClose,
        confirmButton = { TextButton(onClick = onClose) { Text("ठीक है") } },
        title = { Text("FPS बढ़ाने के असली तरीके") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                tips.forEach {
                    Text("• $it", style = MaterialTheme.typography.bodySmall)
                    Spacer(Modifier.height(8.dp))
                }
            }
        }
    )
}

@Composable
fun PermRow(text: String, ok: Boolean, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(text, Modifier.weight(1f), style = MaterialTheme.typography.bodySmall)
        if (ok) Text("✅") else TextButton(onClick = onClick) { Text("दो") }
    }
}

fun fmt(min: Long) = if (min >= 60) "${min / 60}घं ${min % 60}मि" else "${min}मि"

/** गेमिंग मोड चालू करता है। DND परमिशन न हो तो सेटिंग्स खोलकर false लौटाता है */
fun startGameMode(ctx: Context, gamePkg: String?): Boolean {
    val nm = ctx.getSystemService(NotificationManager::class.java)
    if (!nm.isNotificationPolicyAccessGranted) {
        Toast.makeText(ctx, "GameZone को DND की परमिशन दो, फिर वापस आओ", Toast.LENGTH_LONG).show()
        ctx.startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
        return false
    }
    val i = Intent(ctx, GameModeService::class.java)
    gamePkg?.let { i.putExtra(GameModeService.EXTRA_GAME, it) }
    ContextCompat.startForegroundService(ctx, i)
    return true
}

fun thermalLabel(status: Int) = when (status) {
    0 -> "ठंडा ✅"
    1 -> "हल्का गर्म"
    2 -> "गर्म ⚠️"
    else -> "बहुत गर्म 🔥"
}

fun loadGames(ctx: Context): List<GameApp> {
    val pm = ctx.packageManager
    val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
    val infos = pm.queryIntentActivities(intent, 0)
        .map { it.activityInfo.applicationInfo }
        .distinctBy { it.packageName }
        .filter { it.packageName != ctx.packageName }

    // कई गेम्स में category सेट नहीं होती, तब सारे ऐप्स दिखाते हैं
    val games = infos.filter { it.category == ApplicationInfo.CATEGORY_GAME }
    val list = if (games.isEmpty()) infos else games

    return list.map {
        GameApp(
            pm.getApplicationLabel(it).toString(),
            it.packageName,
            pm.getApplicationIcon(it).toBitmap(96, 96).asImageBitmap()
        )
    }.sortedBy { it.label.lowercase() }
}
GZEOF
mkdir -p "app/src/main/java/com/example/gamezone"
cat > "app/src/main/java/com/example/gamezone/GameModeService.kt" <<'GZEOF'
package com.example.gamezone

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class GameModeService : Service() {

    companion object {
        const val ACTION_STOP = "com.example.gamezone.STOP"
        const val EXTRA_GAME = "game_pkg"
        private const val CHANNEL_ID = "game_mode"
        private const val NOTIF_ID = 1

        private val _running = MutableStateFlow(false)
        val running: StateFlow<Boolean> = _running

        private val _thermal = MutableStateFlow(0)
        val thermalStatus: StateFlow<Int> = _thermal

        val cleanMsg = MutableStateFlow("")
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val handler = Handler(Looper.getMainLooper())
    private var overlay: TextView? = null
    private var handle: View? = null
    private var panel: LinearLayout? = null
    private var currentGame: String? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var previousFilter = NotificationManager.INTERRUPTION_FILTER_ALL
    private var dndChanged = false
    private var thermalListener: PowerManager.OnThermalStatusChangedListener? = null
    private var perfGame: String? = null
    private var savedBrightness = -1
    private var savedMode = Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL

    private val ticker = object : Runnable {
        override fun run() {
            overlay?.text = overlayText()
            handler.postDelayed(this, 2000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val game = intent?.getStringExtra(EXTRA_GAME)
        if (game != null) currentGame = game

        if (!_running.value) {
            createChannel()
            val type = if (Build.VERSION.SDK_INT >= 34)
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0
            ServiceCompat.startForeground(this, NOTIF_ID, buildNotification("गेमिंग मोड ON"), type)
            enableDnd()
            lockWifi()
            watchThermal()
            showOverlay()
            showHandle()
            _running.value = true
        }

        if (game != null && Build.VERSION.SDK_INT >= 31 && Shell.available()) perfGame = game
        scope.launch {
            cleanMsg.value = "रैम साफ हो रही है..."
            var msg = Booster.cleanBackground(this@GameModeService, game)
            if (perfGame != null) msg += "\nGame Mode: Performance ✅ (असर के लिए गेम एक बार दोबारा खोलना पड़ सकता है)"
            cleanMsg.value = msg
        }
        return START_NOT_STICKY
    }

    private fun enableDnd() {
        val nm = getSystemService(NotificationManager::class.java)
        if (nm.isNotificationPolicyAccessGranted) {
            previousFilter = nm.currentInterruptionFilter
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
            dndChanged = true
        }
    }

    private fun lockWifi() {
        val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_LOW_LATENCY, "gamezone:wifi")
            .apply {
                setReferenceCounted(false)
                acquire()
            }
    }

    private fun watchThermal() {
        val pm = getSystemService(PowerManager::class.java)
        val listener = PowerManager.OnThermalStatusChangedListener { status ->
            _thermal.value = status
            val hot = status >= PowerManager.THERMAL_STATUS_MODERATE
            adjustBrightness(hot)
            val text = if (hot) "⚠️ फोन गर्म है! चमक कम की, ग्राफिक्स भी कम करो"
            else "गेमिंग मोड ON"
            getSystemService(NotificationManager::class.java)
                .notify(NOTIF_ID, buildNotification(text))
        }
        thermalListener = listener
        pm.addThermalStatusListener(listener)
        _thermal.value = pm.currentThermalStatus
    }

    /** फोन गर्म हो तो स्क्रीन की चमक घटाता है (स्क्रीन गर्मी का बड़ा कारण है), ठंडा होने पर वापस */
    private fun adjustBrightness(hot: Boolean) {
        if (!Settings.System.canWrite(this)) return
        val cr = contentResolver
        if (hot && savedBrightness < 0) {
            savedBrightness = Settings.System.getInt(cr, Settings.System.SCREEN_BRIGHTNESS, 128)
            savedMode = Settings.System.getInt(
                cr, Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
            )
            Settings.System.putInt(
                cr, Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
            )
            Settings.System.putInt(
                cr, Settings.System.SCREEN_BRIGHTNESS,
                (savedBrightness * 0.6).toInt().coerceAtLeast(20)
            )
        } else if (!hot) {
            restoreBrightness()
        }
    }

    private fun restoreBrightness() {
        if (savedBrightness < 0 || !Settings.System.canWrite(this)) return
        val cr = contentResolver
        Settings.System.putInt(cr, Settings.System.SCREEN_BRIGHTNESS, savedBrightness)
        Settings.System.putInt(cr, Settings.System.SCREEN_BRIGHTNESS_MODE, savedMode)
        savedBrightness = -1
    }

    private fun showOverlay() {
        if (!Settings.canDrawOverlays(this)) return
        val tv = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 11f
            setPadding(16, 8, 16, 8)
            setBackgroundColor(0x99000000.toInt())
            text = overlayText()
        }
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 10
            y = 80
        }
        getSystemService(WindowManager::class.java).addView(tv, lp)
        overlay = tv
        handler.postDelayed(ticker, 2000)
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    /** स्क्रीन के दाएँ किनारे (बीच में) एक पतली पट्टी: बाएँ स्वाइप करो या टैप करो तो बूस्टर पैनल खुलता है */
    private fun showHandle() {
        if (!Settings.canDrawOverlays(this)) return
        val v = View(this).apply { setBackgroundColor(0x33FFFFFF) }
        var startX = 0f
        var fired = false
        v.setOnTouchListener { _, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startX = e.rawX
                    fired = false
                }
                MotionEvent.ACTION_MOVE -> if (!fired && startX - e.rawX > dp(24)) {
                    fired = true
                    togglePanel()
                }
                MotionEvent.ACTION_UP -> if (!fired && Math.abs(startX - e.rawX) < dp(8)) {
                    togglePanel()
                }
            }
            true
        }
        val lp = WindowManager.LayoutParams(
            dp(28), dp(200),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.END or Gravity.CENTER_VERTICAL }
        getSystemService(WindowManager::class.java).addView(v, lp)
        handle = v
    }

    private fun togglePanel() {
        if (panel != null) {
            closePanel()
            return
        }
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(12), dp(16), dp(12))
            setBackgroundColor(0xEE1B1B1F.toInt())
        }
        val info = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 13f
            text = overlayText()
        }
        box.addView(info)

        fun addButton(label: String, action: () -> Unit) {
            box.addView(Button(this).apply {
                text = label
                setOnClickListener { action() }
            })
        }
        addButton("🧹 रैम साफ करो") {
            scope.launch {
                info.text = "रैम साफ हो रही है..."
                val m = Booster.cleanBackground(this@GameModeService, currentGame)
                cleanMsg.value = m
                info.text = overlayText() + "\n" + m
            }
        }
        addButton("🔴 गेमिंग मोड बंद करो") {
            closePanel()
            stopSelf()
        }
        addButton("✕ पैनल बंद करो") { closePanel() }

        val lp = WindowManager.LayoutParams(
            dp(270), WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
            x = dp(36)
        }
        getSystemService(WindowManager::class.java).addView(box, lp)
        panel = box
    }

    private fun closePanel() {
        panel?.let {
            try { getSystemService(WindowManager::class.java).removeView(it) } catch (e: Exception) {}
        }
        panel = null
    }

    private fun overlayText(): String {
        val b = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temp = (b?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0) / 10f
        val level = b?.getIntExtra(BatteryManager.EXTRA_LEVEL, 0) ?: 0
        val mi = ActivityManager.MemoryInfo()
        getSystemService(ActivityManager::class.java).getMemoryInfo(mi)
        return "🔋 $level%   🌡 ${temp}°C\nरैम खाली: ${mi.availMem / 1048576} MB\nफोन: ${thermalLabel(_thermal.value)}"
    }

    private fun createChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "Game Mode", NotificationManager.IMPORTANCE_LOW
        )
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        val stopIntent = PendingIntent.getService(
            this, 0,
            Intent(this, GameModeService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("GameZone")
            .setContentText(text)
            .setOngoing(true)
            .addAction(0, "बंद करो", stopIntent)
            .build()
    }

    override fun onDestroy() {
        scope.cancel()
        handler.removeCallbacks(ticker)
        overlay?.let {
            try { getSystemService(WindowManager::class.java).removeView(it) } catch (e: Exception) {}
        }
        overlay = null
        closePanel()
        handle?.let {
            try { getSystemService(WindowManager::class.java).removeView(it) } catch (e: Exception) {}
        }
        handle = null
        restoreBrightness()
        if (dndChanged) {
            val nm = getSystemService(NotificationManager::class.java)
            if (nm.isNotificationPolicyAccessGranted) nm.setInterruptionFilter(previousFilter)
        }
        wifiLock?.let { if (it.isHeld) it.release() }
        thermalListener?.let { getSystemService(PowerManager::class.java).removeThermalStatusListener(it) }
        perfGame?.let { p -> Thread { Shell.setGameMode(p, "standard") }.start() }
        perfGame = null
        _running.value = false
        _thermal.value = 0
        super.onDestroy()
    }
}
GZEOF
mkdir -p "app/src/main/java/com/example/gamezone"
cat > "app/src/main/java/com/example/gamezone/Booster.kt" <<'GZEOF'
package com.example.gamezone

import android.app.ActivityManager
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.util.Calendar

object Booster {

    // इन नामों वाले ऐप्स कभी force-stop नहीं होते (अलार्म, कॉल, SMS, कीबोर्ड, सिस्टम)
    private val NEVER_STOP = listOf(
        "clock", "alarm", "dialer", "phone", "telecom", "contacts", "messag", "mms",
        "systemui", "inputmethod", "keyboard", "launcher", "settings", "bluetooth", "nfc"
    )

    /** बैकग्राउंड में पड़े ऐप्स के प्रोसेस बंद करता है (गेम और होम स्क्रीन को छोड़कर) */
    suspend fun cleanBackground(ctx: Context, exclude: String?): String = withContext(Dispatchers.IO) {
        val am = ctx.getSystemService(ActivityManager::class.java)
        val pm = ctx.packageManager
        fun avail(): Long {
            val mi = ActivityManager.MemoryInfo()
            am.getMemoryInfo(mi)
            return mi.availMem
        }
        val before = avail()
        val home = pm.resolveActivity(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), 0
        )?.activityInfo?.packageName
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val fg = foregroundPackage(ctx)
        val pkgs = pm.queryIntentActivities(launcher, 0)
            .map { it.activityInfo.packageName }
            .distinct()
            .filter { it != ctx.packageName && it != exclude && it != home && it != fg }
        val strict = ctx.getSharedPreferences("gz", Context.MODE_PRIVATE)
            .getBoolean("strict", false) && Shell.available() && (exclude != null || fg != null)
        val count: Int
        if (strict) {
            // असली force-stop (Shizuku से), ज़रूरी सिस्टम/अलार्म/डायलर ऐप्स छोड़कर
            val targets = pkgs.filter { p -> Shell.safe(p) && NEVER_STOP.none { p.contains(it) } }
            if (targets.isNotEmpty()) Shell.run(targets.joinToString("; ") { "am force-stop $it" })
            count = targets.size
        } else {
            pkgs.forEach { am.killBackgroundProcesses(it) }
            count = pkgs.size
        }
        delay(800)
        val freedMb = (avail() - before) / 1048576
        val how = if (strict) "असली बंद (force-stop)" else "साफ"
        if (freedMb > 0) "$count ऐप्स $how, करीब $freedMb MB रैम खाली हुई"
        else "$count ऐप्स $how (रैम पहले से ठीक थी, ज़्यादा फर्क नहीं पड़ा)"
    }

    /** अभी स्क्रीन पर सबसे ऊपर कौन सा ऐप है (यूसेज एक्सेस चाहिए); चल रहा गेम बंद न हो, इसलिए */
    fun foregroundPackage(ctx: Context): String? {
        if (!hasUsageAccess(ctx)) return null
        val usm = ctx.getSystemService(UsageStatsManager::class.java)
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 60 * 60 * 1000, now)
        val e = UsageEvents.Event()
        var last: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            if (e.eventType == UsageEvents.Event.ACTIVITY_RESUMED) last = e.packageName
        }
        return last
    }

    fun hasUsageAccess(ctx: Context): Boolean {
        val ops = ctx.getSystemService(AppOpsManager::class.java)
        return ops.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), ctx.packageName
        ) == AppOpsManager.MODE_ALLOWED
    }

    /** पैकेज -> मिनट (from से अब तक स्क्रीन पर खुला रहा) */
    fun usageMinutes(ctx: Context, from: Long): Map<String, Long> {
        val usm = ctx.getSystemService(UsageStatsManager::class.java)
        return usm.queryAndAggregateUsageStats(from, System.currentTimeMillis())
            .mapValues { it.value.totalTimeInForeground / 60000 }
    }

    fun startOfToday(): Long = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
    }.timeInMillis
}
GZEOF
mkdir -p "app/src/main/java/com/example/gamezone"
cat > "app/src/main/java/com/example/gamezone/Shell.kt" <<'GZEOF'
package com.example.gamezone

import android.content.pm.PackageManager
import android.os.Build
import rikka.shizuku.Shizuku

/** Shizuku के ज़रिए shell कमांड चलाने वाला हेल्पर */
object Shell {
    private val SAFE = Regex("[A-Za-z0-9._]+")
    fun safe(pkg: String) = SAFE.matches(pkg)

    fun running(): Boolean = try {
        Shizuku.pingBinder()
    } catch (e: Throwable) {
        false
    }

    fun available(): Boolean = try {
        Shizuku.pingBinder() && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (e: Throwable) {
        false
    }

    fun requestPermission() {
        try {
            Shizuku.requestPermission(1001)
        } catch (e: Throwable) {
        }
    }

    /** कमांड चलाकर आउटपुट (stdout+stderr) लौटाता है। मुख्य थ्रेड पर मत बुलाना */
    fun run(cmd: String): String {
        return try {
            val m = Shizuku::class.java.getDeclaredMethod(
                "newProcess",
                Array<String>::class.java, Array<String>::class.java, String::class.java
            )
            m.isAccessible = true
            val p = m.invoke(null, arrayOf("sh", "-c", "($cmd) 2>&1"), null, null) as Process
            val out = p.inputStream.bufferedReader().readText()
            p.waitFor()
            out
        } catch (e: Throwable) {
            "error: ${e.message}"
        }
    }

    /** Android 12+ का Game Mode (performance / standard / battery) किसी गेम के लिए सेट करता है */
    fun setGameMode(pkg: String, mode: String): Boolean {
        if (Build.VERSION.SDK_INT < 31 || !available() || !safe(pkg)) return false
        val out = run("cmd game mode $mode $pkg")
        return !out.contains("rror", ignoreCase = true) && !out.contains("Unknown", ignoreCase = true)
    }
}
GZEOF
