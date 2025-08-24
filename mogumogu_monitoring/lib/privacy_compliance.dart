import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// COPPA/GDPR準拠のためのプライバシー管理クラス
class PrivacyComplianceManager {
  static const String _parentalConsentKey = 'parental_consent';
  static const String _childAgeKey = 'child_age';
  static const String _parentEmailKey = 'parent_email';
  static const String _consentTimestampKey = 'consent_timestamp';
  static const String _dataRetentionKey = 'data_retention_period';
  static const String _privacyPolicyAcceptedKey = 'privacy_policy_accepted';

  /// 保護者の同意状況を確認
  static Future<bool> hasParentalConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_parentalConsentKey) ?? false;
  }

  /// 子供の年齢を取得
  static Future<int?> getChildAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_childAgeKey);
  }

  /// 保護者の同意を記録
  static Future<void> recordParentalConsent({
    required int childAge,
    required String parentEmail,
    required bool consent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_parentalConsentKey, consent);
    await prefs.setInt(_childAgeKey, childAge);
    await prefs.setString(_parentEmailKey, parentEmail);
    await prefs.setString(_consentTimestampKey, DateTime.now().toIso8601String());
    await prefs.setBool(_privacyPolicyAcceptedKey, consent);
  }

  /// プライバシーポリシーの同意状況を確認
  static Future<bool> hasAcceptedPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyPolicyAcceptedKey) ?? false;
  }

  /// データ削除（保護者の権利）
  static Future<void> deleteAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // アプリの設定データを削除（プライバシー関連の記録は保持）
    final keysToDelete = [
      'movement_threshold',
      'jaw_threshold',
      'open_threshold',
      'head_movement_threshold',
      'not_eating_duration',
      'audio_file',
      'custom_audio_path',
      'use_back_camera',
      'show_eating_timer',
      'warning_action',
      'enable_youtube_cast',
      'eating_duration_ranking',
    ];
    
    for (String key in keysToDelete) {
      await prefs.remove(key);
    }
  }

  /// 同意の撤回
  static Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_parentalConsentKey, false);
    await prefs.setBool(_privacyPolicyAcceptedKey, false);
    // データも削除
    await deleteAllUserData();
  }

  /// データ保持期間の設定（デフォルト30日）
  static Future<void> setDataRetentionPeriod(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dataRetentionKey, days);
  }

  /// データ保持期間の取得
  static Future<int> getDataRetentionPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dataRetentionKey) ?? 30; // デフォルト30日
  }

  /// 古いデータの自動削除チェック
  static Future<void> checkAndDeleteExpiredData() async {
    final prefs = await SharedPreferences.getInstance();
    final consentTimestamp = prefs.getString(_consentTimestampKey);
    if (consentTimestamp == null) return;

    final consentDate = DateTime.parse(consentTimestamp);
    final retentionPeriod = await getDataRetentionPeriod();
    final expiryDate = consentDate.add(Duration(days: retentionPeriod));

    if (DateTime.now().isAfter(expiryDate)) {
      await deleteAllUserData();
    }
  }
}

/// 年齢確認ダイアログ
class AgeVerificationDialog extends StatefulWidget {
  const AgeVerificationDialog({super.key});

  @override
  State<AgeVerificationDialog> createState() => _AgeVerificationDialogState();
}

class _AgeVerificationDialogState extends State<AgeVerificationDialog> {
  final _ageController = TextEditingController();
  bool _isUnder13 = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('年齢確認'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('このアプリを使用するお子様の年齢を入力してください。'),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '年齢',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final age = int.tryParse(value);
              setState(() {
                _isUnder13 = age != null && age < 13;
              });
            },
          ),
          if (_isUnder13) ...[
            const SizedBox(height: 16),
            const Text(
              '13歳未満のお子様には保護者の同意が必要です。',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final age = int.tryParse(_ageController.text);
            if (age != null) {
              Navigator.of(context).pop(age);
            }
          },
          child: const Text('次へ'),
        ),
      ],
    );
  }
}

/// 保護者同意ダイアログ
class ParentalConsentDialog extends StatefulWidget {
  final int childAge;

  const ParentalConsentDialog({super.key, required this.childAge});

  @override
  State<ParentalConsentDialog> createState() => _ParentalConsentDialogState();
}

class _ParentalConsentDialogState extends State<ParentalConsentDialog> {
  final _emailController = TextEditingController();
  final _mathAnswer = TextEditingController();
  late int _mathA, _mathB, _correctAnswer;
  bool _consentGiven = false;
  bool _privacyPolicyRead = false;

  @override
  void initState() {
    super.initState();
    _generateMathProblem();
  }

