/**
 * FOUC (Flash of Unstyled Content) prevention script.
 * This script runs before React hydration to apply the correct theme class
 * and CSS variables to the HTML element, preventing a flash of wrong theme colors.
 */
export const themeScript = `
(function() {
  var darkVars = {
    '--primary': '#F39C12',
    '--primary-light': '#5D4037',
    '--primary-dark': '#E67E22',
    '--secondary': '#8D6E63',
    '--success': '#2ECC71',
    '--error': '#E74C3C',
    '--rating': '#F1C40F',
    '--hashtag': '#66BB6A',
    '--background': '#121212',
    '--surface': '#1E1E1E',
    '--text-primary': '#E8E8E8',
    '--text-secondary': '#A0A0A0',
    '--text-logo': '#F5F5F5',
    '--border': '#333333',
    '--highlight-bg': '#2D2D2D',
    '--diff-added': '#2ECC71',
    '--diff-added-bg': '#1A3A2A',
    '--diff-removed': '#E74C3C',
    '--diff-removed-bg': '#3A1A1A',
    '--diff-modified': '#F39C12',
    '--diff-modified-bg': '#3A2A1A'
  };

  function getTheme() {
    var stored = localStorage.getItem('theme');
    if (stored === 'dark' || stored === 'light') return stored;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  if (getTheme() === 'dark') {
    var root = document.documentElement;
    root.classList.add('dark');
    root.style.colorScheme = 'dark';
    Object.keys(darkVars).forEach(function(key) {
      root.style.setProperty(key, darkVars[key]);
    });
  }
})();
`;
