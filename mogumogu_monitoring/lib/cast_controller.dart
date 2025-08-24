import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class CastController {
  static const MethodChannel _channel = MethodChannel('youtube_cast_controller');
  
  // コールバック関数
  Function(bool)? onConnectionChanged;
  Function(bool)? onPlaybackStateChanged;
  Function(String, String, double, double)? onMediaInfoChanged;
  
  Timer? _statusTimer;
  bool _isInitialized = false;
  
  /// Cast制御を初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // ネイティブ側の初期化
      await _channel.invokeMethod('initialize');
      
      // 定期的な状態更新を開始
      _startStatusUpdates();
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Cast制御の初期化に失敗しました: $e');
    }
  }
  
  /// Cast接続状態を確認
  Future<bool> isConnected() async {
    try {
      final result = await _channel.invokeMethod('isConnected');
      return result ?? false;
    } catch (e) {
      developer.log('Cast接続状態の確認に失敗: $e');
      return false;
    }
  }
  
  /// 再生
  Future<void> play() async {
    try {
      await _channel.invokeMethod('play');
    } catch (e) {
      throw Exception('再生に失敗しました: $e');
    }
  }
  
  /// 一時停止
  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause');
    } catch (e) {
      throw Exception('一時停止に失敗しました: $e');
    }
  }
  
  /// 指定位置にシーク
  Future<void> seekTo(int positionSeconds) async {
    try {
      await _channel.invokeMethod('seekTo', {'position': positionSeconds});
    } catch (e) {
      throw Exception('シークに失敗しました: $e');
    }
  }
  
  /// 現在のメディア情報を取得
  Future<Map<String, dynamic>?> getCurrentMediaInfo() async {
    try {
      final result = await _channel.invokeMethod('getCurrentMediaInfo');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      developer.log('メディア情報の取得に失敗: $e');
      return null;
    }
  }
  
  /// 音量を設定
  Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume.clamp(0.0, 1.0)});
    } catch (e) {
      throw Exception('音量設定に失敗しました: $e');
    }
  }
  
  /// Cast可能なデバイスを検索
  Future<List<Map<String, String>>> discoverDevices() async {
    try {
      final result = await _channel.invokeMethod('discoverDevices');
      if (result != null) {
        return List<Map<String, String>>.from(
          result.map((device) => Map<String, String>.from(device))
        );
      }
      return [];
    } catch (e) {
      developer.log('デバイス検索に失敗: $e');
      return [];
    }
  }
  
  /// 指定したデバイスに接続
  Future<void> connectToDevice(String deviceId) async {
    try {
      await _channel.invokeMethod('connectToDevice', {'deviceId': deviceId});
    } catch (e) {
      throw Exception('デバイス接続に失敗しました: $e');
    }
  }
  
  /// Cast接続を切断
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } catch (e) {
      throw Exception('切断に失敗しました: $e');
    }
  }
  
  /// YouTube動画のURLを直接キャスト
  Future<void> castYouTubeVideo(String videoUrl) async {
    try {
      await _channel.invokeMethod('castYouTubeVideo', {'url': videoUrl});
    } catch (e) {
      throw Exception('YouTube動画のキャストに失敗しました: $e');
    }
  }
  
  /// 定期的な状態更新を開始
  void _startStatusUpdates() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _updateStatus();
    });
  }
  
  /// 状態を更新
  Future<void> _updateStatus() async {
    try {
      // 接続状態をチェック
      final connected = await isConnected();
      onConnectionChanged?.call(connected);
      
      if (connected) {
        // メディア情報を取得
        final mediaInfo = await getCurrentMediaInfo();
        if (mediaInfo != null) {
          final title = mediaInfo['title'] ?? '';
          final artist = mediaInfo['artist'] ?? '';
          final position = (mediaInfo['position'] ?? 0).toDouble();
          final duration = (mediaInfo['duration'] ?? 0).toDouble();
          final isPlaying = mediaInfo['isPlaying'] ?? false;
          
          onMediaInfoChanged?.call(title, artist, position, duration);
          onPlaybackStateChanged?.call(isPlaying);
        }
      }
    } catch (e) {
      developer.log('状態更新に失敗: $e');
    }
  }
  
  /// リソースを解放
  void dispose() {
    _statusTimer?.cancel();
    _statusTimer = null;
    _isInitialized = false;
  }
}

/// YouTube Cast制御用のネイティブブリッジ
class YouTubeCastBridge {
  static const MethodChannel _channel = MethodChannel('youtube_cast_bridge');
  
  /// YouTubeアプリの再生状態を取得
  static Future<Map<String, dynamic>?> getYouTubePlaybackState() async {
    try {
      final result = await _channel.invokeMethod('getYouTubePlaybackState');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      developer.log('YouTube再生状態の取得に失敗: $e');
      return null;
    }
  }
  
  /// YouTubeアプリに再生/一時停止コマンドを送信
  static Future<void> sendPlayPauseCommand() async {
    try {
      await _channel.invokeMethod('sendPlayPauseCommand');
    } catch (e) {
      throw Exception('再生/一時停止コマンドの送信に失敗しました: $e');
    }
  }
  
  /// YouTubeアプリに一時停止コマンドを送信
  static Future<void> sendPauseCommand() async {
    try {
      await _channel.invokeMethod('sendPauseCommand');
    } catch (e) {
      throw Exception('一時停止コマンドの送信に失敗しました: $e');
    }
  }
  
  /// YouTubeアプリに再生コマンドを送信
  static Future<void> sendPlayCommand() async {
    try {
      await _channel.invokeMethod('sendPlayCommand');
    } catch (e) {
      throw Exception('再生コマンドの送信に失敗しました: $e');
    }
  }
} 