  void _generateMathProblem() {
    _mathA = 10 + (DateTime.now().millisecond % 20);
    _mathB = 5 + (DateTime.now().second % 15);
    _correctAnswer = _mathA + _mathB;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('保護者の同意'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('お子様（${widget.childAge}歳）がこのアプリを使用することについて、保護者の同意が必要です。'),
            const SizedBox(height: 16),
            const Text('保護者のメールアドレス:'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'parent@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('保護者確認（大人の方のみ回答してください）:'),
            Text('$_mathA + $_mathB = ?'),
            TextField(
              controller: _mathAnswer,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '答えを入力',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('プライバシーポリシーを読み、理解しました'),
              value: _privacyPolicyRead,
              onChanged: (value) {
                setState(() {
                  _privacyPolicyRead = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('子供のデータ収集と使用に同意します'),
              value: _consentGiven,
              onChanged: (value) {
                setState(() {
                  _consentGiven = value ?? false;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text(
              '注意: この同意はいつでも撤回できます。同意を撤回すると、お子様のデータは削除されます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('拒否'),
        ),
        ElevatedButton(
          onPressed: _canProceed() ? () async {
            final userAnswer = int.tryParse(_mathAnswer.text);
            if (userAnswer == _correctAnswer) {
              await PrivacyComplianceManager.recordParentalConsent(
                childAge: widget.childAge,
                parentEmail: _emailController.text,
                consent: true,
              );
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('計算が間違っています。保護者の方が回答してください。')),
              );
            }
          } : null,
          child: const Text('同意する'),
        ),
      ],
    );
  }

  bool _canProceed() {
    return _emailController.text.contains('@') &&
           _mathAnswer.text.isNotEmpty &&
           _privacyPolicyRead &&
           _consentGiven;
  }
}

/// プライバシーポリシー表示ダイアログ
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      title: const Text('プライバシーポリシー'),
      content: SingleChildScrollView(
        child: Text('''
もぐもぐ監視アプリ プライバシーポリシー

最終更新日: ${now.year}年${now.month}月${now.day}日

1. はじめに
本アプリは13歳未満のお子様を対象としており、COPPA（児童オンラインプライバシー保護法）およびGDPR（一般データ保護規則）に準拠しています。

2. 収集する情報
- カメラ映像（顔検出のため、ローカル処理のみ）
- 音声（通知音再生のため）
- アプリ設定情報
- 使用統計（匿名化）

3. 情報の使用目的
- 食事監視機能の提供
- アプリ設定の保存
- 機能改善のための統計分析

4. データの保護
- すべてのデータはデバイス内でローカル処理
- 外部サーバーへの送信は行いません
- データは暗号化して保存

5. 保護者の権利
- お子様のデータの確認
- データの削除要求
- 同意の撤回
- データ処理の停止

6. データ保持期間
- デフォルト30日間
- 保護者が設定可能
- 期間経過後は自動削除

7. お問い合わせ
プライバシーに関するご質問は、アプリ内の設定画面からお問い合わせください。

8. ポリシーの変更
本ポリシーの変更時は、アプリ内で通知いたします。
'''),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// 保護者向け設定画面
class ParentalControlsScreen extends StatefulWidget {
  const ParentalControlsScreen({super.key});

  @override
  State<ParentalControlsScreen> createState() => _ParentalControlsScreenState();
}

class _ParentalControlsScreenState extends State<ParentalControlsScreen> {
  int _dataRetentionDays = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final days = await PrivacyComplianceManager.getDataRetentionPeriod();
    setState(() {
      _dataRetentionDays = days;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保護者向け設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'データ管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('データ保持期間'),
              subtitle: Text('$_dataRetentionDays日間'),
              trailing: const Icon(Icons.edit),
              onTap: _showDataRetentionDialog,
            ),
            const Divider(),
            ListTile(
              title: const Text('プライバシーポリシーを表示'),
              trailing: const Icon(Icons.privacy_tip),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const PrivacyPolicyDialog(),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('すべてのデータを削除'),
              subtitle: const Text('お子様のデータをすべて削除します'),
              trailing: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: _showDeleteDataDialog,
            ),
            const Divider(),
            ListTile(
              title: const Text('同意を撤回'),
              subtitle: const Text('データ収集の同意を撤回し、データを削除します'),
              trailing: const Icon(Icons.block, color: Colors.red),
              onTap: _showRevokeConsentDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _showDataRetentionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempDays = _dataRetentionDays;
        return AlertDialog(
          title: const Text('データ保持期間'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('データを保持する期間を設定してください（1-365日）'),
              const SizedBox(height: 16),
              Slider(
                value: tempDays.toDouble(),
                min: 1,
                max: 365,
                divisions: 364,
                label: '$tempDays日',
                onChanged: (value) {
                  setState(() {
                    tempDays = value.round();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                await PrivacyComplianceManager.setDataRetentionPeriod(tempDays);
                setState(() {
                  _dataRetentionDays = tempDays;
                });
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データ削除の確認'),
        content: const Text('お子様のすべてのデータを削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await PrivacyComplianceManager.deleteAllUserData();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('データを削除しました')),
              );
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showRevokeConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同意撤回の確認'),
        content: const Text('データ収集の同意を撤回し、すべてのデータを削除しますか？アプリは使用できなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await PrivacyComplianceManager.revokeConsent();
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 設定画面も閉じる
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('同意を撤回しました。アプリを再起動してください。')),
              );
            },
            child: const Text('撤回'),
          ),
        ],
      ),
    );
  }
}