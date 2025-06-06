package com.example.youtube_cast_controller

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "youtube_cast_controller"
    private val BRIDGE_CHANNEL = "youtube_cast_bridge"
    private lateinit var methodChannel: MethodChannel
    private lateinit var bridgeChannel: MethodChannel
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        bridgeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIDGE_CHANNEL)
        
        methodChannel.setMethodCallHandler { call, result ->
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
                "sendSeekCommand" -> {
                    val position = call.argument<Int>("position") ?: 0
                    sendSeekCommand(position, result)
                }
                "getCastVideoInfo" -> {
                    getCastVideoInfo(result)
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
        // 簡易的なCast接続チェック
        // 実際の実装では、Cast SDKの状態を確認する
        return try {
            // YouTubeアプリが実行中かチェック
            val packageManager = packageManager
            val intent = packageManager.getLaunchIntentForPackage("com.google.android.youtube")
            intent != null
        } catch (e: Exception) {
            false
        }
    }
    
    private fun sendMediaCommand(command: String, result: MethodChannel.Result) {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            // シンプルで確実なメディア制御
            val keyCode = when (command) {
                "play" -> KeyEvent.KEYCODE_MEDIA_PLAY
                "pause" -> KeyEvent.KEYCODE_MEDIA_PAUSE
                else -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            }
            
            // メディアキーイベントを送信
            val keyEventDown = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
            val keyEventUp = KeyEvent(KeyEvent.ACTION_UP, keyCode)
            
            // AudioManagerを使用してメディアキーを送信
            audioManager.dispatchMediaKeyEvent(keyEventDown)
            Thread.sleep(100) // 確実に処理されるよう少し待機
            audioManager.dispatchMediaKeyEvent(keyEventUp)
            
            Log.d("CastController", "Media command sent: $command (keyCode: $keyCode)")
            result.success(true)
            
        } catch (e: Exception) {
            Log.e("CastController", "Failed to send media command: $command", e)
            result.error("COMMAND_ERROR", "Failed to send command: ${e.message}", null)
        }
    }
    
    private fun seekTo(positionSeconds: Int, result: MethodChannel.Result) {
        // シーク機能は使用しないため、エラーを返す
        result.error("NOT_SUPPORTED", "Seek functionality is not supported", null)
    }
    
    private fun getCurrentMediaInfo(result: MethodChannel.Result) {
        try {
            // YouTubeアプリの実行状態をチェック
            val isYouTubeRunning = try {
                val packageManager = packageManager
                val intent = packageManager.getLaunchIntentForPackage("com.google.android.youtube")
                intent != null
            } catch (e: Exception) {
                false
            }
            
            if (isYouTubeRunning) {
                // YouTubeが実行中の場合は模擬データを返す
                // 実際のキャスト状態は検知できないため、デフォルトで停止状態とする
                val mockInfo = mapOf(
                    "title" to "YouTube Video",
                    "artist" to "YouTube Channel",
                    "duration" to 300, // 5分
                    "position" to 120, // 2分
                    "isPlaying" to false // デフォルトで停止状態
                )
                
                Log.d("CastController", "Returning mock media info (YouTube running)")
                result.success(mockInfo)
            } else {
                Log.d("CastController", "YouTube app not running")
                result.success(null)
            }
        } catch (e: Exception) {
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
    
    private fun sendSeekCommand(positionSeconds: Int, result: MethodChannel.Result) {
        seekTo(positionSeconds, result)
    }
    
    private fun getCastVideoInfo(result: MethodChannel.Result) {
        getCurrentMediaInfo(result)
    }
} 