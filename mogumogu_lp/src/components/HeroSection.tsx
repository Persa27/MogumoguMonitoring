import React from 'react';

const HeroSection: React.FC = () => {
  return (
    <section className="pt-24 md:pt-32 relative overflow-hidden">
      {/* <div 
        className="absolute inset-0 bg-cover bg-center" 
        style={{
          backgroundImage: `url('/helosection_background.png')`
        }}
      ></div>
      <div className="absolute inset-0 bg-gradient-to-r from-white via-white/90 to-transparent"></div> */}
      {/* ① 背景画像 */}
      <div
        className="absolute inset-0 bg-cover bg-center"
        style={{ backgroundImage: "url('/helosection_background.png')" }}
      />

      {/* ② 白→透明 グラデーション（左 0〜30% を白で固定、60% 以降を完全透過） */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'linear-gradient(to right, ' +
            'rgba(255,255,255,1) 0%, ' +      // 完全に白
            'rgba(255,255,255,0.95) 25%, ' + // 少し透過
            'rgba(255,255,255,0.8) 50%, ' +  // ここまでを「ほぼ白」で保持
            'rgba(255,255,255,0) 70%)'       // 60% 以降で完全透過
        }}
      />

      <div className="container mx-auto px-4 py-16 md:py-24 relative">
        <div className="max-w-xl">
          <h1 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 text-gray-900 leading-tight">
            テレビに夢中でも、<br />"もぐもぐ"は止めない。
          </h1>
          <h2 className="text-lg md:text-xl text-gray-700 mb-8 leading-relaxed">
            食事中の口の動きをAIで見守り、止まったらテレビもピタッ。<br />家族時間を1分でも長くするスマート習慣。
          </h2>
          <a href="#waiting-list" className="inline-flex items-center bg-primary text-white px-6 py-3 rounded-button text-lg font-medium hover:bg-opacity-90 transition-all">
            リリース通知を受け取る <i className="ri-notification-line ml-2 ri-lg"></i>
          </a>
        </div>
      </div>
    </section>
  );
};

export default HeroSection; 