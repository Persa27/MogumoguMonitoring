import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:developer' as developer;
import 'cast_controller.dart';

void main() {
  runApp(const YouTubeCastControllerApp());
}

class YouTubeCastControllerApp extends StatelessWidget {
  const YouTubeCastControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Cast Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CastControllerPage(),
    );
  }
}

class CastControllerPage extends StatefulWidget {
  const CastControllerPage({super.key});

  @override
  State<CastControllerPage> createState() => _CastControllerPageState();
}

class _CastControllerPageState extends State<CastControllerPage> {
  final CastController _castController = CastController();
  bool _isConnected = false;
  bool _isPlaying = false;
  String _currentTitle = '';
  String _currentArtist = '';
  bool _isLoading = false;
  bool _hasUserInteracted = false; // ユーザーが操作したかどうかを追跡

  @override
  void initState() {
    super.initState();
    _initializeCastController();
  }

  Future<void> _initializeCastController() async {
    setState(() => _isLoading = true);
    
    try {
      await _castController.initialize();
      _castController.onConnectionChanged = (connected) {
        setState(() => _isConnected = connected);
      };
      
      _castController.onPlaybackStateChanged = (isPlaying) {
        // ユーザーが操作していない場合のみ外部からの状態変更を受け入れる
        if (!_hasUserInteracted) {
          setState(() => _isPlaying = isPlaying);
        }
      };
      
      _castController.onMediaInfoChanged = (title, artist, position, duration) {
        setState(() {
          _currentTitle = title;
          _currentArtist = artist;
        });
      };
      
      // 初期状態をチェック
      await _checkCastStatus();
    } catch (e) {
      _showErrorSnackBar('Cast制御の初期化に失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkCastStatus() async {
    try {
      final connected = await _castController.isConnected();
      setState(() => _isConnected = connected);
      
      if (connected) {
        final mediaInfo = await _castController.getCurrentMediaInfo();
        if (mediaInfo != null) {
          setState(() {
            _currentTitle = mediaInfo['title'] ?? '';
            _currentArtist = mediaInfo['artist'] ?? '';
            
            // ユーザーが操作していない場合のみ、外部の再生状態を使用
            if (!_hasUserInteracted) {
              _isPlaying = mediaInfo['isPlaying'] ?? false;
            }
          });
        }
      } else {
        // 接続が切れた場合は状態をリセット
        setState(() {
          _hasUserInteracted = false;
          _isPlaying = false;
        });
      }
    } catch (e) {
      developer.log('Cast状態の確認に失敗: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (!_isConnected) {
      _showErrorSnackBar('Castデバイスに接続されていません');
      return;
    }

    try {
      HapticFeedback.lightImpact();
      
      // ユーザーが操作したことを記録
      _hasUserInteracted = true;
      
      // 現在の状態を保存
      final wasPlaying = _isPlaying;
      
      if (wasPlaying) {
        await _castController.pause();
        setState(() => _isPlaying = false);  // 即座に状態を更新
        _showInfoSnackBar('一時停止しました');
        developer.log('Paused - UI updated to show play button');
      } else {
        await _castController.play();
        setState(() => _isPlaying = true);   // 即座に状態を更新
        _showInfoSnackBar('再生しました');
        developer.log('Playing - UI updated to show pause button');
      }
      
    } catch (e) {
      _showErrorSnackBar('再生制御に失敗しました: $e');
      // エラーの場合は元の状態に戻す
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  // 状態をリセットする機能を追加
  void _resetPlaybackState() {
    setState(() {
      _hasUserInteracted = false;
      _isPlaying = false;
    });
    _checkCastStatus();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Cast Controller'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? MdiIcons.cast : MdiIcons.castOff),
            onPressed: _checkCastStatus,
            tooltip: _isConnected ? 'Cast接続中' : 'Cast未接続',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 接続状態表示
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _isConnected ? MdiIcons.cast : MdiIcons.castOff,
                            color: _isConnected ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isConnected ? 'Cast接続中' : 'Cast未接続',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  _isConnected
                                      ? 'TVにキャストしているYouTube動画を制御できます'
                                      : 'YouTubeアプリでTVにキャストしてください',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // メディア情報表示
                  if (_isConnected && _currentTitle.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _currentTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_currentArtist.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _currentArtist,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            // 再生状態表示
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isPlaying ? Icons.play_arrow : Icons.pause,
                                  color: _isPlaying ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isPlaying ? '再生中' : '一時停止中',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _isPlaying ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // 再生制御ボタン（中央に大きく配置）
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      boxShadow: _isConnected ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: IconButton(
                      onPressed: _isConnected ? _togglePlayPause : null,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 64,
                      tooltip: _isPlaying ? '一時停止' : '再生',
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 状態表示テキスト
                  if (_isConnected) ...[
                    Text(
                      _isPlaying ? 'タップして一時停止' : 'タップして再生',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // デバッグ情報（開発中のみ表示）
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'デバッグ情報',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ユーザー操作: ${_hasUserInteracted ? "あり" : "なし"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '再生状態: ${_isPlaying ? "再生中" : "停止中"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // ボタン群
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 状態更新ボタン
                      ElevatedButton.icon(
                        onPressed: _checkCastStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('状態更新'),
                      ),
                      
                      // 状態リセットボタン
                      ElevatedButton.icon(
                        onPressed: _isConnected ? _resetPlaybackState : null,
                        icon: const Icon(Icons.restore),
                        label: const Text('状態リセット'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _castController.dispose();
    super.dispose();
  }
}
