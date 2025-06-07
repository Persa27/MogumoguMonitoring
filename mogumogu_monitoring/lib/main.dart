import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MogumoguApp(cameras: cameras));
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
      home: MogumoguHomePage(cameras: cameras),
    );
  }
}

class MogumoguHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MogumoguHomePage({super.key, required this.cameras});

  @override
  State<MogumoguHomePage> createState() => _MogumoguHomePageState();
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
  
  FaceState(this.id) 
    : isEating = false,
      lastMovementTime = null,
      previousMouthPosition = null,
      notEatingTimer = null,
      audioTimer = null,
      showNotEatingMessage = false,
      currentEatingStartTime = null,
      currentEatingDuration = 0;
      
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

class _MogumoguHomePageState extends State<MogumoguHomePage> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  AudioPlayer? _audioPlayer;
  
  bool _isDetecting = false;
  bool _isInitialized = false;
  String _initializationError = '';
  
  List<Face> _faces = [];
  Map<String, FaceState> _faceStates = {};
  Timer? _uiUpdateTimer; // UI更新用タイマー
  
  // 設定値
  double _movementThreshold = 0.5; // 唇の動きの閾値（上限を10.0に拡張）
  int _notEatingDuration = 10; // 食べていないと判断する秒数（1秒刻み）
  String _audioFile = 'default'; // 音声ファイル
  String _customAudioPath = ''; // カスタム音声ファイルのパス
  bool _useBackCamera = true; // バックカメラを使用するか
  bool _isSettingsOpen = false; // 設定モーダルが開いているかどうか
  bool _showEatingTimer = true; // 連続食事時間表示のON/OFF
  
  // 連続食事時間のランキング（上位3位まで保存）
  List<int> _eatingDurationRanking = [0, 0, 0];
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
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
      _movementThreshold = prefs.getDouble('movement_threshold') ?? 0.5;
      _notEatingDuration = prefs.getInt('not_eating_duration') ?? 10;
      _audioFile = prefs.getString('audio_file') ?? 'default';
      _customAudioPath = prefs.getString('custom_audio_path') ?? '';
      _useBackCamera = prefs.getBool('use_back_camera') ?? true;
      _showEatingTimer = prefs.getBool('show_eating_timer') ?? true;
      
      // ランキングデータの読み込み
      final rankingData = prefs.getStringList('eating_duration_ranking');
      if (rankingData != null && rankingData.length == 3) {
        _eatingDurationRanking = rankingData.map((e) => int.parse(e)).toList();
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('movement_threshold', _movementThreshold);
    await prefs.setInt('not_eating_duration', _notEatingDuration);
    await prefs.setString('audio_file', _audioFile);
    await prefs.setString('custom_audio_path', _customAudioPath);
    await prefs.setBool('use_back_camera', _useBackCamera);
    await prefs.setBool('show_eating_timer', _showEatingTimer);
    
    // ランキングデータの保存
    await prefs.setStringList('eating_duration_ranking', 
        _eatingDurationRanking.map((e) => e.toString()).toList());
  }
  
  // 連続食事時間をランキングに追加
  void _updateEatingDurationRanking(int duration) {
    if (duration > 0) {
      _eatingDurationRanking.add(duration);
      _eatingDurationRanking.sort((a, b) => b.compareTo(a)); // 降順ソート
      if (_eatingDurationRanking.length > 3) {
        _eatingDurationRanking = _eatingDurationRanking.take(3).toList();
      }
      _saveSettings(); // ランキング更新時に保存
    }
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
        ResolutionPreset.medium,
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
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableLandmarks: true,
        ),
      );
      debugPrint('Face detector created successfully');
    } catch (e) {
      debugPrint('Face detector initialization error: $e');
      // 顔検出の初期化に失敗してもアプリを続行
      debugPrint('Continuing without face detection');
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
    if (_faceDetector == null) return;
    
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        debugPrint('Failed to create InputImage from CameraImage');
        return;
      }

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
      final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth];
      
      if (mouthBottom != null) {
        final currentMouthPosition = Offset(
          mouthBottom.position.x.toDouble(),
          mouthBottom.position.y.toDouble(),
        );
        
        if (faceState.previousMouthPosition != null) {
          final distance = (currentMouthPosition - faceState.previousMouthPosition!).distance;
          
          if (distance > _movementThreshold) {
            _handleMovementDetected(faceState);
          } else {
            _handleNoMovement(faceState);
          }
        }
        
        faceState.previousMouthPosition = currentMouthPosition;
      }
    }
    
    // 検出されなくなった顔の状態をクリア
    final removedFaceIds = _faceStates.keys.where((id) => !currentFaceIds.contains(id)).toList();
    for (final faceId in removedFaceIds) {
      final faceState = _faceStates[faceId]!;
      // 連続食事時間をランキングに追加
      if (faceState.currentEatingStartTime != null && faceState.isEating) {
        final duration = DateTime.now().difference(faceState.currentEatingStartTime!).inSeconds;
        _updateEatingDurationRanking(duration);
      }
      faceState.dispose();
      _faceStates.remove(faceId);
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
      
      // 「食べています」判定時に音声を即座に停止
      _stopAudio();
    }
    
    // 全てのタイマーをキャンセル
    faceState.notEatingTimer?.cancel();
    faceState.audioTimer?.cancel();
  }

  void _handleNoMovement(FaceState faceState) {
    if (faceState.lastMovementTime == null) {
      faceState.lastMovementTime = DateTime.now();
      return;
    }
    
    final timeSinceLastMovement = DateTime.now().difference(faceState.lastMovementTime!);
    
    // 1秒経過で「食べていません」表示に変更
    if (timeSinceLastMovement.inSeconds >= 1) {
      if (faceState.isEating) {
        // 連続食事時間をランキングに追加
        if (faceState.currentEatingStartTime != null) {
          final duration = DateTime.now().difference(faceState.currentEatingStartTime!).inSeconds;
          _updateEatingDurationRanking(duration);
        }
        
        setState(() {
          faceState.isEating = false;
          faceState.showNotEatingMessage = true;
          faceState.currentEatingStartTime = null; // リセット
        });
        
        // 指定秒数後に音声を再生するタイマーを開始
        _startAudioTimer(faceState);
      }
    }
  }

  void _startAudioTimer(FaceState faceState) {
    // 指定秒数後に音声を再生
    faceState.audioTimer = Timer(Duration(seconds: _notEatingDuration), () {
      if (mounted && faceState.showNotEatingMessage) {
        _playAudio();
      }
    });
  }

  Future<void> _playAudio() async {
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
            audioPath = 'bell.mp3';
            break;
          case 'alarm':
            audioPath = 'alarm.mp3';
            break;
          case 'notification':
            audioPath = 'notification.mp3';
            break;
          case 'voice':
            audioPath = 'voice.mp3';
            break;
          default:
            audioPath = 'notification.mp3';
        }
        
        await _audioPlayer!.play(AssetSource(audioPath));
      } catch (e) {
        // 音声ファイルがない場合はシステム音を使用
        debugPrint('Audio file not found, using system sound: $e');
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (systemSoundError) {
          debugPrint('System sound also failed: $systemSoundError');
        }
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



  Widget _buildStatCard({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
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
                    // 動きの閾値設定（上限を10.0に拡張）
                    ListTile(
                      title: const Text('動きの閾値'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Slider(
                            value: _movementThreshold,
                            min: 0.1,
                            max: 10.0,
                            divisions: 99,
                            label: _movementThreshold.toStringAsFixed(1),
                            onChanged: (value) {
                              setDialogState(() {
                                _movementThreshold = value;
                              });
                            },
                          ),
                          const Text(
                            '値が小さいほど小さな動きでも検知します（0.1-10.0）',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // 判定時間設定（1秒刻み）
                    ListTile(
                      title: const Text('判定時間（秒）'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Slider(
                            value: _notEatingDuration.toDouble(),
                            min: 1,
                            max: 60,
                            divisions: 59,
                            label: _notEatingDuration.toString(),
                            onChanged: (value) {
                              setDialogState(() {
                                _notEatingDuration = value.round();
                              });
                            },
                          ),
                          const Text(
                            'この時間食べていないと警告します（1-60秒）',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // 音声ファイル設定
                    ListTile(
                      title: const Text('警告音'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<String>(
                            value: _audioFile,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'default', child: Text('デフォルト')),
                              DropdownMenuItem(value: 'bell', child: Text('ベル音')),
                              DropdownMenuItem(value: 'alarm', child: Text('アラーム音')),
                              DropdownMenuItem(value: 'notification', child: Text('通知音')),
                              DropdownMenuItem(value: 'voice', child: Text('音声メッセージ')),
                              DropdownMenuItem(value: 'custom', child: Text('カスタム音声')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  _audioFile = value;
                                });
                              }
                            },
                          ),
                          if (_audioFile == 'custom') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _customAudioPath.isEmpty 
                                        ? '音声ファイルが選択されていません' 
                                        : '選択済み: ${_customAudioPath.split('/').last}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    setState(() {
                                      _isSettingsOpen = false;
                                    });
                                    Navigator.of(context).pop();
                                    await _pickCustomAudioFile();
                                    _showSettingsDialog();
                                  },
                                  child: const Text('選択'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(),
                    // 連続食事時間表示のON/OFF設定
                    ListTile(
                      title: const Text('連続食事時間表示'),
                      subtitle: const Text('カメラ映像上にリアルタイムタイマーを表示'),
                      trailing: Switch(
                        value: _showEatingTimer,
                        onChanged: (value) {
                          setDialogState(() {
                            _showEatingTimer = value;
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('ランキングをリセット'),
                      subtitle: const Text('連続食事時間のランキングをリセットします'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            _eatingDurationRanking = [0, 0, 0];
                            _sessionStartTime = DateTime.now();
                          });
                        },
                        child: const Text('リセット'),
                      ),
                    ),
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
                    await _saveSettings();
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
                Text('• 動きの閾値: 唇の動きの感度を調整（0.1-10.0）'),
                Text('• 判定時間: 食べていないと判断する時間（1-60秒）'),
                Text('• 警告音: 判定時間経過時に再生する音声'),
                Text('• カスタム音声: スマートフォン内の音声ファイルを選択'),
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
                Text('• 動きが検知されない → 閾値を下げる'),
                Text('• 誤検知が多い → 閾値を上げる'),
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

  // 連続食事時間表示オーバーレイ
  Widget _buildEatingTimerOverlay() {
    // 設定でOFFになっている場合は表示しない
    if (!_showEatingTimer) return const SizedBox.shrink();
    
    // 食事中の顔があるかチェック
    final eatingFaces = _faceStates.values.where((state) => state.isEating).toList();
    if (eatingFaces.isEmpty) return const SizedBox.shrink();
    
    // 最も長く食べている時間を取得
    final maxDuration = eatingFaces.map((state) => state.getCurrentEatingDuration()).reduce((a, b) => a > b ? a : b);
    if (maxDuration == 0) return const SizedBox.shrink();
    
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getTimerColors(maxDuration),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // キラキラエフェクト付きのタイトル
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSparkleText('✨'),
                  const SizedBox(width: 8),
                  const Text(
                    'がんばってるね！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSparkleText('✨'),
                ],
              ),
              const SizedBox(height: 8),
              // 大きな時間表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBouncingEmoji('🍽️'),
                    const SizedBox(width: 12),
                    Text(
                      _formatDurationForTimer(maxDuration),
                      style: TextStyle(
                        color: const Color(0xFFFF6B35),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: const Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildBouncingEmoji('🎉'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 励ましメッセージ
              Text(
                _getEncouragementMessage(maxDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // キラキラエフェクト付きテキスト
  Widget _buildSparkleText(String text) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          shadows: [
            Shadow(
              color: Colors.white,
              offset: Offset(0, 0),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
  
  // バウンスする絵文字
  Widget _buildBouncingEmoji(String emoji) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (math.sin(value * math.pi * 4) * 0.1),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        );
      },
    );
  }
  
  // タイマー用の時間フォーマット
  String _formatDurationForTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // 励ましメッセージ
  String _getEncouragementMessage(int seconds) {
    if (seconds < 10) return 'いいかんじ！';
    if (seconds < 30) return 'すごいね！';
    if (seconds < 60) return 'がんばってる！';
    if (seconds < 120) return 'すばらしい！';
    if (seconds < 300) return 'ちょうすごい！';
    return 'きみはチャンピオン！';
  }
  
  // 時間に応じたタイマーの色
  List<Color> _getTimerColors(int seconds) {
    if (seconds < 10) {
      return [
        const Color(0xFF4CAF50).withOpacity(0.95), // 緑
        const Color(0xFF8BC34A).withOpacity(0.95),
      ];
    } else if (seconds < 30) {
      return [
        const Color(0xFF2196F3).withOpacity(0.95), // 青
        const Color(0xFF03A9F4).withOpacity(0.95),
      ];
    } else if (seconds < 60) {
      return [
        const Color(0xFFFF9800).withOpacity(0.95), // オレンジ
        const Color(0xFFFFC107).withOpacity(0.95),
      ];
    } else if (seconds < 120) {
      return [
        const Color(0xFFE91E63).withOpacity(0.95), // ピンク
        const Color(0xFFFF5722).withOpacity(0.95),
      ];
    } else if (seconds < 300) {
      return [
        const Color(0xFF9C27B0).withOpacity(0.95), // 紫
        const Color(0xFF673AB7).withOpacity(0.95),
      ];
    } else {
      return [
        const Color(0xFFFFD700).withOpacity(0.95), // ゴールド
        const Color(0xFFFFA500).withOpacity(0.95),
      ];
    }
  }
  
  // 特別な達成エフェクト
  Widget _buildAchievementEffect(int seconds, BuildContext context) {
    // 10秒、30秒、60秒、120秒、300秒の節目で特別エフェクト
    final milestones = [10, 30, 60, 120, 300];
    final isSpecialMoment = milestones.contains(seconds);
    
    if (!isSpecialMoment) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 2000),
          child: Stack(
            children: [
              // 花火エフェクト
              ...List.generate(8, (index) {
                final angle = (index * math.pi * 2) / 8;
                return Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 15,
                  top: MediaQuery.of(context).size.height / 3,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      final distance = value * 100;
                      final x = math.cos(angle) * distance;
                      final y = math.sin(angle) * distance;
                      return Transform.translate(
                        offset: Offset(x, y),
                        child: Opacity(
                          opacity: 1.0 - value,
                          child: const Text(
                            '⭐',
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
              // 中央の大きな星
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 25,
                top: MediaQuery.of(context).size.height / 3 - 25,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value * 2,
                      child: Opacity(
                        opacity: 1.0 - value,
                        child: const Text(
                          '🌟',
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              
              // 連続食事時間表示
              _buildEatingTimerOverlay(),
              
              // 達成エフェクト
              if (_showEatingTimer && _faceStates.values.any((state) => state.isEating))
                Builder(
                  builder: (context) => _buildAchievementEffect(
                    _faceStates.values
                        .where((state) => state.isEating)
                        .map((state) => state.getCurrentEatingDuration())
                        .fold(0, (a, b) => a > b ? a : b),
                    context,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🔄', style: TextStyle(fontSize: 80)),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  strokeWidth: 6,
                ),
                SizedBox(height: 24),
                Text(
                  'じゅんびちゅう...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'カメラとAIをじゅんびしています',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
        elevation: 0,
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
              tooltip: _useBackCamera ? 'フロントカメラに切り替え' : 'バックカメラに切り替え',
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: _showHelpDialog,
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
            
            // 統計情報表示（カメラ映像の下に配置）
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2196F3),
                    Color(0xFF03DAC6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📊', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        'きょうのきろく',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: '🥇',
                          value: _formatDuration(_eatingDurationRanking.isNotEmpty ? _eatingDurationRanking[0] : 0),
                          label: '1位',
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: '🥈',
                          value: _formatDuration(_eatingDurationRanking.length > 1 ? _eatingDurationRanking[1] : 0),
                          label: '2位',
                          color: const Color(0xFFC0C0C0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: '🥉',
                          value: _formatDuration(_eatingDurationRanking.length > 2 ? _eatingDurationRanking[2] : 0),
                          label: '3位',
                          color: const Color(0xFFCD7F32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    _audioPlayer?.dispose();
    _uiUpdateTimer?.cancel();
    
    // 全ての顔の状態を破棄
    for (final faceState in _faceStates.values) {
      faceState.dispose();
    }
    _faceStates.clear();
    
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
      text = 'たべてるよ！';
      emoji = '😋';
      bgColor = const Color(0xFF4CAF50);
      textColor = Colors.white;
    } else if (faceState.showNotEatingMessage) {
      text = 'たべてない！';
      emoji = '😟';
      bgColor = const Color(0xFFFF5722);
      textColor = Colors.white;
    } else {
      // 判定中は何も表示しない
      return;
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
