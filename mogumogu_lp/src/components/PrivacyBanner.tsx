import React from 'react';

const PrivacyBanner: React.FC = () => {
  return (
    <section className="py-8 bg-gray-100">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row items-center justify-center text-center md:text-left">
          <div className="w-12 h-12 flex items-center justify-center bg-primary/20 rounded-full mb-4 md:mb-0 md:mr-4">
            <i className="ri-shield-check-line ri-lg text-primary"></i>
          </div>
          <p className="text-gray-700">
            <span className="font-medium">プライバシー重視の設計</span> - 映像解析はすべて端末内で完結。COPPA/GDPRの要件を満たすよう開発中です。
          </p>
        </div>
      </div>
    </section>
  );
};

export default PrivacyBanner; 