import React from 'react';

const SolutionSection: React.FC = () => {
  return (
    <section id="solution" className="py-16 bg-white section-fade">
      <div className="container mx-auto px-4">
        <h2 className="text-2xl md:text-3xl font-bold text-center mb-4 text-gray-900">もぐもぐウォッチで解決！</h2>
        <p className="text-center text-gray-600 mb-12 max-w-2xl mx-auto">
          AIが口の動きを自動検知し、お子さまの食事をサポート。<br />親の負担を減らしながら、楽しい食事時間を実現します。
        </p>
        
        <div className="flex flex-col md:flex-row items-center justify-center gap-4 md:gap-8 max-w-4xl mx-auto">
          {/* Step 1 */}
          <div className="bg-gray-50 p-6 rounded-lg text-center w-full md:w-1/3">
            <div className="w-16 h-16 flex items-center justify-center mx-auto mb-4 bg-primary/10 rounded-full">
              <i className="ri-camera-line ri-xl text-primary"></i>
            </div>
            <h3 className="text-lg font-semibold mb-2">カメラで見守り</h3>
            <p className="text-gray-600 text-sm">スマホのカメラが子どもの顔を優しく見守ります</p>
          </div>
          
          <div className="hidden md:block">
            <i className="ri-arrow-right-line ri-xl text-primary"></i>
          </div>
          <div className="block md:hidden">
            <i className="ri-arrow-down-line ri-xl text-primary"></i>
          </div>
          
          {/* Step 2 */}
          <div className="bg-gray-50 p-6 rounded-lg text-center w-full md:w-1/3">
            <div className="w-16 h-16 flex items-center justify-center mx-auto mb-4 bg-primary/10 rounded-full">
              <i className="ri-brain-line ri-xl text-primary"></i>
            </div>
            <h3 className="text-lg font-semibold mb-2">AI口の動き検知</h3>
            <p className="text-gray-600 text-sm">最先端AIが口の動きを正確に検知します</p>
          </div>
          
          <div className="hidden md:block">
            <i className="ri-arrow-right-line ri-xl text-primary"></i>
          </div>
          <div className="block md:hidden">
            <i className="ri-arrow-down-line ri-xl text-primary"></i>
          </div>
          
          {/* Step 3 */}
          <div className="bg-gray-50 p-6 rounded-lg text-center w-full md:w-1/3">
            <div className="w-16 h-16 flex items-center justify-center mx-auto mb-4 bg-primary/10 rounded-full">
              <i className="ri-tv-line ri-xl text-primary"></i>
            </div>
                                <h3 className="text-lg font-semibold mb-2">自動制御</h3>
                    <p className="text-gray-600 text-sm">口の動きが止まるとテレビが停止、もしくは音声が再生されます</p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default SolutionSection; 