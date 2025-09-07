import React, { useState, useEffect } from 'react';

const Header: React.FC = () => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    // Header scroll effect
    const handleScroll = () => {
      const header = document.getElementById('header');
      if (header) {
        if (window.scrollY > 50) {
          header.classList.add('py-2');
          header.classList.remove('py-3');
        } else {
          header.classList.add('py-3');
          header.classList.remove('py-2');
        }
      }
    };

    window.addEventListener('scroll', handleScroll);
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  const toggleMobileMenu = () => {
    setMobileMenuOpen(!mobileMenuOpen);
  };

  const handleLinkClick = () => {
    setMobileMenuOpen(false);
  };

  return (
    <header id="header" className="header-shrink fixed w-full bg-white shadow-md z-50 transition-all duration-300">
      <div className="container mx-auto px-4 py-3 flex items-center justify-between">
        <div className="flex items-center">
          <h1 className="text-2xl font-pacifico text-primary">もぐもぐウォッチ<span className="text-secondary">🍽️</span></h1>
        </div>
        
        <div className="hidden md:flex items-center space-x-6">
          <a href="#features" className="text-gray-700 hover:text-primary">機能</a>
          <a href="#how-it-works" className="text-gray-700 hover:text-primary">使い方</a>
          <a href="#pricing" className="text-gray-700 hover:text-primary">料金</a>
          <a href="#faq" className="text-gray-700 hover:text-primary">よくある質問</a>
        </div>
        
        <div>
          <a href="#waiting-list" className="bg-primary text-white px-4 py-2 rounded-button whitespace-nowrap font-medium hover:bg-opacity-90 transition-all">リリース通知を受け取る</a>
        </div>
        
        <div className="md:hidden flex items-center">
          <button onClick={toggleMobileMenu} className="w-8 h-8 flex items-center justify-center">
            <i className={`${mobileMenuOpen ? 'ri-close-line' : 'ri-menu-line'} ri-lg`}></i>
          </button>
        </div>
      </div>
      
      {/* Mobile menu */}
      <div className={`md:hidden ${mobileMenuOpen ? '' : 'hidden'} bg-white shadow-lg absolute w-full`}>
        <div className="container mx-auto px-4 py-3 flex flex-col space-y-3">
          <a href="#features" className="text-gray-700 py-2 border-b border-gray-100" onClick={handleLinkClick}>機能</a>
          <a href="#how-it-works" className="text-gray-700 py-2 border-b border-gray-100" onClick={handleLinkClick}>使い方</a>
          <a href="#pricing" className="text-gray-700 py-2 border-b border-gray-100" onClick={handleLinkClick}>料金</a>
          <a href="#faq" className="text-gray-700 py-2" onClick={handleLinkClick}>よくある質問</a>
        </div>
      </div>
    </header>
  );
};

export default Header; 