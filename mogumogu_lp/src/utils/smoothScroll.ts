export const smoothScrollTo = (targetId: string) => {
  const targetElement = document.querySelector(targetId);
  if (targetElement) {
    const headerHeight = document.getElementById('header')?.offsetHeight || 0;
    const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - headerHeight;
    
    window.scrollTo({
      top: targetPosition,
      behavior: 'smooth'
    });
  }
};

export const initSmoothScroll = () => {
  const links = document.querySelectorAll('a[href^="#"]');
  
  links.forEach(link => {
    link.addEventListener('click', function(e: Event) {
      e.preventDefault();
      
      const target = e.target as HTMLAnchorElement;
      const targetId = target.getAttribute('href');
      if (targetId && targetId !== '#') {
        smoothScrollTo(targetId);
      }
    });
  });
}; 