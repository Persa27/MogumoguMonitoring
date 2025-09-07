import React from 'react';

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-900 text-white py-12">
      <div className="container mx-auto px-4">
        <div className="flex flex-col items-center text-center">
          {/* Logo and info */}
          <div className="mb-8">
            <h2 className="text-2xl font-pacifico text-white mb-4">もぐもぐウォッチ<span className="text-secondary">🍽️</span></h2>
            <p className="text-gray-400 mb-6 max-w-md">AI技術で食事習慣を改善し、家族の時間をより豊かにします。</p>
            <div className="flex justify-center space-x-4">
              <a href="https://x.com/tama_develop" className="w-10 h-10 flex items-center justify-center bg-gray-800 rounded-full hover:bg-primary transition-colors">
                <i className="ri-twitter-x-line"></i>
              </a>
            </div>
          </div>
          
          {/* App Store Links */}
          <div className="flex justify-center space-x-6 mb-8">
            <a href="https://apps.apple.com" className="flex items-center text-gray-400 hover:text-white transition-colors">
              <i className="ri-apple-fill mr-2 text-xl"></i> 
              <span>App Store</span>
            </a>
            <a href="https://play.google.com" className="flex items-center text-gray-400 hover:text-white transition-colors">
              <i className="ri-google-play-fill mr-2 text-xl"></i> 
              <span>Google Play</span>
            </a>
          </div>
        </div>
        
        <div className="border-t border-gray-800 pt-8 text-center">
          <p className="text-gray-500 text-sm">© 2025 もぐもぐウォッチ All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer; 