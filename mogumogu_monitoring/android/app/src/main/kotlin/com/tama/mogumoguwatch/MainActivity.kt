package com.tama.mogumoguwatch

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CAST_CHANNEL = "youtube_cast_controller"
    private val BRIDGE_CHANNEL = "youtube_cast_bridge"
    private lateinit var castChannel: MethodChannel
    private lateinit var bridgeChannel: MethodChannel
    
    // 対応する動画アプリのパッケージ名
    private val supportedVideoApps = listOf(
        "com.google.android.youtube",           // YouTube
        "com.amazon.avod.thirdpartyclient",    // Amazon Prime Video
        "jp.co.nttdocomo.danimeapp"             // dアニメストア
    )
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // YouTube Cast制御チャンネル
        castChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAST_CHANNEL)
        bridgeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIDGE_CHANNEL)
        
        castChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    initializeCast(result)
                }
                "isConnected" -> {
                    result.success(checkCastConnection())
                }
                "play" -> {
                    sendMediaCommand("play", result)
                }
                "pause" -> {
                    sendMediaCommand("pause", result)
                }
                "seekTo" -> {
                    val position = call.argument<Int>("position") ?: 0
                    seekTo(position, result)
                }
                "getCurrentMediaInfo" -> {
                    getCurrentMediaInfo(result)
                }
                "setVolume" -> {
                    val volume = call.argument<Double>("volume") ?: 0.5
                    setVolume(volume, result)
                }
                "discoverDevices" -> {
                    discoverDevices(result)
                }
                "connectToDevice" -> {
                    val deviceId = call.argument<String>("deviceId") ?: ""
                    connectToDevice(deviceId, result)
                }
                "disconnect" -> {
                    disconnect(result)
                }
                "castYouTubeVideo" -> {
                    val url = call.argument<String>("url") ?: ""
                    castYouTubeVideo(url, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        bridgeChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getYouTubePlaybackState" -> {
                    getYouTubePlaybackState(result)
                }
                "sendPlayPauseCommand" -> {
                    sendPlayPauseCommand(result)
                }
                "sendPauseCommand" -> {
                    sendMediaCommand("pause", result)
                }
                "sendPlayCommand" -> {
                    sendMediaCommand("play", result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun initializeCast(result: MethodChannel.Result) {
        try {
            Log.d("CastController", "Cast controller initialized")
            result.success(true)
        } catch (e: Exception) {
            Log.e("CastController", "Cast initialization failed", e)
            result.error("INIT_ERROR", "Cast initialization failed: ${e.message}", null)
        }
    }
    
    private fun checkCastConnection(): Boolean {
        return try {
            // 1. 対応する動画アプリのいずれかが実行中かチェック
            val runningApp = supportedVideoApps.find { packageName ->
                isAppRunning(packageName)
            }
            
            // 2. メディアセッションで動画アプリの再生状態をチェック
            val hasVideoMediaSession = hasActiveMediaSession()
            
            val isConnected = runningApp != null && hasVideoMediaSession
            
            Log.d("CastController", "Cast connection check - Running app: $runningApp, Media session: $hasVideoMediaSession, Connected: $isConnected")
            
            isConnected
        } catch (e: Exception) {
            Log.e("CastController", "Failed to check cast connection", e)
            false
        }
    }
    
    private fun isAppRunning(packageName: String): Boolean {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningApps = activityManager.runningAppProcesses
            
            runningApps?.any { processInfo ->
                processInfo.processName == packageName && 
                processInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            } ?: false
        } catch (e: Exception) {
            Log.e("CastController", "Failed to check if app is running: $packageName", e)
            false
        }
    }
    
    private fun hasActiveMediaSession(): Boolean {
        return try {
            val mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
            val activeSessions = mediaSessionManager.getActiveSessions(null)
            
            val hasVideoSession = activeSessions.any { controller ->
                val packageName = controller.packageName
                Log.d("CastController", "Active media session: $packageName")
                supportedVideoApps.contains(packageName)
            }
            
            Log.d("CastController", "Video app media session found: $hasVideoSession")
            hasVideoSession
        } catch (e: Exception) {
            Log.e("CastController", "Failed to check media sessions", e)
            false
        }
    }
    
    private fun sendMediaCommand(command: String, result: MethodChannel.Result) {
        try {
            Log.d("CastController", "Attempting to send media command: $command")
            
            // 方法1: MediaSessionManagerを使用してYouTubeのメディアコントローラーを取得
            val success1 = sendCommandViaMediaSession(command)
            
            // 方法2: AudioManagerのメディアキーイベント
            val success2 = sendCommandViaAudioManager(command)
            
            // 方法3: YouTubeアプリに直接Intentを送信
            val success3 = sendCommandViaIntent(command)
            
            Log.d("CastController", "Media command results - MediaSession: $success1, AudioManager: $success2, Intent: $success3")
            
            if (success1 || success2 || success3) {
                result.success(true)
            } else {
                result.error("COMMAND_ERROR", "All media command methods failed", null)
            }
            
        } catch (e: Exception) {
            Log.e("CastController", "Failed to send media command: $command", e)
            result.error("COMMAND_ERROR", "Failed to send command: ${e.message}", null)
        }
    }
    
    private fun sendCommandViaMediaSession(command: String): Boolean {
        return try {
            val mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
            val activeSessions = mediaSessionManager.getActiveSessions(null)
            
            val videoController = activeSessions.find { controller ->
                supportedVideoApps.contains(controller.packageName)
            }
            
            if (videoController != null) {
                when (command) {
                    "play" -> videoController.transportControls.play()
                    "pause" -> videoController.transportControls.pause()
                    else -> {
                        // 現在の再生状態を取得して切り替え
                        val playbackState = videoController.playbackState
                        if (playbackState?.state == android.media.session.PlaybackState.STATE_PLAYING) {
                            videoController.transportControls.pause()
                        } else {
                            videoController.transportControls.play()
                        }
                    }
                }
                Log.d("CastController", "Media command sent via MediaSession: $command to ${videoController.packageName}")
                true
            } else {
                Log.w("CastController", "Video app media controller not found")
                false
            }
        } catch (e: Exception) {
            Log.e("CastController", "Failed to send command via MediaSession", e)
            false
        }
    }
    
    private fun sendCommandViaAudioManager(command: String): Boolean {
        return try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            val keyCode = when (command) {
                "play" -> KeyEvent.KEYCODE_MEDIA_PLAY
                "pause" -> KeyEvent.KEYCODE_MEDIA_PAUSE
                else -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            }
            
            val keyEventDown = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
            val keyEventUp = KeyEvent(KeyEvent.ACTION_UP, keyCode)
            
            audioManager.dispatchMediaKeyEvent(keyEventDown)
            Thread.sleep(50)
            audioManager.dispatchMediaKeyEvent(keyEventUp)
            
            Log.d("CastController", "Media command sent via AudioManager: $command (keyCode: $keyCode)")
            true
        } catch (e: Exception) {
            Log.e("CastController", "Failed to send command via AudioManager", e)
            false
        }
    }
    
    private fun sendCommandViaIntent(command: String): Boolean {
        return try {
            // 実行中の動画アプリを探して、そのアプリにIntentを送信
            val runningApp = supportedVideoApps.find { packageName ->
                isAppRunning(packageName)
            }
            
            if (runningApp != null) {
                val intent = when (runningApp) {
                    "com.google.android.youtube" -> {
                        Intent("com.google.android.youtube.intent.action.MEDIA_CONTROL")
                    }
                    "com.amazon.avod.thirdpartyclient" -> {
                        Intent("com.amazon.avod.intent.action.MEDIA_CONTROL")
                    }
                    "jp.co.nttdocomo.danimeapp" -> {
                        Intent("jp.co.nttdocomo.danimeapp.intent.action.MEDIA_CONTROL")
                    }
                    else -> {
                        Intent("android.intent.action.MEDIA_CONTROL")
                    }
                }
                
                intent.setPackage(runningApp)
                intent.putExtra("command", command)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                
                sendBroadcast(intent)
                Log.d("CastController", "Media command sent via Intent: $command to $runningApp")
                true
            } else {
                Log.w("CastController", "No running video app found for Intent")
                false
            }
        } catch (e: Exception) {
            Log.e("CastController", "Failed to send command via Intent", e)
            false
        }
    }
    
    private fun seekTo(positionSeconds: Int, result: MethodChannel.Result) {
        // シーク機能は使用しないため、エラーを返す
        result.error("NOT_SUPPORTED", "Seek functionality is not supported", null)
    }
    
    private fun getCurrentMediaInfo(result: MethodChannel.Result) {
        try {
            val mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
            val activeSessions = mediaSessionManager.getActiveSessions(null)
            
            val videoController = activeSessions.find { controller ->
                supportedVideoApps.contains(controller.packageName)
            }
            
            if (videoController != null) {
                val metadata = videoController.metadata
                val playbackState = videoController.playbackState
                val packageName = videoController.packageName
                
                val appName = when (packageName) {
                    "com.google.android.youtube" -> "YouTube"
                    "com.amazon.avod.thirdpartyclient" -> "Amazon Prime Video"
                    "jp.co.nttdocomo.danimeapp" -> "dアニメストア"
                    else -> "Video App"
                }
                
                val title = metadata?.getString(android.media.MediaMetadata.METADATA_KEY_TITLE) ?: "$appName Video"
                val artist = metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST) ?: "$appName Channel"
                val duration = metadata?.getLong(android.media.MediaMetadata.METADATA_KEY_DURATION) ?: 0L
                val position = playbackState?.position ?: 0L
                val isPlaying = playbackState?.state == android.media.session.PlaybackState.STATE_PLAYING
                
                val mediaInfo = mapOf(
                    "title" to title,
                    "artist" to artist,
                    "duration" to (duration / 1000).toInt(), // ミリ秒を秒に変換
                    "position" to (position / 1000).toInt(), // ミリ秒を秒に変換
                    "isPlaying" to isPlaying,
                    "appName" to appName,
                    "packageName" to packageName
                )
                
                Log.d("CastController", "$appName media info - Title: $title, Playing: $isPlaying")
                result.success(mediaInfo)
            } else {
                Log.d("CastController", "Video app media controller not found")
                result.success(null)
            }
        } catch (e: Exception) {
            Log.e("CastController", "Failed to get media info", e)
            result.error("MEDIA_INFO_ERROR", "Failed to get media info: ${e.message}", null)
        }
    }
    
    private fun setVolume(volume: Double, result: MethodChannel.Result) {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val targetVolume = (volume * maxVolume).toInt()
            
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
            
            Log.d("CastController", "Volume set to: $volume")
            result.success(true)
        } catch (e: Exception) {
            result.error("VOLUME_ERROR", "Set volume failed: ${e.message}", null)
        }
    }
    
    private fun discoverDevices(result: MethodChannel.Result) {
        // デバイス検索は現在未実装
        result.success(emptyList<Map<String, String>>())
    }
    
    private fun connectToDevice(deviceId: String, result: MethodChannel.Result) {
        // デバイス接続は現在未実装
        result.success(true)
    }
    
    private fun disconnect(result: MethodChannel.Result) {
        try {
            Log.d("CastController", "Disconnect requested")
            result.success(true)
        } catch (e: Exception) {
            result.error("DISCONNECT_ERROR", "Disconnect failed: ${e.message}", null)
        }
    }
    
    private fun castYouTubeVideo(url: String, result: MethodChannel.Result) {
        try {
            // YouTubeアプリでURLを開く
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
            intent.setPackage("com.google.android.youtube")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
            } else {
                result.error("NO_YOUTUBE_APP", "YouTube app not found", null)
            }
        } catch (e: Exception) {
            result.error("CAST_ERROR", "Failed to cast video: ${e.message}", null)
        }
    }
    
    private fun getYouTubePlaybackState(result: MethodChannel.Result) {
        // YouTube再生状態の取得は現在未実装
        result.success(null)
    }
    
    private fun sendPlayPauseCommand(result: MethodChannel.Result) {
        sendMediaCommand("play_pause", result)
    }
}
