import React from 'react';

const PricingSection: React.FC = () => {
  return (
    <section id="pricing" className="py-16 bg-gray-50 section-fade">
      <div className="container mx-auto px-4">
        <h2 className="text-2xl md:text-3xl font-bold text-center mb-4 text-gray-900">料金プラン</h2>
        <p className="text-center text-gray-600 mb-12 max-w-2xl mx-auto">基本機能は無料でご利用いただけます。広告なしで快適にお使いいただくには、買い切り480円のプレミアムプランをご利用ください</p>
        
        <div className="max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Free Plan */}
          <div className="bg-white rounded-xl shadow-sm hover:shadow-md transition-shadow overflow-hidden">
            <div className="p-6 border-b border-gray-100">
              <h3 className="text-xl font-bold mb-2">無料プラン</h3>
              <div className="flex items-end mb-4">
                <span className="text-3xl font-bold">¥0</span>
              </div>
              <p className="text-gray-600">すべての基本機能を無料でお使いいただけます</p>
            </div>
            <div className="p-6">
              <ul className="space-y-3">
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>AI口の動き検知機能</span>
                </li>
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>テレビ自動停止</span>
                </li>
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>音声お知らせ</span>
                </li>
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>カスタマイズ設定</span>
                </li>
                <li className="flex items-start text-orange-600">
                  <i className="ri-advertisement-line mt-1 mr-2"></i>
                  <span>広告表示あり</span>
                </li>
              </ul>
              <a href="/signup/free" className="mt-8 block w-full py-3 px-4 bg-gray-100 text-gray-800 text-center rounded-button font-medium hover:bg-gray-200 transition-colors whitespace-nowrap">無料ではじめる</a>
            </div>
          </div>
          
          {/* Premium Plan */}
          <div className="bg-white rounded-xl shadow-md hover:shadow-lg transition-shadow overflow-hidden border-2 border-primary relative">
            <div className="absolute top-0 right-0 bg-primary text-white px-3 py-1 text-sm font-medium rounded-bl-lg">おすすめ</div>
            <div className="p-6 border-b border-gray-100">
              <h3 className="text-xl font-bold mb-2">プレミアムプラン</h3>
              <div className="flex items-end mb-4">
                <span className="text-3xl font-bold">¥480</span>
                <span className="text-gray-500 ml-1">買い切り</span>
              </div>
              <p className="text-gray-600">一度のお支払いで広告を永続的に非表示にできます</p>
            </div>
            <div className="p-6">
              <ul className="space-y-3">
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>AI口の動き検知機能</span>
                </li>
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>テレビ自動停止</span>
                </li>
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>音声お知らせ</span>
                </li>
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>カスタマイズ設定</span>
                </li>
                <li className="flex items-start">
                  <i className="ri-check-line text-primary mt-1 mr-2"></i>
                  <span>広告なし</span>
                </li>
              </ul>
              <a href="/signup/premium" className="mt-8 block w-full py-3 px-4 bg-primary text-white text-center rounded-button font-medium hover:bg-opacity-90 transition-colors whitespace-nowrap">480円で広告を削除</a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default PricingSection; 