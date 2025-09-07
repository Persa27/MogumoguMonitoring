import React from 'react';

const FeaturesSection: React.FC = () => {
  const features = [
    {
      icon: 'ri-eye-line',
      title: 'AI口の動きセンサー',
      description: '高精度AIが口の動きを検知し、リアルタイムで分析。プライバシーを守るため、すべての処理はデバイス内で完結します。'
    },
    {
      icon: 'ri-remote-control-line',
      title: 'テレビ自動停止',
      description: '口の動きが指定した秒数以上止まると、キャスト中の動画アプリと連携してテレビを自動停止。食事に集中できる環境を作ります。'
    },
    {
      icon: 'ri-volume-vibrate-line',
      title: '音声お知らせ',
      description: '口の動きが止まると設定した音声でお知らせ。食事に集中できるようサポートします。'
    },
    {
      icon: 'ri-settings-line',
      title: 'カスタマイズ設定',
      description: '停止までの秒数や音声の種類など、お子さまの個性に合わせて細かく設定可能。家族それぞれに最適な環境を作れます。'
    }
  ];

  return (
    <section id="features" className="py-16 bg-gray-50 section-fade">
      <div className="container mx-auto px-4">
        <h2 className="text-2xl md:text-3xl font-bold text-center mb-12 text-gray-900">主な機能</h2>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <div key={index} className="bg-white p-6 rounded-lg shadow-sm hover:shadow-md transition-shadow">
              <div className="w-12 h-12 flex items-center justify-center mb-4 bg-primary/10 rounded-full">
                <i className={`${feature.icon} ri-lg text-primary`}></i>
              </div>
              <h3 className="text-lg font-semibold mb-3">{feature.title}</h3>
              <p className="text-gray-600 text-sm">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection; 