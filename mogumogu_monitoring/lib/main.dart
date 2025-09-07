import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'cast_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  
  runApp(MogumoguApp(cameras: cameras));
}

/// 共通の読み込み画面
Widget buildLoadingScreen() {
  return Scaffold(
    body: Column(
      children: [
        // Top status bar area (スマートフォンのトップバー用スペース)
        Container(
          width: double.infinity,
          height: 40, // トップバー用のスペース
          color: Colors.white,
        ),
        
        // Rest of the screen
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 残りの画面の高さに基づいて背景画像とボタンエリアの比率を調整
              final remainingHeight = constraints.maxHeight;
              final backgroundHeight = remainingHeight * 0.7; // 残り画面の70%を背景画像に
              
              return Column(
                children: [
                  // Background image area (70%の高さ)
                  Container(
                    width: double.infinity,
                    height: backgroundHeight,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/loading.png'),
                        fit: BoxFit.fitWidth, // 幅に合わせてフィット
                        alignment: Alignment.topCenter, // 上部中央揃い
                      ),
                      // Fallback gradient if image fails to load
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE8F5E8),
                          Color(0xFFF1F8E9),
                        ],
                      ),
                    ),
                  ),
                  
                  // Empty area (残り30%)
                  Expanded(
                    child: Container(
                      color: Color(0xFFF4FBF8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// 共通の基本設定UI関数
Widget buildBasicSettings(
  StateSetter setDialogState,
  double movementThreshold,
  double jawThreshold,
  double openThreshold,
  double headMovementThreshold,
  int notEatingDuration,
  bool alertOnNoFaceDetected,
  Function(double) onMovementThresholdChanged,
  Function(double) onJawThresholdChanged,
  Function(double) onOpenThresholdChanged,
  Function(double) onHeadMovementThresholdChanged,
  Function(int) onNotEatingDurationChanged,
  Function(bool) onAlertOnNoFaceDetectedChanged,
) {
  return Column(
    children: [
      // 動きの閾値設定
      ListTile(
        title: const Text('動きの閾値'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: movementThreshold,
              min: 0.005,
              max: 0.2,
              divisions: 39,
              label: movementThreshold.toStringAsFixed(3),
              onChanged: (value) {
                setDialogState(() {
                  onMovementThresholdChanged(value);
                });
              },
            ),
            const Text(
              '値が小さいほど小さな動きでも検知します（0.005-0.2）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      // 顎の動きの閾値設定
      ListTile(
        title: const Text('顎の動きの閾値'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: jawThreshold,
              min: 0.005,
              max: 0.2,
              divisions: 39,
              label: jawThreshold.toStringAsFixed(3),
              onChanged: (value) {
                setDialogState(() {
                  onJawThresholdChanged(value);
                });
              },
            ),
            const Text(
              '顎の縦方向の動きを検知する閾値（0.005-0.2）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      // 開閉度の閾値設定
      ListTile(
        title: const Text('口の開閉度の閾値'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: openThreshold,
              min: 0.005,
              max: 0.2,
              divisions: 39,
              label: openThreshold.toStringAsFixed(3),
              onChanged: (value) {
                setDialogState(() {
                  onOpenThresholdChanged(value);
                });
              },
            ),
            const Text(
              '口の開閉を検知する閾値（0.005-0.2）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      // 頭の動きの閾値設定
      ListTile(
        title: const Text('頭の動きの閾値'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: headMovementThreshold,
              min: 0.01,
              max: 0.5,
              divisions: 49,
              label: headMovementThreshold.toStringAsFixed(3),
              onChanged: (value) {
                setDialogState(() {
                  onHeadMovementThresholdChanged(value);
                });
              },
            ),
            const Text(
              '頭の急激な動きを検知する閾値（0.01-0.5）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      // 警告までの時間設定
      ListTile(
        title: const Text('警告までの時間'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: notEatingDuration.toDouble(),
              min: 1,
              max: 60,
              divisions: 11,
              label: '${notEatingDuration}秒',
              onChanged: (value) {
                setDialogState(() {
                  onNotEatingDurationChanged(value.round());
                });
              },
            ),
            const Text(
              '食べていないと判断してから警告するまでの時間（1-60秒）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      // 顔検知なしアラート設定
      ListTile(
        title: const Text('顔検知なしアラート'),
        subtitle: const Text('顔が検知されない時に警告を表示'),
        trailing: Switch(
          value: alertOnNoFaceDetected,
          onChanged: (value) {
            setDialogState(() {
              onAlertOnNoFaceDetectedChanged(value);
            });
          },
        ),
      ),
    ],
  );
}

class MogumoguApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MogumoguApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'もぐもぐ監視アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(cameras: cameras),
    );
  }
}

/// ホーム画面
class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    // ステータスバーを白色に設定
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8), // Figmaのベース背景色
      body: Column(
        children: [
          // Top status bar area (スマートフォンのトップバー用スペース)
          Container(
            width: double.infinity,
            height: 40, // トップバー用のスペース
            color: Colors.white,
          ),
          
          // Rest of the screen
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 残りの画面の高さに基づいて背景画像とボタンエリアの比率を調整
                final remainingHeight = constraints.maxHeight;
                final backgroundHeight = remainingHeight * 0.7; // 残り画面の70%を背景画像に
                
                return Column(
                  children: [
                    // Background image area (70%の高さ)
                    Container(
                      width: double.infinity,
                      height: backgroundHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/main_background.png'),
                    fit: BoxFit.fitWidth, // 幅に合わせてフィット
                    alignment: Alignment.topCenter, // 上部中央揃い
                    onError: (exception, stackTrace) {
                      print('Background image failed to load: $exception');
                    },
                  ),
                  // Fallback gradient if image fails to load
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE8F5E8),
                      Color(0xFFF1F8E9),
                    ],
                  ),
                ),
              ),
              
              // Button area (背景画像の下に配置 - 残り30%)
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF4FBF8), // Figmaのベース背景色
                  padding: const EdgeInsets.symmetric(horizontal: 62.0, vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // 上詰め配置
                    children: [
                  
                // 音声再生モードボタン
                Container(
                  width: 288,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('🏠 Navigating to AudioModeScreen from home');
                      // 全てのルートをクリアして確実に新しい画面のみ表示
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioModeScreen(cameras: cameras),
                        ),
                        (route) => false, // 全ての前の画面を削除
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFD9E9D),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mic,
                          size: 24,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '音声再生モード',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Noto Sans JP',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  
                const SizedBox(height: 10),
                
                // 動画停止モードボタン
                Container(
                  width: 288,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('🏠 Navigating to VideoModeScreen from home');
                      // 全てのルートをクリアして確実に新しい画面のみ表示
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoModeScreen(cameras: cameras),
                        ),
                        (route) => false, // 全ての前の画面を削除
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF65B9D0),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.tv,
                          size: 24,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '動画停止モード',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Noto Sans JP',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  
                const SizedBox(height: 20),
                
                // 説明を見るボタン
                Container(
                  width: 150,
                  height: 39,
                  child: OutlinedButton(
                    onPressed: () {
                      _showHelpDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF828282),
                      side: const BorderSide(
                        color: Color(0xFF828282),
                        width: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      '説明を見る',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Noto Sans JP',
                      ),
                    ),
                  ),
                ),
                // const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('使用方法'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎯 基本的な使い方',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('1. カメラに顔を向けてください'),
                Text('2. 緑色の枠が顔の周りに表示されます'),
                Text('3. 赤い点が唇の位置を示します'),
                Text('4. 食事をすると顔枠の上に「食べています」と表示されます'),
                SizedBox(height: 16),
                Text(
                  '🎵 音声再生モード',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 食べていない状態が続くと音声で警告します'),
                Text('• ベル音、アラーム音、カスタム音声から選択可能'),
                SizedBox(height: 16),
                Text(
                  '📺 動画停止モード',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 食べていない状態が続くとYouTube動画を停止します'),
                Text('• 食べ始めると自動的に再生を再開します'),
                SizedBox(height: 16),
                Text(
                  '⚙️ 設定について',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 動きの閾値: 唇の動きの感度調整'),
                Text('• 判定時間: 食べていないと判断する時間'),
                Text('• カメラ切り替え: フロント/バックカメラの選択'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}

/// 音声再生モード画面
class AudioModeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AudioModeScreen({super.key, required this.cameras});

  @override
  State<AudioModeScreen> createState() => _AudioModeScreenState();
}

// 個別の顔の状態を管理するクラス
class FaceState {
  final String id;
  bool isEating;
  DateTime? lastMovementTime;
  Offset? previousMouthPosition;
  Timer? notEatingTimer;
  Timer? audioTimer;
  bool showNotEatingMessage;
  DateTime? currentEatingStartTime;
  int currentEatingDuration; // 現在の連続食事時間（秒）
  
  // 精度向上のための追加フィールド
  Offset? prevFaceCenter;      // 顔全体の平行移動を保存
  double? baselineMouthRatio;  // 通常時の口開閉比（自動キャリブレーション用）
  bool calibrated = false;     // ベースラインが確定したか
  Offset? prevJawCenter;       // 顎の動きを追跡
  Offset? prevNoseBase;        // 鼻先の平行移動を記録（頭の動き補正用）
  
  FaceState(this.id) 
    : isEating = false,
      lastMovementTime = null,
      previousMouthPosition = null,
      notEatingTimer = null,
      audioTimer = null,
      showNotEatingMessage = false,
      currentEatingStartTime = null,
      currentEatingDuration = 0,
      prevFaceCenter = null,
      baselineMouthRatio = null,
      prevJawCenter = null,
      prevNoseBase = null;
      
  // 現在の連続食事時間を取得（秒）
  int getCurrentEatingDuration() {
    if (currentEatingStartTime == null || !isEating) return 0;
    return DateTime.now().difference(currentEatingStartTime!).inSeconds;
  }
      
  void dispose() {
    notEatingTimer?.cancel();
    audioTimer?.cancel();
  }
}

class _AudioModeScreenState extends State<AudioModeScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  AudioPlayer? _audioPlayer;
  CastController? _castController; // YouTube Cast制御
  
  bool _isDetecting = false;
  bool _isInitialized = false;
  String _initializationError = '';
  
  List<Face> _faces = [];
  Map<String, FaceState> _faceStates = {};
  Timer? _uiUpdateTimer; // UI更新用タイマー
  Timer? _groupAudioTimer; // グループ音声制御用タイマー
  
  // YouTube Cast制御関連
  bool _isCastConnected = false;
  bool _isCastPlaying = false;
  String _currentCastTitle = '';
  
  // 設定値
  double _movementThreshold = 0.012; // 唇の動きの閾値（垂直成分のみ、顔高さ比で設定）
  double _jawThreshold = 0.020; // 顎の動きの閾値
  double _openThreshold = 0.030; // 開閉度の閾値
  double _headMovementThreshold = 0.050; // 頭の動きの閾値（急激な動きを検知）
  int _notEatingDuration = 10; // 食べていないと判断する秒数（1秒刻み）
  String _audioFile = 'bell'; // 音声ファイル
  String _customAudioPath = ''; // カスタム音声ファイルのパス
  bool _useBackCamera = true; // バックカメラを使用するか
  bool _isSettingsOpen = false; // 設定モーダルが開いているかどうか
  
  // 警告アクション設定
  String _warningAction = 'audio'; // 'audio' または 'youtube_cast'
  bool _enableYouTubeCast = false; // YouTube Cast制御を有効にするか
  
  // 顔検知なしアラート設定
  bool _alertOnNoFaceDetected = false; // 顔検知なしアラートのON/OFF
  Timer? _noFaceDetectionTimer; // 顔が検知されない時間を追跡するタイマー
  DateTime? _lastFaceDetectionTime; // 最後に顔が検知された時間
  bool _isPlayingNoFaceAudio = false; // 顔検知なし音声再生中フラグ
  
  // セッション開始時間
  DateTime? _sessionStartTime;
  
  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    // 音声再生モードに固定
    _warningAction = 'audio';
    _enableYouTubeCast = false;
    debugPrint('🎵 AudioModeScreen initialized - Warning action: $_warningAction, YouTube enabled: $_enableYouTubeCast');
    _initializeApp();
    
    // UI更新タイマーを開始（1秒ごとに更新）
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // 連続食事時間表示の更新のためのsetState
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('Starting app initialization...');
      
      // 権限チェック
      await _checkPermissions();
      debugPrint('Permissions checked');
      
      await _loadSettings();
      debugPrint('Settings loaded');
      
      await _initializeCamera();
      debugPrint('Camera initialized');
      
      await _initializeFaceDetector();
      debugPrint('Face detector initialized');
      
      await _initializeAudioPlayer();
      debugPrint('Audio player initialized');
      
      // YouTube Cast制御が有効な場合のみ初期化
      if (_enableYouTubeCast) {
        await _initializeCastController();
        debugPrint('Cast controller initialized');
      }
      
      setState(() {
        _isInitialized = true;
      });
      debugPrint('App initialization completed');
    } catch (e) {
      debugPrint('Initialization error: $e');
      setState(() {
        _initializationError = e.toString();
      });
    }
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    debugPrint('Camera permission status: $cameraStatus');
    
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      debugPrint('Camera permission request result: $result');
      
      if (result.isDenied) {
        throw Exception('カメラの権限が必要です。設定からカメラの権限を有効にしてください。');
      }
    }
    
    if (cameraStatus.isPermanentlyDenied) {
      throw Exception('カメラの権限が永続的に拒否されています。設定からカメラの権限を有効にしてください。');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _movementThreshold = prefs.getDouble('movement_threshold') ?? 0.012;
      _jawThreshold = prefs.getDouble('jaw_threshold') ?? 0.020;
      _openThreshold = prefs.getDouble('open_threshold') ?? 0.030;
      _headMovementThreshold = prefs.getDouble('head_movement_threshold') ?? 0.050;
      _notEatingDuration = prefs.getInt('not_eating_duration') ?? 10;
      _audioFile = prefs.getString('audio_file') ?? 'bell';  // デフォルトをbellに変更
      _customAudioPath = prefs.getString('custom_audio_path') ?? '';
      _useBackCamera = prefs.getBool('use_back_camera') ?? true;
      // AudioModeScreenでは設定に関係なく音声再生モードに固定
      _warningAction = 'audio';
      _enableYouTubeCast = false;
      _alertOnNoFaceDetected = prefs.getBool('alert_on_no_face_detected') ?? false;      
    });
    debugPrint('🎵 AudioModeScreen settings loaded - Warning action: $_warningAction, YouTube enabled: $_enableYouTubeCast');
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('movement_threshold', _movementThreshold);
    await prefs.setDouble('jaw_threshold', _jawThreshold);
    await prefs.setDouble('open_threshold', _openThreshold);
    await prefs.setDouble('head_movement_threshold', _headMovementThreshold);
    await prefs.setInt('not_eating_duration', _notEatingDuration);
    await prefs.setString('audio_file', _audioFile);
    await prefs.setString('custom_audio_path', _customAudioPath);
    await prefs.setBool('use_back_camera', _useBackCamera);
    // warning_actionとenable_youtube_castは画面固有なので保存しない
    await prefs.setBool('alert_on_no_face_detected', _alertOnNoFaceDetected);
  }
  
  // 時間を分秒形式でフォーマット
  String _formatDuration(int seconds) {
    if (seconds == 0) return '--';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}分${remainingSeconds}秒';
    } else {
      return '${remainingSeconds}秒';
    }
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('Available cameras: ${widget.cameras.length}');
      
      if (widget.cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      
      final camera = _useBackCamera 
          ? widget.cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => widget.cameras.first)
          : widget.cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => widget.cameras.first);
      
      debugPrint('Selected camera: ${camera.name}');
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      debugPrint('Camera controller initialized');
      
      if (mounted) {
        _startImageStream();
        debugPrint('Image stream started');
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      rethrow;
    }
  }

  Future<void> _initializeFaceDetector() async {
    try {
      debugPrint('AudioMode: Initializing FaceDetector...');
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableLandmarks: true,
          enableClassification: false,
          enableTracking: false,
          minFaceSize: 0.05,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      debugPrint('AudioMode: Face detector created successfully');
    } catch (e) {
      debugPrint('AudioMode: Face detector initialization error: $e');
      // 顔検出の初期化に失敗してもアプリを続行
      debugPrint('AudioMode: Continuing without face detection');
    }
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      debugPrint('Audio player created successfully');
    } catch (e) {
      debugPrint('Audio player initialization error: $e');
      // 音声プレイヤーの初期化に失敗してもアプリを続行
      debugPrint('Continuing without audio player');
    }
  }

  void _startImageStream() {
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _detectFaces(image).then((_) {
          _isDetecting = false;
        });
      }
    });
  }

  Future<void> _detectFaces(CameraImage image) async {
    if (_faceDetector == null) {
      debugPrint('FaceDetector is null - skipping detection');
      return;
    }
    
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        debugPrint('Failed to create InputImage from CameraImage');
        return;
      }

      debugPrint('Processing image with FaceDetector...');
      debugPrint('InputImage metadata: ${inputImage.metadata}');
      final faces = await _faceDetector!.processImage(inputImage);
      debugPrint('Detected ${faces.length} faces');
      
      if (mounted) {
        setState(() {
          _faces = faces;
        });
        
        _analyzeMouthMovement(faces);
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
      // エラーが発生してもアプリを続行
    }
  }

  void _analyzeMouthMovement(List<Face> faces) {
    if (_isSettingsOpen) return; // 設定モーダル表示中は処理をスキップ
    
    // 顔検知なしアラート処理
    _handleFaceDetectionAlert(faces);
    
    // 現在検出されている顔のIDを生成
    Set<String> currentFaceIds = {};
    
    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final faceId = 'face_$i'; // 簡単なID生成
      currentFaceIds.add(faceId);
      
      // 新しい顔の場合は状態を初期化
      if (!_faceStates.containsKey(faceId)) {
        _faceStates[faceId] = FaceState(faceId);
      }
      
      final faceState = _faceStates[faceId]!;
      final box = face.boundingBox;
      
      /* ---------- ① 平行移動を鼻先基準で補正 ---------- */
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      if (nose == null) continue;
      final nosePos = Offset(
        nose.position.x.toDouble(),
        nose.position.y.toDouble(),
      );
      
      // 頭の急激な動きを検知
      bool hasRapidHeadMovement = false;
      if (faceState.prevNoseBase != null) {
        final headMovement = (nosePos - faceState.prevNoseBase!).distance;
        final headMovementRatio = headMovement / math.max(box.width, box.height);
        hasRapidHeadMovement = headMovementRatio > _headMovementThreshold;
      }
      
    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth];
      if (mouthBottom == null) continue;
    
      Offset mouthPos = Offset(
        mouthBottom.position.x.toDouble(),
        mouthBottom.position.y.toDouble(),
      );
      
      // 鼻先の移動量を唇座標から減算（頭の動きを補正）
      if (faceState.prevNoseBase != null) {
        final headDelta = nosePos - faceState.prevNoseBase!;
        mouthPos -= headDelta; // 鼻先に合わせて補正
      }
      faceState.prevNoseBase = nosePos; // 次フレーム用に保存
      
      double moveRatio = 0.0;
      if (faceState.previousMouthPosition != null) {
        // 垂直成分のみを使用（横振りによる誤検知を防止）
        final dy = (mouthPos.dy - faceState.previousMouthPosition!.dy).abs();
        moveRatio = dy / box.height; // 顔高さで正規化
      }
      faceState.previousMouthPosition = mouthPos;
      
      /* ---------- ② 口の開閉度（横顔対応MAR方式） ---------- */
      double openness = 0.0;
      final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
      final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
      final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
      
      // 利用可能なランドマークで口の開閉度を計算
      if (leftMouth != null && rightMouth != null && bottomMouth != null) {
        // 口の中心を計算
        final mouthCenter = Offset(
          (leftMouth.position.x + rightMouth.position.x) / 2,
          (leftMouth.position.y + rightMouth.position.y) / 2,
        );
        // 口中心から下唇までの距離を顔サイズで正規化
        final vertical = (mouthCenter - Offset(bottomMouth.position.x.toDouble(), bottomMouth.position.y.toDouble())).distance;
        openness = vertical / box.width;
      }
      
      // ベースライン確定までは calibrated=false
      if (!faceState.calibrated && openness > 0) {
        faceState.baselineMouthRatio = openness;
        faceState.calibrated = true; // 1-2フレームで完了
      }
      
      double openDelta = 0.0;
      if (faceState.calibrated) {
        openDelta = openness - faceState.baselineMouthRatio!;
    }
      
      /* ---------- ③ 顎の上下動（新規追加） ---------- */
      final jawCenter = Offset(
        (box.left + box.right) / 2, 
        box.bottom.toDouble()
      );
      
      double jawRatio = 0.0;
      if (faceState.prevJawCenter != null) {
        jawRatio = (jawCenter - faceState.prevJawCenter!).distance / box.height;
      }
      faceState.prevJawCenter = jawCenter;
      
      /* ---------- ④ 三本立て判定 ---------- */
      final chewOpen = (moveRatio > _movementThreshold) && (openDelta > _openThreshold);  // 口開け咀嚼（垂直成分のみ）
      final chewClosed = (jawRatio > _jawThreshold);                                      // 口閉じ咀嚼
      final isChewing = (chewOpen || chewClosed) && !hasRapidHeadMovement;               // 急激な頭の動きがある場合は無効
      
      /* ---------- ⑤ 状態決定 ---------- */
      if (!faceState.calibrated) {
        // キャリブレーション中は「判定中」状態
        faceState.isEating = false;
        faceState.showNotEatingMessage = false;
      } else if (hasRapidHeadMovement) {
        // 急激な頭の動きがある場合は「食べていない」判定
        _handleNoMovement(faceState);
      } else if (isChewing) {
        _handleMovementDetected(faceState);
      } else {
        _handleNoMovement(faceState);
      }
    }
    
    // 検出されなくなった顔の状態をクリア
    final removedFaceIds = _faceStates.keys.where((id) => !currentFaceIds.contains(id)).toList();
    for (final faceId in removedFaceIds) {
      final faceState = _faceStates[faceId]!;
      faceState.dispose();
      _faceStates.remove(faceId);
    }
    
    // グループ全体の音声制御を評価
    _evaluateGroupAudio();
  }

  // 顔検知なしアラートを処理するメソッド
  void _handleFaceDetectionAlert(List<Face> faces) {
    if (!_alertOnNoFaceDetected) return; // 機能がOFFの場合は何もしない
    
    debugPrint('👀 Face detection alert check - faces: ${faces.length}, alert enabled: $_alertOnNoFaceDetected');
    
    if (faces.isNotEmpty) {
      // 顔が検知された場合、タイマーをリセット
      _lastFaceDetectionTime = DateTime.now();
      _noFaceDetectionTimer?.cancel();
      _noFaceDetectionTimer = null;
      debugPrint('👀 Face detected - resetting no face timer');
    } else {
      // 顔が検知されない場合
      if (_lastFaceDetectionTime == null) {
        // 初回の顔未検知時刻を記録
        _lastFaceDetectionTime = DateTime.now();
        debugPrint('👀 No face detected - starting timer');
      }
      
      // タイマーが未設定の場合のみ新規設定
      if (_noFaceDetectionTimer == null) {
        debugPrint('👀 Setting no face detection timer for $_notEatingDuration seconds');
        _noFaceDetectionTimer = Timer(Duration(seconds: _notEatingDuration), () {
          debugPrint('⏰ No face timer expired - executing warning action');
          _executeNoFaceWarningAction();
          _noFaceDetectionTimer = null;
        });
      }
    }
  }

  void _handleMovementDetected(FaceState faceState) {
    faceState.lastMovementTime = DateTime.now();
    
    if (!faceState.isEating) {
        setState(() {
        faceState.isEating = true;
        faceState.showNotEatingMessage = false;
        // 連続食事開始時間を記録
        faceState.currentEatingStartTime = DateTime.now();
        });
    }
    
    // 個別タイマーをキャンセル（グループ制御に統一）
    faceState.notEatingTimer?.cancel();
    faceState.audioTimer?.cancel();
  }

  void _handleNoMovement(FaceState faceState) {
    if (faceState.lastMovementTime == null) {
      faceState.lastMovementTime = DateTime.now();
      return;
    }
    
    final timeSinceLastMovement = DateTime.now().difference(faceState.lastMovementTime!);
    
    // 1秒経過で「食べていません」表示に変更（静止中は食べていない扱い）
    if (timeSinceLastMovement.inSeconds >= 1) {
      if (faceState.isEating) {
        setState(() {
          faceState.isEating = false;
          faceState.showNotEatingMessage = true;
          faceState.currentEatingStartTime = null; // リセット
        });
      } else if (!faceState.showNotEatingMessage) {
        // まだ「食べていません」表示になっていない場合は表示する
        setState(() {
          faceState.showNotEatingMessage = true;
        });
      }
    }
  }

  Future<void> _executeWarningAction() async {
    if (_warningAction == 'audio') {
      await _playAudio();
    } else if (_warningAction == 'youtube_cast') {
      await _pauseYouTubeCast();
    }
  }

  Future<void> _executeNoFaceWarningAction() async {
    // 顔検知なしの場合は常に専用の音声ファイルを再生
    debugPrint('🔊 Executing no face warning action - current warning action: $_warningAction');
    await _playNoFaceAudio();
  }

  Future<void> _playNoFaceAudio() async {
    debugPrint('🎵 _playNoFaceAudio called - audio player available: ${_audioPlayer != null}');
    if (_audioPlayer != null) {
      try {
        // 顔検知なし音声再生中フラグを設定
        _isPlayingNoFaceAudio = true;
        
        // 顔検知なし専用の音声ファイルを再生
        debugPrint('🎵 Playing no face detection audio: sounds/no_face.mp3');
        await _audioPlayer!.play(AssetSource('sounds/no_face.mp3'));
        debugPrint('✅ Successfully started playing no_face.mp3');
        
        // 音声再生完了後にフラグをリセット（3秒後に自動リセット）
        Timer(Duration(seconds: 3), () {
          _isPlayingNoFaceAudio = false;
          debugPrint('🔄 No face audio playback flag reset');
        });
      } catch (e) {
        // エラー時もフラグをリセット
        _isPlayingNoFaceAudio = false;
        // no_face.mp3ファイルがない場合はシステム音を使用
        debugPrint('❌ no_face.mp3 not found, using system sound: $e');
        try {
          await SystemSound.play(SystemSoundType.alert);
          debugPrint('✅ System sound played successfully');
        } catch (systemSoundError) {
          debugPrint('❌ System sound also failed: $systemSoundError');
        }
      }
    } else {
      debugPrint('❌ Audio player is null');
    }
  }

  Future<void> _playAudio() async {
    debugPrint('🎵 _playAudio called - AudioPlayer: ${_audioPlayer != null}, Audio file: $_audioFile');
    if (_audioPlayer != null) {
      try {
        // カスタム音声ファイルが設定されている場合
        if (_audioFile == 'custom' && _customAudioPath.isNotEmpty) {
          await _audioPlayer!.play(DeviceFileSource(_customAudioPath));
          return;
        }
        
        // 設定された音声ファイルに基づいて再生
        String audioPath;
        switch (_audioFile) {
          case 'bell':
            audioPath = 'sounds/bell.mp3';
            break;
          case 'alarm':
            audioPath = 'sounds/alarm.mp3';
            break;
          case 'notification':
            audioPath = 'sounds/notification.mp3';
            break;
          case 'voice':
            audioPath = 'sounds/voice.mp3';
            break;
          default:
            audioPath = 'sounds/bell.mp3';
        }
        
        debugPrint('🎵 Playing audio file: $audioPath (from _audioFile: $_audioFile)');
        await _audioPlayer!.play(AssetSource(audioPath));
        debugPrint('✅ Audio playback started successfully for: $audioPath');
      } catch (e) {
        // 音声ファイルがない場合はシステム音を使用
        debugPrint('❌ Audio file not found, using system sound: $e');
        try {
          await SystemSound.play(SystemSoundType.alert);
          debugPrint('✅ System sound played successfully');
        } catch (systemSoundError) {
          debugPrint('❌ System sound also failed: $systemSoundError');
        }
      }
    }
  }

  Future<void> _stopAudio() async {
    // 顔検知なし音声再生中は停止しない
    if (_isPlayingNoFaceAudio) {
      debugPrint('Skipping audio stop - no face audio is playing');
      return;
    }
    
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
        debugPrint('Audio stopped');
      } catch (e) {
        debugPrint('Error stopping audio: $e');
      }
    }
  }

  Future<void> _pickCustomAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customAudioPath = result.files.single.path!;
          _audioFile = 'custom';
        });
        await _saveSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('音声ファイルが設定されました: ${result.files.single.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('音声ファイルの選択に失敗しました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;
      debugPrint('Camera sensor orientation: $sensorOrientation');
      
      InputImageRotation? rotation;
      
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = 
            _orientations[_cameraController!.value.deviceOrientation];
        debugPrint('Device orientation: ${_cameraController!.value.deviceOrientation}');
        debugPrint('Rotation compensation: $rotationCompensation');
        
        if (rotationCompensation == null) {
          debugPrint('Rotation compensation is null');
          return null;
        }
        
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
      
      if (rotation == null) {
        debugPrint('Rotation is null');
        return null;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        debugPrint('Format is null, raw format: ${image.format.raw}');
        return null;
      }

      debugPrint('Image planes: ${image.planes.length}');
      debugPrint('Image format: ${image.format.group}');
      
      // YUV420形式（3プレーン）の場合の処理
      if (image.planes.length == 3) {
        // YUVデータを結合してNV21形式に変換
        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];
        
        final ySize = yPlane.bytes.length;
        final uvSize = uPlane.bytes.length + vPlane.bytes.length;
        
        final nv21Bytes = Uint8List(ySize + uvSize);
        
        // Yプレーンをコピー
        nv21Bytes.setRange(0, ySize, yPlane.bytes);
        
        // UVプレーンを交互に配置
        int uvIndex = ySize;
        for (int i = 0; i < uPlane.bytes.length; i++) {
          nv21Bytes[uvIndex++] = vPlane.bytes[i];
          nv21Bytes[uvIndex++] = uPlane.bytes[i];
        }
        
        debugPrint('Converted to NV21 format, bytes: ${nv21Bytes.length}');
        
        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: yPlane.bytesPerRow,
          ),
        );
      }
      // 1プレーンの場合の処理（従来通り）
      else if (image.planes.length == 1) {
        final plane = image.planes.first;
        debugPrint('Image size: ${image.width}x${image.height}, bytes: ${plane.bytes.length}');

        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      } else {
        debugPrint('Unsupported number of planes: ${image.planes.length}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating InputImage: $e');
      return null;
    }
  }

  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };





  void _showSettingsDialog() {
    setState(() {
      _isSettingsOpen = true;
    });
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('設定'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 基本設定
                    _buildBasicSettings(setDialogState),
                    const Divider(),

                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSettingsOpen = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    if (mounted) {
                      setState(() {
                        _isSettingsOpen = false;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBasicSettings(StateSetter setDialogState) {
    return buildBasicSettings(
      setDialogState,
      _movementThreshold,
      _jawThreshold,
      _openThreshold,
      _headMovementThreshold,
      _notEatingDuration,
      _alertOnNoFaceDetected,
      (value) => _movementThreshold = value,
      (value) => _jawThreshold = value,
      (value) => _openThreshold = value,
      (value) => _headMovementThreshold = value,
      (value) => _notEatingDuration = value,
      (value) => _alertOnNoFaceDetected = value,
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('使用方法'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎯 基本的な使い方',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('1. カメラに顔を向けてください'),
                Text('2. 緑色の枠が顔の周りに表示されます'),
                Text('3. 赤い点が唇の位置を示します'),
                Text('4. 食事をすると顔枠の上に「食べています」と表示されます'),
                SizedBox(height: 16),
                Text(
                  '⚙️ 設定について',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 動きの閾値: 唇の垂直方向の動きの感度（0.005-0.2）'),
                Text('  ※鼻先基準で頭の動きを補正、横振りでは誤検知しない'),
                Text('• 顎の動きの閾値: 口を閉じた咀嚼の感度（0.010-0.200）'),
                Text('  ※顔の高さで正規化、口閉じでも検知可能'),
                Text('• 開閉度の閾値: 口の開閉による咀嚼判定（0.020-0.200）'),
                Text('  ※横顔でも対応、MAR方式で開閉度を測定'),
                Text('• 頭の動きの閾値: 急激な頭の動きを検知（0.020-0.200）'),
                Text('  ※この値を超える動きがあると食事判定を無効化'),
                Text('• 判定時間: 食べていないと判断する時間（1-60秒）'),
                Text('• 顔検知なしアラート: 顔が検知されない場合に専用音声で警告'),
                Text('• 複数人対応: 1人でも食べていなければ警告音再生'),
                Text('• 警告音: 判定時間経過時に再生する音声'),
                Text('• カスタム音声: スマートフォン内の音声ファイルを選択'),
                Text('• YouTube Cast制御: キャスト中の動画を自動停止/再生'),
                Text('• 警告アクション: 音声再生 or YouTube停止を選択'),
                Text('• 連続食事時間表示: リアルタイムタイマーのON/OFF'),
                Text('• カメラ切り替え: フロント/バック'),
                SizedBox(height: 16),
                Text(
                  '📊 ランキング情報',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 1位〜3位: 連続して食べ続けた時間のランキング'),
                Text('• 食事を止めると自動的にランキングに記録されます'),
                Text('• 設定からランキングをリセットできます'),
                SizedBox(height: 16),
                Text(
                  '🔧 トラブルシューティング',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 顔が検出されない → 明るい場所で使用'),
                Text('• 顔検知なしアラートが鳴る → no_face.mp3が専用音声で再生'),
                Text('• 頭を左右に振って誤検知する → 修正済み（垂直成分のみ判定）'),
                Text('• 頭を急激に動かして誤検知する → 頭の動きの閾値で調整'),
                Text('• 口を開けて食べても検知されない → 開閉度の閾値を下げる'),
                Text('• 口を閉じて食べても検知されない → 顎の動きの閾値を下げる'),
                Text('• 会話で誤検知する → 各閾値を上げる'),
                Text('• 複数人で1人だけ食べていない → 全体で警告音制御'),
                Text('• YouTube Cast制御が動作しない → Cast接続を確認'),
                Text('• 横顔でも正確に判定 → MAR方式で対応済み'),
                Text('• 静止中は「食べていない」扱い → 1秒で自動判定'),
                Text('• 初回検出時は「判定中‥」表示 → キャリブレーション中'),
                Text('• 座標がずれる → 修正済み'),
                Text('• フロントカメラで左右が逆 → 修正済み'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _toggleCamera() async {
    try {
      setState(() {
        _useBackCamera = !_useBackCamera;
      });
      
      await _saveSettings();
      await _cameraController?.dispose();
      
      // 顔の状態をクリア
      for (final faceState in _faceStates.values) {
        faceState.dispose();
      }
      _faceStates.clear();
      
      await _initializeCamera();
      
      debugPrint('Camera switched to: ${_useBackCamera ? "back" : "front"}');
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  // タイマー用の時間フォーマット
  String _formatDurationForTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // カメラプレビューとオーバーレイを統一したレイヤー
  Widget _buildCameraLayer(BuildContext context) {
    // プレビューが実際に占める縦横比 (回転後なので「高さ÷幅」)
    final aspect = 1 / _cameraController!.value.aspectRatio; // 例: 1280/720 ≒ 1.78

    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final previewW = constraints.maxWidth;
          final previewH = constraints.maxHeight;

          // ML Kit へ渡した "回転前" の画像サイズ
          final Size imageSize = _cameraController!.value.previewSize!; // 例 1280×720

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_cameraController!),

              // プレビューとまったく同じ領域にオーバレイを描く
              CustomPaint(
                size: Size(previewW, previewH),
                painter: FacePainter(
                  faces: _faces,
                  faceStates: _faceStates,
                  imageSize: imageSize,
                  previewW: previewW,
                  previewH: previewH,
                  lensDirection: _useBackCamera
                      ? CameraLensDirection.back
                      : CameraLensDirection.front,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _evaluateGroupAudio() {
    final someoneNotEating = _faceStates.values.any((s) => s.showNotEatingMessage);
    
    debugPrint('🎵 AudioModeScreen _evaluateGroupAudio - Someone not eating: $someoneNotEating, Warning action: $_warningAction, YouTube enabled: $_enableYouTubeCast');

    if (someoneNotEating) {
      // タイマーが無ければセット
      _groupAudioTimer ??= Timer(Duration(seconds: _notEatingDuration), () {
        if (_faceStates.values.any((s) => s.showNotEatingMessage)) {
          debugPrint('⏰ Timer expired - executing warning action: $_warningAction');
          // AudioModeScreenでは常に音声を再生
          debugPrint('🔊 Executing audio playback in AudioModeScreen');
          _executeWarningAction();
        }
        _groupAudioTimer = null;
      });
    } else {
      _groupAudioTimer?.cancel();
      _groupAudioTimer = null;
      
      // AudioModeScreenでは音声を停止
      debugPrint('🔇 Stopping audio in AudioModeScreen');
      _stopAudio();
    }
  }

  Future<void> _initializeCastController() async {
    try {
      debugPrint('🎬 Initializing Cast Controller...');
      _castController = CastController();
      
      // コールバック設定
      _castController!.onConnectionChanged = (connected) {
        debugPrint('🔗 Cast connection changed: $connected');
        setState(() => _isCastConnected = connected);
      };
      
      _castController!.onPlaybackStateChanged = (isPlaying) {
        debugPrint('▶️ Cast playback state changed: $isPlaying');
        setState(() => _isCastPlaying = isPlaying);
      };
      
      _castController!.onMediaInfoChanged = (title, artist, position, duration) {
        debugPrint('📺 Cast media info changed: $title');
        setState(() => _currentCastTitle = title);
      };
      
      await _castController!.initialize();
      debugPrint('✅ Cast Controller initialized successfully');
    } catch (e) {
      debugPrint('❌ Cast controller initialization failed: $e');
      // Cast制御の初期化に失敗してもアプリは継続
    }
  }

  Future<void> _pauseYouTubeCast() async {
    debugPrint('🎬 _pauseYouTubeCast called - Cast controller: ${_castController != null}, Connected: $_isCastConnected');
    
    if (_castController != null) {
      try {
        await _castController!.pause();
        debugPrint('✅ YouTube Cast paused due to not eating');
      } catch (e) {
        debugPrint('❌ Failed to pause YouTube Cast: $e');
      }
    } else {
      debugPrint('⚠️ Cast controller is null');
    }
  }

  Future<void> _resumeYouTubeCast() async {
    debugPrint('▶️ _resumeYouTubeCast called - Cast controller: ${_castController != null}, Connected: $_isCastConnected');
    
    if (_castController != null) {
      try {
        await _castController!.play();
        debugPrint('✅ YouTube Cast resumed due to eating');
      } catch (e) {
        debugPrint('❌ Failed to resume YouTube Cast: $e');
      }
    } else {
      debugPrint('⚠️ Cast controller is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ステータスバーを白色に設定
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    // 初期化エラーがある場合
    if (_initializationError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text(
                'もぐもぐウォッチ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8F5E8),
                Color(0xFFF1F8E9),
              ],
            ),
          ),
          child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  const Text('😵', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text(
                    'あれれ？',
                  style: TextStyle(
                      fontSize: 28,
                    fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                  _initializationError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                    ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializationError = '';
                      _isInitialized = false;
                    });
                    _initializeApp();
                  },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔄', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('もういちど', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 初期化中の場合
    if (!_isInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '音声再生モード',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
                 backgroundColor: const Color(0xFFFD9E9D),
        elevation: 0,
        leading:         IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            debugPrint('🏠 Navigating to home from AudioModeScreen');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen(cameras: widget.cameras)),
              (route) => false, // 全ての前の画面を削除
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                _useBackCamera ? Icons.camera_rear : Icons.camera_front,
                color: Colors.white,
              ),
              onPressed: _toggleCamera,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _showSettingsDialog,
            ),
          ),
        ],
      ),
      body: SafeArea(
              child: Column(
                children: [
            // カメラプレビューとオーバーレイを統一
            Expanded(
              child: Stack(
                    children: [
                  _buildCameraLayer(context),
                  

                ],
              ),
            ),
            
            // 制御パネル（カメラ映像の下に配置）
            _buildControlPanel(),
        ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 音声を変更ボタン
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: () => _showAudioSelectionDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD9E9D),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note, size: 20, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    '音声を変更',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Noto Sans JP',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 判定時間プルダウン
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF828282), width: 0.5),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButton<int>(
              value: _notEatingDuration,
              isExpanded: true,
              underline: Container(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'Noto Sans JP',
                color: Color(0xFF828282),
              ),
              items: List.generate(60, (index) => index + 1)
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('食べなくなってから${value}秒後に再生'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _notEatingDuration = value;
                  });
                  _saveSettings();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAudioSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('音声ファイルを選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFF2196F3)),
                title: const Text('bell.mp3'),
                subtitle: const Text('デフォルト'),
                trailing: _audioFile == 'bell' ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    _audioFile = 'bell';
                  });
                  _saveSettings();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Color(0xFFFF9800)),
                title: const Text('alarm.mp3'),
                subtitle: const Text('アラーム音'),
                trailing: _audioFile == 'alarm' ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    _audioFile = 'alarm';
                  });
                  _saveSettings();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.music_note, color: Color(0xFF4CAF50)),
                title: const Text('notification.mp3'),
                subtitle: const Text('通知音'),
                trailing: _audioFile == 'notification' ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    _audioFile = 'notification';
                  });
                  _saveSettings();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.voice_chat, color: Color(0xFF9C27B0)),
                title: const Text('voice.mp3'),
                subtitle: const Text('音声メッセージ'),
                trailing: _audioFile == 'voice' ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    _audioFile = 'voice';
                  });
                  _saveSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    debugPrint('🎵 AudioModeScreen disposing - Warning action: $_warningAction');
    _cameraController?.dispose();
    _faceDetector?.close();
    _audioPlayer?.dispose();
    _castController?.dispose(); // Cast制御の破棄
    _uiUpdateTimer?.cancel();
    _groupAudioTimer?.cancel(); // グループ音声タイマーもキャンセル
    _noFaceDetectionTimer?.cancel(); // 顔検知なしタイマーもキャンセル
    
    // 全ての顔状態のタイマーをキャンセル
    for (final faceState in _faceStates.values) {
      faceState.dispose();
    }
    
    super.dispose();
  }
}

class FacePainter extends CustomPainter {
  FacePainter({
    required this.faces,
    required this.faceStates,
    required this.imageSize,
    required this.previewW,
    required this.previewH,
    required this.lensDirection,
  });

  final List<Face> faces;
  final Map<String, FaceState> faceStates;
  final Size imageSize;               // 例: 1280×720  (回転前)
  final double previewW, previewH;    // LayoutBuilder で得た "見えている領域"
  final CameraLensDirection lensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = previewW / imageSize.height; // ★ width 基準

    // 上下にクロップされた分だけプレビューが"はみ出す" → その分 y を引く
    final double verticalCrop =
        (imageSize.width * scale - previewH) / 2;      // == (scaledH - viewH) / 2

    final mirror = lensDirection == CameraLensDirection.front;
    final pRect   = Paint()..color = const Color(0xFF4CAF50)..style = PaintingStyle.stroke..strokeWidth = 4;
    final pDot    = Paint()..color = const Color(0xFFFF5722)..style = PaintingStyle.fill   ..strokeWidth = 3;

    for (int i = 0; i < faces.length; ++i) {
      final f   = faces[i];
      final id  = 'face_$i';
      final st  = faceStates[id];

      // ========= 矩形 =========
      final left   = f.boundingBox.left  * scale;
      final top    = f.boundingBox.top   * scale - verticalCrop;
      final right  = f.boundingBox.right * scale;
      final bottom = f.boundingBox.bottom* scale - verticalCrop;

      final rect = mirror
          ? Rect.fromLTRB(previewW - right, top, previewW - left, bottom)
          : Rect.fromLTRB(left, top, right, bottom);

      canvas.drawRect(rect, pRect);

      // ========= テキスト =========
      if (st != null) {
        _drawLabel(canvas, rect.topLeft, st);
      }
      
      // ========= ランドマーク =========
      for (final lmType in [
        FaceLandmarkType.leftMouth,
        FaceLandmarkType.bottomMouth,
        FaceLandmarkType.rightMouth,
      ]) {
        final lm = f.landmarks[lmType];
        if (lm == null) continue;

        double x = lm.position.x * scale;
        double y = lm.position.y * scale - verticalCrop;
        if (mirror) x = previewW - x;

        canvas.drawCircle(Offset(x, y), 4, pDot);
      }
    }
  }

  void _drawLabel(Canvas c, Offset pos, FaceState faceState) {
    // 表示するテキストと色を決定
    String text;
    String emoji;
    Color bgColor;
    Color textColor;
    
    if (faceState.isEating) {
      text      = 'たべてるよ！';
      emoji     = '😋';
      bgColor   = const Color(0xFF4CAF50);
      textColor = Colors.white;
    } else if (faceState.showNotEatingMessage) {
      text      = 'たべてない！';
      emoji     = '😟';
      bgColor   = const Color(0xFFFF9800);
      textColor = Colors.white;
    } else if (!faceState.calibrated) {
      text      = '判定中…';
      emoji     = '🤔';
      bgColor   = Colors.grey.shade600;
      textColor = Colors.white;
    } else {                    // 静止中（判定待機）
      text      = '静止中…';
      emoji     = '🙂';
      bgColor   = Colors.blueGrey.shade600;
      textColor = Colors.white;
    }

    // 背景の丸角矩形を描画
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: emoji, style: const TextStyle(fontSize: 18)),
          const TextSpan(text: ' '),
          TextSpan(
            text: text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    final labelPos = pos - const Offset(0, 35);
    final padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelPos.dx - padding.left,
        labelPos.dy - padding.top,
        textPainter.width + padding.horizontal,
        textPainter.height + padding.vertical,
      ),
      const Radius.circular(15),
    );
    
    // 影を描画
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    c.drawRRect(bgRect.shift(const Offset(2, 2)), shadowPaint);
    
    // 背景を描画
    final bgPaint = Paint()..color = bgColor;
    c.drawRRect(bgRect, bgPaint);
    
    // テキストを描画
    textPainter.paint(c, labelPos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// 動画停止モード画面
class VideoModeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const VideoModeScreen({super.key, required this.cameras});

  @override
  State<VideoModeScreen> createState() => _VideoModeScreenState();
}

