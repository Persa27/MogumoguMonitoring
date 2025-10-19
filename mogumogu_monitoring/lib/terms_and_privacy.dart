import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// プライバシーポリシーと利用規約の管理クラス
class TermsAndPrivacyManager {
  static const String _keyTermsAccepted = 'terms_accepted';
  static const String _keyPrivacyAccepted = 'privacy_accepted';

  /// 規約に同意済みかどうかを確認
  static Future<bool> isTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTermsAccepted) ?? false;
  }

  /// プライバシーポリシーに同意済みかどうかを確認
  static Future<bool> isPrivacyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPrivacyAccepted) ?? false;
  }

  /// 両方の規約に同意済みかどうかを確認
  static Future<bool> isAllAccepted() async {
    return await isTermsAccepted() && await isPrivacyAccepted();
  }

  /// 規約同意状態を保存
  static Future<void> setTermsAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTermsAccepted, accepted);
  }

  /// プライバシーポリシー同意状態を保存
  static Future<void> setPrivacyAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivacyAccepted, accepted);
  }
}

/// プライバシーポリシーと利用規約の文面
class TermsContent {
  static const String privacyPolicy = '''
プライバシーポリシー

本アプリケーション「もぐもぐウォッチ」（以下「本アプリ」）をご利用いただき、ありがとうございます。本プライバシーポリシーでは、本アプリが収集する情報とその利用方法について説明いたします。

【1. 収集する情報】
本アプリは以下の情報を収集する場合があります：
• カメラで撮影された映像データ（リアルタイム処理のみ、保存されません）
• マイクで録音された音声データ（リアルタイム処理のみ、保存されません）
• アプリの利用状況や設定情報
• 広告配信のための匿名化された使用統計

【2. 情報の利用目的】
収集した情報は以下の目的で利用いたします：
• 食事状況の監視および通知機能の提供
• アプリの機能改善
• 広告配信の最適化

【3. 情報の保存と管理】
• カメラ映像および音声データは端末内でリアルタイム処理され、保存されません
• 設定情報は端末内にのみ保存され、外部に送信されません
• 個人を特定する情報は収集いたしません

【4. 第三者への提供】
本アプリは、以下の場合を除き、収集した情報を第三者に提供いたしません：
• Google AdMob（広告配信サービス）への匿名化された統計情報
• 法令に基づく開示要求がある場合

【5. 広告について】
本アプリではGoogle AdMobを使用して広告を表示しています。AdMobは匿名化された情報を使用して関連性の高い広告を配信します。

【6. お問い合わせ】
本プライバシーポリシーについてご質問がございましたら、アプリ内のお問い合わせ機能をご利用ください。

最終更新日：2024年12月
''';

  static const String termsOfService = '''
利用規約

本利用規約（以下「本規約」）は、「もぐもぐウォッチ」（以下「本アプリ」）の利用条件を定めるものです。本アプリをご利用になる場合には、本規約に同意していただく必要があります。

【1. アプリの目的と利用条件】
• 本アプリは食事状況の監視を目的とした補助ツールです
• 継続的な監視を前提としており、10分以上の使用が想定されています
• カメラおよびマイクの使用許可が必要です

【2. 禁止事項】
以下の行為を禁止いたします：
• 本アプリを本来の目的以外で使用すること
• 他者のプライバシーを侵害する目的での使用
• 公序良俗に反する用途での使用
• 本アプリの機能を妨害する行為

【3. 免責事項】
• 本アプリの機能は補助的なものであり、完全性を保証するものではありません
• 監視の精度や動作の継続性について一切の保証をいたしません
• 本アプリの使用により生じた損害について、当方は責任を負いません

【4. 知的財産権】
本アプリに関する知的財産権は当方に帰属します。

【5. 規約の変更】
本規約は予告なく変更される場合があります。変更後の規約は、アプリ内で表示された時点で効力を生じます。

【6. 準拠法】
本規約は日本法に準拠し、解釈されるものとします。

【7. お問い合わせ】
本規約についてご質問がございましたら、アプリ内のお問い合わせ機能をご利用ください。

最終更新日：2024年12月
''';
}

/// プライバシーポリシーと利用規約の同意画面
class TermsAndPrivacyScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const TermsAndPrivacyScreen({
    Key? key,
    required this.onAccepted,
  }) : super(key: key);

  @override
  _TermsAndPrivacyScreenState createState() => _TermsAndPrivacyScreenState();
}

class _TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  int _currentPage = 0; // 0: プライバシーポリシー, 1: 利用規約
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _currentPage == 0 ? 'プライバシーポリシー' : '利用規約',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans JP',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ページインジケーター
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0, 'プライバシー\nポリシー'),
                const SizedBox(width: 20),
                Container(
                  width: 40,
                  height: 2,
                  color: _currentPage >= 1 ? const Color(0xFFFF9500) : const Color(0xFFE0E0E0),
                ),
                const SizedBox(width: 20),
                _buildPageIndicator(1, '利用規約'),
              ],
            ),
          ),
          
          // コンテンツ
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildContentPage(
                  TermsContent.privacyPolicy,
                  _privacyAccepted,
                  (value) {
                    setState(() {
                      _privacyAccepted = value;
                    });
                  },
                ),
                _buildContentPage(
                  TermsContent.termsOfService,
                  _termsAccepted,
                  (value) {
                    setState(() {
                      _termsAccepted = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // ボタンエリア
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFFF9500)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '前へ',
                        style: TextStyle(
                          color: Color(0xFFFF9500),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Noto Sans JP',
                        ),
                      ),
                    ),
                  ),
                
                if (_currentPage > 0) const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage == 0 && _privacyAccepted
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : _currentPage == 1 && _termsAccepted && _privacyAccepted
                            ? _onAllAccepted
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9500),
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentPage == 0 ? '次へ' : 'アプリを開始',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans JP',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int page, String label) {
    final isActive = _currentPage >= page;
    final isCompleted = (page == 0 && _privacyAccepted) || (page == 1 && _termsAccepted);
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFFF9500)
                : isActive
                    ? const Color(0xFFFF9500)
                    : const Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'Noto Sans JP',
            color: isActive ? const Color(0xFF333333) : const Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildContentPage(String content, bool isAccepted, Function(bool) onChanged) {
    return Column(
      children: [
        // コンテンツスクロール領域
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'Noto Sans JP',
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ),
        
        // 同意チェックボックス
        Container(
          margin: const EdgeInsets.all(20),
          child: Row(
            children: [
              Checkbox(
                value: isAccepted,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: const Color(0xFFFF9500),
              ),
              Expanded(
                child: Text(
                  _currentPage == 0 
                      ? '上記のプライバシーポリシーに同意します'
                      : '上記の利用規約に同意します',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Noto Sans JP',
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onAllAccepted() async {
    // 同意状態を保存
    await TermsAndPrivacyManager.setTermsAccepted(true);
    await TermsAndPrivacyManager.setPrivacyAccepted(true);
    
    // コールバック実行
    widget.onAccepted();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
