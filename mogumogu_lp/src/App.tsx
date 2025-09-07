import React, { useEffect } from 'react';
import Header from './components/Header';
import HeroSection from './components/HeroSection';
import PainPointsSection from './components/PainPointsSection';
import SolutionSection from './components/SolutionSection';
import FeaturesSection from './components/FeaturesSection';

import HowItWorksSection from './components/HowItWorksSection';
import PricingSection from './components/PricingSection';
import FAQSection from './components/FAQSection';
import WaitingListSection from './components/WaitingListSection';
import PrivacyBanner from './components/PrivacyBanner';
import Footer from './components/Footer';
import { initSmoothScroll } from './utils/smoothScroll';
import './App.css';

function App() {
  useEffect(() => {
    // Scroll animation
    const sections = document.querySelectorAll('.section-fade');
    
    const fadeInSection = function() {
      sections.forEach(section => {
        const sectionTop = section.getBoundingClientRect().top;
        const windowHeight = window.innerHeight;
        
        if (sectionTop < windowHeight * 0.85) {
          section.classList.add('visible');
        }
      });
    };
    
    // Initial check
    fadeInSection();
    
    // Check on scroll
    window.addEventListener('scroll', fadeInSection);
    
    // Initialize smooth scroll
    initSmoothScroll();
    
    return () => {
      window.removeEventListener('scroll', fadeInSection);
    };
  }, []);



  return (
    <div className="App bg-white">
      
      <Header />
      <HeroSection />
      <PainPointsSection />
      <SolutionSection />
      <FeaturesSection />

      <HowItWorksSection />
      <PricingSection />
      <FAQSection />
      <WaitingListSection />
      <PrivacyBanner />
      <Footer />
    </div>
  );
}

export default App;