class _VideoModeScreenState extends State<VideoModeScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  AudioPlayer? _audioPlayer;
  CastController? _castController;
  
  bool _isDetecting = false;
  bool _isInitialized = false;
  String _initializationError = '';
  
  List<Face> _faces = [];
  Map<String, FaceState> _faceStates = {};
  Timer? _uiUpdateTimer;
  Timer? _groupAudioTimer;
  
  bool _isCastConnected = false;
  bool _isCastPlaying = false;
  String _currentCastTitle = '';
  
  // 設定値
  double _movementThreshold = 0.012;
  double _jawThreshold = 0.020;
  double _openThreshold = 0.030;
  double _headMovementThreshold = 0.050;
  int _notEatingDuration = 10;
  String _audioFile = 'bell';
  String _customAudioPath = '';
  bool _useBackCamera = true;
  bool _isSettingsOpen = false;
  
  String _warningAction = 'youtube_cast';
  bool _enableYouTubeCast = true;
  
  bool _alertOnNoFaceDetected = false;
  Timer? _noFaceDetectionTimer;
  DateTime? _lastFaceDetectionTime;
  bool _isPlayingNoFaceAudio = false;
  bool _videoPausedByNoFace = false; // 顔検知なしで動画を停止したフラグ
  
  // セッション開始時間
  DateTime? _sessionStartTime;
  
  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    // 動画停止モードに固定
    _warningAction = 'youtube_cast';
    _enableYouTubeCast = true;
    debugPrint('🎬 VideoModeScreen initialized - Warning action: $_warningAction, YouTube enabled: $_enableYouTubeCast');
    _initializeApp();
    
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _checkPermissions();
      await _loadSettings();
      await _initializeCamera();
      await _initializeFaceDetector();
      await _initializeAudioPlayer();
      await _initializeCastController();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _initializationError = e.toString();
      });
    }
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        throw Exception('カメラの権限が必要です。');
      }
    }
    if (cameraStatus.isPermanentlyDenied) {
      throw Exception('カメラの権限が永続的に拒否されています。');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _movementThreshold = prefs.getDouble('movement_threshold') ?? 0.012;
      _jawThreshold = prefs.getDouble('jaw_threshold') ?? 0.020;
      _openThreshold = prefs.getDouble('open_threshold') ?? 0.030;
      _headMovementThreshold = prefs.getDouble('head_movement_threshold') ?? 0.050;
      _notEatingDuration = prefs.getInt('not_eating_duration') ?? 10;
      _audioFile = prefs.getString('audio_file') ?? 'bell';  // デフォルトをbellに変更
      _customAudioPath = prefs.getString('custom_audio_path') ?? '';
      _useBackCamera = prefs.getBool('use_back_camera') ?? true;
      // VideoModeScreenでは設定に関係なく動画停止モードに固定
      _warningAction = 'youtube_cast';
      _enableYouTubeCast = true;
      _alertOnNoFaceDetected = prefs.getBool('alert_on_no_face_detected') ?? false;
      
    });
    debugPrint('🎬 VideoModeScreen settings loaded - Warning action: $_warningAction, YouTube enabled: $_enableYouTubeCast');
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('movement_threshold', _movementThreshold);
    await prefs.setDouble('jaw_threshold', _jawThreshold);
    await prefs.setDouble('open_threshold', _openThreshold);
    await prefs.setDouble('head_movement_threshold', _headMovementThreshold);
    await prefs.setInt('not_eating_duration', _notEatingDuration);
    await prefs.setString('audio_file', _audioFile);
    await prefs.setString('custom_audio_path', _customAudioPath);
    await prefs.setBool('use_back_camera', _useBackCamera);
    // warning_actionとenable_youtube_castは画面固有なので保存しない
    await prefs.setBool('alert_on_no_face_detected', _alertOnNoFaceDetected);
    
  }

  Future<void> _initializeCamera() async {
    try {
      if (widget.cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      
      final camera = _useBackCamera 
          ? widget.cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => widget.cameras.first)
          : widget.cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => widget.cameras.first);
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        _startImageStream();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initializeFaceDetector() async {
    try {
      debugPrint('VideoMode: Initializing FaceDetector...');
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableLandmarks: true,
          enableClassification: false,
          enableTracking: false,
          minFaceSize: 0.05,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      debugPrint('VideoMode: Face detector created successfully');
    } catch (e) {
      debugPrint('VideoMode: Face detector initialization error: $e');
      debugPrint('VideoMode: Continuing without face detection');
    }
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
    } catch (e) {
      // Continue without audio player
    }
  }

  Future<void> _initializeCastController() async {
    try {
      _castController = CastController();
      
      _castController!.onConnectionChanged = (connected) {
        setState(() => _isCastConnected = connected);
      };
      
      _castController!.onPlaybackStateChanged = (isPlaying) {
        setState(() => _isCastPlaying = isPlaying);
      };
      
      _castController!.onMediaInfoChanged = (title, artist, position, duration) {
        setState(() => _currentCastTitle = title);
      };
      
      await _castController!.initialize();
    } catch (e) {
      // Continue without cast controller
    }
  }

  void _startImageStream() {
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _detectFaces(image).then((_) {
          _isDetecting = false;
        });
      }
    });
  }

  Future<void> _detectFaces(CameraImage image) async {
    if (_faceDetector == null) {
      debugPrint('VideoMode: FaceDetector is null - skipping detection');
      return;
    }
    
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        debugPrint('VideoMode: Failed to create InputImage from CameraImage');
        return;
      }

      debugPrint('VideoMode: Processing image with FaceDetector...');
      final faces = await _faceDetector!.processImage(inputImage);
      debugPrint('VideoMode: Detected ${faces.length} faces');
      
      if (mounted) {
        setState(() {
          _faces = faces;
        });
        
        _analyzeMouthMovement(faces);
      }
    } catch (e) {
      debugPrint('VideoMode: Face detection error: $e');
      // Continue on error
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;
      
      InputImageRotation? rotation;
      
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = 
            _orientations[_cameraController!.value.deviceOrientation];
        
        if (rotationCompensation == null) {
          return null;
        }
        
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
      
      if (rotation == null) {
        return null;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        return null;
      }

      if (image.planes.length == 3) {
        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];
        
        final ySize = yPlane.bytes.length;
        final uvSize = uPlane.bytes.length + vPlane.bytes.length;
        
        final nv21Bytes = Uint8List(ySize + uvSize);
        
        nv21Bytes.setRange(0, ySize, yPlane.bytes);
        
        int uvIndex = ySize;
        for (int i = 0; i < uPlane.bytes.length; i++) {
          nv21Bytes[uvIndex++] = vPlane.bytes[i];
          nv21Bytes[uvIndex++] = uPlane.bytes[i];
        }
        
        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: yPlane.bytesPerRow,
          ),
        );
      } else if (image.planes.length == 1) {
        final plane = image.planes.first;

        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _analyzeMouthMovement(List<Face> faces) {
    if (_isSettingsOpen) return;
    
    _handleFaceDetectionAlert(faces);
    
    Set<String> currentFaceIds = {};
    
    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final faceId = 'face_$i';
      currentFaceIds.add(faceId);
      
      if (!_faceStates.containsKey(faceId)) {
        _faceStates[faceId] = FaceState(faceId);
      }
      
      final faceState = _faceStates[faceId]!;
      final box = face.boundingBox;
      
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      if (nose == null) continue;
      final nosePos = Offset(
        nose.position.x.toDouble(),
        nose.position.y.toDouble(),
      );
      
      bool hasRapidHeadMovement = false;
      if (faceState.prevNoseBase != null) {
        final headMovement = (nosePos - faceState.prevNoseBase!).distance;
        final headMovementRatio = headMovement / math.max(box.width, box.height);
        hasRapidHeadMovement = headMovementRatio > _headMovementThreshold;
      }
      
      final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth];
      if (mouthBottom == null) continue;
    
      Offset mouthPos = Offset(
        mouthBottom.position.x.toDouble(),
        mouthBottom.position.y.toDouble(),
      );
      
      if (faceState.prevNoseBase != null) {
        final headDelta = nosePos - faceState.prevNoseBase!;
        mouthPos -= headDelta;
      }
      faceState.prevNoseBase = nosePos;
      
      double moveRatio = 0.0;
      if (faceState.previousMouthPosition != null) {
        final dy = (mouthPos.dy - faceState.previousMouthPosition!.dy).abs();
        moveRatio = dy / box.height;
      }
      faceState.previousMouthPosition = mouthPos;
      
      double openness = 0.0;
      final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
      final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
      final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
      
      if (leftMouth != null && rightMouth != null && bottomMouth != null) {
        final mouthCenter = Offset(
          (leftMouth.position.x + rightMouth.position.x) / 2,
          (leftMouth.position.y + rightMouth.position.y) / 2,
        );
        final vertical = (mouthCenter - Offset(bottomMouth.position.x.toDouble(), bottomMouth.position.y.toDouble())).distance;
        openness = vertical / box.width;
      }
      
      if (!faceState.calibrated && openness > 0) {
        faceState.baselineMouthRatio = openness;
        faceState.calibrated = true;
      }
      
      double openDelta = 0.0;
      if (faceState.calibrated) {
        openDelta = openness - faceState.baselineMouthRatio!;
      }
      
      final jawCenter = Offset(
        (box.left + box.right) / 2, 
        box.bottom.toDouble()
      );
      
      double jawRatio = 0.0;
      if (faceState.prevJawCenter != null) {
        jawRatio = (jawCenter - faceState.prevJawCenter!).distance / box.height;
      }
      faceState.prevJawCenter = jawCenter;
      
      final chewOpen = (moveRatio > _movementThreshold) && (openDelta > _openThreshold);
      final chewClosed = (jawRatio > _jawThreshold);
      final isChewing = (chewOpen || chewClosed) && !hasRapidHeadMovement;
      
      if (!faceState.calibrated) {
        faceState.isEating = false;
        faceState.showNotEatingMessage = false;
      } else if (hasRapidHeadMovement) {
        _handleNoMovement(faceState);
      } else if (isChewing) {
        _handleMovementDetected(faceState);
      } else {
        _handleNoMovement(faceState);
      }
    }
    
    final removedFaceIds = _faceStates.keys.where((id) => !currentFaceIds.contains(id)).toList();
    for (final faceId in removedFaceIds) {
      final faceState = _faceStates[faceId]!;
      faceState.dispose();
      _faceStates.remove(faceId);
    }
    
    _evaluateGroupAudio();
  }

  void _evaluateGroupAudio() {
    final someoneNotEating = _faceStates.values.any((s) => s.showNotEatingMessage);
    
    debugPrint('🎬 VideoModeScreen _evaluateGroupAudio - Someone not eating: $someoneNotEating, Warning action: $_warningAction, YouTube enabled: $_enableYouTubeCast');

    if (someoneNotEating) {
      // タイマーが無ければセット
      _groupAudioTimer ??= Timer(Duration(seconds: _notEatingDuration), () {
        if (_faceStates.values.any((s) => s.showNotEatingMessage)) {
          debugPrint('⏰ Timer expired - executing warning action: $_warningAction');
          // 動画停止モードでは動画を停止
          debugPrint('🎬 Executing YouTube Cast pause');
          _pauseYouTubeCast();
        }
        _groupAudioTimer = null;
      });
    } else {
      _groupAudioTimer?.cancel();
      _groupAudioTimer = null;
      
      // 顔検知なしで停止していない場合のみ動画を再開
      if (!_videoPausedByNoFace) {
        debugPrint('🎬 Everyone eating - resuming YouTube Cast');
        _resumeYouTubeCast();
      } else {
        debugPrint('🎬 Video paused by no face - not resuming until eating detected');
      }
    }
  }

  void _handleFaceDetectionAlert(List<Face> faces) {
    if (!_alertOnNoFaceDetected) return;
    
    debugPrint('👀 Face detection alert check - faces: ${faces.length}, alert enabled: $_alertOnNoFaceDetected');
    
    if (faces.isNotEmpty) {
      // 顔が検知された場合、タイマーをリセット
      _lastFaceDetectionTime = DateTime.now();
      _noFaceDetectionTimer?.cancel();
      _noFaceDetectionTimer = null;
      debugPrint('👀 Face detected - resetting no face timer');
    } else {
      // 顔が検知されない場合
      if (_lastFaceDetectionTime == null) {
        // 初回の顔未検知時刻を記録
        _lastFaceDetectionTime = DateTime.now();
        debugPrint('👀 No face detected - starting timer');
      }
      
      // タイマーが未設定の場合のみ新規設定
      if (_noFaceDetectionTimer == null) {
        debugPrint('👀 Setting no face detection timer for $_notEatingDuration seconds');
        _noFaceDetectionTimer = Timer(Duration(seconds: _notEatingDuration), () {
          debugPrint('⏰ No face timer expired - executing warning action');
          _executeNoFaceWarningAction();
          _noFaceDetectionTimer = null;
        });
      }
    }
  }

  Future<void> _executeNoFaceWarningAction() async {
    // 顔検知なしの場合は専用の音声ファイルを再生し、動画も停止
    debugPrint('🔊 Executing no face warning action in VideoModeScreen - playing audio and stopping video');
    await _playNoFaceAudio();
    await _pauseYouTubeCast();
    _videoPausedByNoFace = true; // 顔検知なしで停止したことを記録
    debugPrint('📺 Video paused by no face detection - requires eating to resume');
  }

  Future<void> _playNoFaceAudio() async {
    debugPrint('🎵 _playNoFaceAudio called in VideoModeScreen - audio player available: ${_audioPlayer != null}');
    if (_audioPlayer != null) {
      try {
        // 顔検知なし音声再生中フラグを設定
        _isPlayingNoFaceAudio = true;
        
        // 顔検知なし専用の音声ファイルを再生
        debugPrint('🎵 Playing no face detection audio: sounds/no_face.mp3');
        await _audioPlayer!.play(AssetSource('sounds/no_face.mp3'));
        debugPrint('✅ Successfully started playing no_face.mp3');
        
        // 音声再生完了後にフラグをリセット（3秒後に自動リセット）
        Timer(Duration(seconds: 3), () {
          _isPlayingNoFaceAudio = false;
          debugPrint('🔄 No face audio playback flag reset in VideoModeScreen');
        });
      } catch (e) {
        // エラー時もフラグをリセット
        _isPlayingNoFaceAudio = false;
        // no_face.mp3ファイルがない場合はシステム音を使用
        debugPrint('❌ no_face.mp3 not found, using system sound: $e');
        try {
          await SystemSound.play(SystemSoundType.alert);
          debugPrint('✅ System sound played successfully');
        } catch (systemSoundError) {
          debugPrint('❌ System sound also failed: $systemSoundError');
        }
      }
    } else {
      debugPrint('❌ Audio player is null');
    }
  }

  void _handleMovementDetected(FaceState faceState) {
    faceState.lastMovementTime = DateTime.now();
    
    if (!faceState.isEating) {
      setState(() {
        faceState.isEating = true;
        faceState.showNotEatingMessage = false;
        faceState.currentEatingStartTime = DateTime.now();
      });
      
      // 顔検知なしで停止していた場合、食べている状態になったので動画を再開
      if (_videoPausedByNoFace) {
        _videoPausedByNoFace = false;
        debugPrint('🎬 Eating detected after no face pause - resuming video');
        _resumeYouTubeCast();
      }
    }
    
    faceState.notEatingTimer?.cancel();
    faceState.audioTimer?.cancel();
  }

  void _handleNoMovement(FaceState faceState) {
    if (faceState.lastMovementTime == null) {
      faceState.lastMovementTime = DateTime.now();
      return;
    }
    
    final timeSinceLastMovement = DateTime.now().difference(faceState.lastMovementTime!);
    
    if (timeSinceLastMovement.inSeconds >= 1) {
      if (faceState.isEating) {
        setState(() {
          faceState.isEating = false;
          faceState.showNotEatingMessage = true;
          faceState.currentEatingStartTime = null;
        });
      } else if (!faceState.showNotEatingMessage) {
        setState(() {
          faceState.showNotEatingMessage = true;
        });
      }
    }
  }

  Future<void> _pauseYouTubeCast() async {
    if (_castController != null) {
      try {
        await _castController!.pause();
      } catch (e) {
        debugPrint('Failed to pause YouTube Cast: $e');
      }
    }
  }

  Future<void> _resumeYouTubeCast() async {
    if (_castController != null) {
      try {
        await _castController!.play();
      } catch (e) {
        debugPrint('Failed to resume YouTube Cast: $e');
      }
    }
  }



  Future<void> _stopAudio() async {
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
        debugPrint('Audio stopped');
      } catch (e) {
        debugPrint('Error stopping audio: $e');
      }
    }
  }

  void _toggleCamera() async {
    try {
      setState(() {
        _useBackCamera = !_useBackCamera;
      });
      
      await _saveSettings();
      await _cameraController?.dispose();
      
      for (final faceState in _faceStates.values) {
        faceState.dispose();
      }
      _faceStates.clear();
      
      await _initializeCamera();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  void _showSettingsDialog() {
    setState(() {
      _isSettingsOpen = true;
    });
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('設定'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 基本設定
                    _buildBasicSettings(setDialogState),
                    const Divider(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSettingsOpen = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    final oldEnableYouTubeCast = _enableYouTubeCast;
                    
                    await _saveSettings();
                    
                    if (oldEnableYouTubeCast != _enableYouTubeCast) {
                      if (_enableYouTubeCast) {
                        await _initializeCastController();
                      } else {
                        _castController?.dispose();
                        _castController = null;
                        setState(() {
                          _isCastConnected = false;
                          _isCastPlaying = false;
                          _currentCastTitle = '';
                        });
                      }
                    }
                    
                    if (mounted) {
                      setState(() {
                        _isSettingsOpen = false;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCameraLayer(BuildContext context) {
    final aspect = 1 / _cameraController!.value.aspectRatio;

    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final previewW = constraints.maxWidth;
          final previewH = constraints.maxHeight;
          final Size imageSize = _cameraController!.value.previewSize!;

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_cameraController!),
              CustomPaint(
                size: Size(previewW, previewH),
                painter: FacePainter(
                  faces: _faces,
                  faceStates: _faceStates,
                  imageSize: imageSize,
                  previewW: previewW,
                  previewH: previewH,
                  lensDirection: _useBackCamera
                      ? CameraLensDirection.back
                      : CameraLensDirection.front,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDurationForTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildControlPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 動画アプリを変更ボタン
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: () => _showVideoAppSelectionDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65B9D0),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tv, size: 20, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    '動画アプリを変更',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Noto Sans JP',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 判定時間プルダウン
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF828282), width: 0.5),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButton<int>(
              value: _notEatingDuration,
              isExpanded: true,
              underline: Container(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'Noto Sans JP',
                color: Color(0xFF828282),
              ),
              items: List.generate(60, (index) => index + 1)
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('食べなくなってから${value}秒後に停止'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _notEatingDuration = value;
                  });
                  _saveSettings();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoAppSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('動画アプリを選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_fill, color: Colors.red),
                title: const Text('YouTube'),
                subtitle: const Text('デフォルト'),
                trailing: const Icon(Icons.check, color: Colors.green),
                onTap: () {
                  // YouTubeは現在唯一の選択肢
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ステータスバーを白色に設定
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (_initializationError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            '動画停止モード',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
                     backgroundColor: const Color(0xFF65B9D0),
          leading:         IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            debugPrint('🏠 Navigating to home from AudioModeScreen');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen(cameras: widget.cameras)),
              (route) => false, // 全ての前の画面を削除
            );
          },
        ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😵', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(_initializationError),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initializationError = '';
                    _isInitialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('もういちど'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '動画停止モード',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
                   backgroundColor: const Color(0xFF65B9D0),
        elevation: 0,
        leading:         IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            debugPrint('🏠 Navigating to home from AudioModeScreen');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen(cameras: widget.cameras)),
              (route) => false, // 全ての前の画面を削除
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                _useBackCamera ? Icons.camera_rear : Icons.camera_front,
                color: Colors.white,
              ),
              onPressed: _toggleCamera,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _showSettingsDialog,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
                         Expanded(
               child: Stack(
                 children: [
                   _buildCameraLayer(context),
                 ],
               ),
             ),
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettings(StateSetter setDialogState) {
    return buildBasicSettings(
      setDialogState,
      _movementThreshold,
      _jawThreshold,
      _openThreshold,
      _headMovementThreshold,
      _notEatingDuration,
      _alertOnNoFaceDetected,
      (value) => _movementThreshold = value,
      (value) => _jawThreshold = value,
      (value) => _openThreshold = value,
      (value) => _headMovementThreshold = value,
      (value) => _notEatingDuration = value,
      (value) => _alertOnNoFaceDetected = value,
    );
  }

  @override
  void dispose() {
    debugPrint('🎬 VideoModeScreen disposing - Warning action: $_warningAction');
    _cameraController?.dispose();
    _faceDetector?.close();
    _audioPlayer?.dispose();
    _castController?.dispose();
    _uiUpdateTimer?.cancel();
    _groupAudioTimer?.cancel();
    _noFaceDetectionTimer?.cancel();
    
    for (final faceState in _faceStates.values) {
      faceState.dispose();
    }
    
    super.dispose();
  }
}
