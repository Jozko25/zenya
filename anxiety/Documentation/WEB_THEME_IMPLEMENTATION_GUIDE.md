# Web App Theme Implementation Guide

## Overview
This document provides implementation instructions for adding dynamic theme support to the Zenya wellness app web onboarding. The iOS app now passes theme preferences via URL parameters to create a seamless user experience.

## iOS App Changes Implemented

### URL Parameter System
The iOS app now generates dynamic URLs with theme information:

```
https://zenya-web.vercel.app?theme=dark&device=phone&source=ios
```

### Parameters Passed
- `theme`: "light" or "dark" (user's system preference)
- `device`: "phone" or "tablet" (device type for responsive design)
- `source`: "ios" (traffic source identification)

### iOS Implementation Details
```swift
private var webURL: String {
    let baseURL = "https://zenya-web.vercel.app"
    let colorSchemeParam = colorScheme == .dark ? "dark" : "light"
    let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
    return "\(baseURL)?theme=\(colorSchemeParam)&device=\(deviceType)&source=ios"
}
```

---

## LLM Prompt for Web Development Team

```markdown
I need to implement dynamic theming support for a wellness app's onboarding website. The website currently only supports dark mode, but I need it to adapt to the user's device theme preference.

### CONTEXT:
- This is a wellness/mental health app onboarding website (Zenya)
- Users are coming from a native iOS app that detects their system theme preference
- The iOS app passes URL parameters to indicate the user's preferred theme
- Currently the website is hardcoded to dark mode
- The site is hosted on Vercel at: https://zenya-web.vercel.app

### URL PARAMETERS RECEIVED:
- `theme`: Either "light" or "dark" (user's system preference)
- `device`: Either "phone" or "tablet" (device type)
- `source`: "ios" (indicating they came from the iOS app)

### REQUIREMENTS:

#### 1. Theme Detection & Implementation
```javascript
// Required functionality structure:
function initializeTheme() {
  const urlParams = new URLSearchParams(window.location.search);
  const themeParam = urlParams.get('theme');
  const deviceParam = urlParams.get('device');
  const sourceParam = urlParams.get('source');
  
  // Parse theme parameter
  let theme = 'light'; // Default fallback
  if (themeParam === 'dark' || themeParam === 'light') {
    theme = themeParam;
  } else {
    // Fallback to system preference detection
    theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  
  // Apply theme
  applyTheme(theme, deviceParam);
}
```

#### 2. CSS Variable System
```css
:root {
  /* Light Theme (Default) */
  --bg-primary: #f8f9fa;
  --bg-secondary: #ffffff;
  --bg-card: #ffffff;
  --text-primary: #1a1a1a;
  --text-secondary: #4a4a4a;
  --text-tertiary: #6b7280;
  --text-hint: #9ca3af;
  
  /* Wellness-specific colors */
  --accent-lavender: #b4a7d6;
  --accent-blue: #3b82f6;
  --accent-orange: #f59e0b;
  --accent-green: #10b981;
  --accent-pink: #fce4ec;
  --accent-teal: #e0f2f1;
  
  /* Interactive elements */
  --button-primary-bg: var(--accent-lavender);
  --button-primary-text: #ffffff;
  --button-secondary-bg: #f3f4f6;
  --button-secondary-text: var(--text-primary);
  --input-bg: #ffffff;
  --input-border: #d1d5db;
  --input-focus-border: var(--accent-lavender);
  
  /* Shadows and effects */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
}

[data-theme="dark"] {
  /* Dark Theme */
  --bg-primary: #121212;
  --bg-secondary: #1a1a1a;
  --bg-card: #2a2a2a;
  --text-primary: #e0e0e0;
  --text-secondary: #b0b0b0;
  --text-tertiary: #808080;
  --text-hint: #6b7280;
  
  /* Adjusted accent colors for dark mode */
  --accent-lavender: #9b86bd;
  --accent-blue: #6b9bd1;
  --accent-orange: #f4c95d;
  --accent-green: #7fb685;
  --accent-pink: #d4b8c5;
  --accent-teal: #8fa8b8;
  
  /* Interactive elements */
  --button-primary-bg: var(--accent-lavender);
  --button-primary-text: #ffffff;
  --button-secondary-bg: #2f2f2f;
  --button-secondary-text: var(--text-primary);
  --input-bg: #2f2f2f;
  --input-border: #404040;
  --input-focus-border: var(--accent-lavender);
  
  /* Shadows for dark mode */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.3);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.4);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.5);
}
```

#### 3. Base Component Styles
```css
/* Apply variables to components */
body {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
}

.card {
  background-color: var(--bg-card);
  border-radius: 16px;
  box-shadow: var(--shadow-md);
  padding: 24px;
  transition: background-color 0.3s ease, box-shadow 0.3s ease;
}

.btn-primary {
  background: linear-gradient(135deg, var(--accent-lavender), var(--accent-blue));
  color: var(--button-primary-text);
  border: none;
  border-radius: 12px;
  padding: 16px 24px;
  font-weight: 600;
  transition: all 0.3s ease;
  box-shadow: var(--shadow-md);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.input {
  background-color: var(--input-bg);
  border: 2px solid var(--input-border);
  border-radius: 12px;
  color: var(--text-primary);
  padding: 16px;
  transition: all 0.3s ease;
}

.input:focus {
  border-color: var(--input-focus-border);
  outline: none;
  box-shadow: 0 0 0 3px var(--accent-lavender)25;
}

.text-primary { color: var(--text-primary); }
.text-secondary { color: var(--text-secondary); }
.text-tertiary { color: var(--text-tertiary); }
```

#### 4. JavaScript Implementation
```javascript
// Complete theme management system
class ThemeManager {
  constructor() {
    this.currentTheme = 'light';
    this.init();
  }
  
  init() {
    // Get theme from URL parameter
    const urlParams = new URLSearchParams(window.location.search);
    const themeParam = urlParams.get('theme');
    const deviceParam = urlParams.get('device');
    
    // Determine theme
    if (themeParam === 'dark' || themeParam === 'light') {
      this.currentTheme = themeParam;
    } else {
      // Fallback to system preference
      this.currentTheme = this.detectSystemTheme();
    }
    
    // Apply theme immediately
    this.applyTheme(this.currentTheme);
    
    // Listen for system theme changes
    this.watchSystemTheme();
    
    // Store device info for analytics
    if (deviceParam) {
      this.handleDeviceType(deviceParam);
    }
  }
  
  detectSystemTheme() {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }
    return 'light';
  }
  
  applyTheme(theme) {
    this.currentTheme = theme;
    document.documentElement.setAttribute('data-theme', theme);
    
    // Store preference
    localStorage.setItem('theme', theme);
    
    // Dispatch event for other components
    window.dispatchEvent(new CustomEvent('themeChanged', { 
      detail: { theme: theme } 
    }));
  }
  
  watchSystemTheme() {
    if (window.matchMedia) {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      mediaQuery.addListener((e) => {
        // Only auto-switch if user hasn't manually selected a theme
        const storedTheme = localStorage.getItem('theme');
        if (!storedTheme) {
          this.applyTheme(e.matches ? 'dark' : 'light');
        }
      });
    }
  }
  
  handleDeviceType(deviceType) {
    document.documentElement.setAttribute('data-device', deviceType);
    
    // Apply device-specific optimizations
    if (deviceType === 'tablet') {
      document.body.classList.add('tablet-layout');
    } else if (deviceType === 'phone') {
      document.body.classList.add('mobile-layout');
    }
  }
  
  toggleTheme() {
    const newTheme = this.currentTheme === 'light' ? 'dark' : 'light';
    this.applyTheme(newTheme);
  }
}

// Initialize theme manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  window.themeManager = new ThemeManager();
});
```

#### 5. Wellness-Specific Design Requirements

**Visual Hierarchy:**
- Soft, rounded corners (border-radius: 12px+)
- Gentle gradients rather than harsh color transitions
- Subtle shadows for depth without being overwhelming
- Adequate spacing for a calming, uncluttered feel

**Color Psychology:**
- Light mode: Calming blues, soft greens, warm whites
- Dark mode: Muted colors, warm grays (#121212 instead of pure black)
- Maintain therapeutic, calming feel in both themes

**Accessibility:**
- WCAG 2.1 AA compliance for contrast ratios
- Minimum 4.5:1 contrast for normal text
- Minimum 3:1 contrast for large text
- Focus indicators visible in both themes

#### 6. Responsive Considerations
```css
/* Device-specific optimizations */
.mobile-layout {
  /* Mobile-specific styles */
  padding: 16px;
}

.tablet-layout {
  /* Tablet-specific styles */
  max-width: 768px;
  margin: 0 auto;
  padding: 24px;
}

/* Responsive breakpoints */
@media (max-width: 640px) {
  .card {
    padding: 16px;
    margin: 8px;
  }
  
  .btn-primary {
    width: 100%;
    padding: 18px;
  }
}
```

#### 7. Loading States and Animations
```css
/* Skeleton loading for dark/light themes */
.skeleton {
  background: linear-gradient(90deg, 
    var(--bg-card) 25%, 
    var(--bg-secondary) 50%, 
    var(--bg-card) 75%
  );
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
}

@keyframes loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* Smooth theme transitions */
* {
  transition: background-color 0.3s ease, 
              color 0.3s ease, 
              border-color 0.3s ease, 
              box-shadow 0.3s ease;
}
```

### DELIVERABLES:
1. ✅ Complete theme detection and switching system
2. ✅ CSS variable system with wellness-focused color palette
3. ✅ Smooth theme transition animations
4. ✅ Device-responsive design optimizations
5. ✅ WCAG accessibility compliance
6. ✅ Loading states and skeleton screens
7. ✅ Analytics tracking for theme usage

### TESTING CHECKLIST:
- [ ] Theme switches correctly based on URL parameter
- [ ] Fallback to system preference works when parameter is missing
- [ ] All text has sufficient contrast in both themes
- [ ] Interactive elements (buttons, forms) work in both themes
- [ ] Smooth transitions between theme changes
- [ ] Mobile and tablet layouts work properly
- [ ] Loading states are visible in both themes
- [ ] Focus indicators are visible and accessible

Please implement this system to create a seamless, calming user experience that matches the user's device theme preference and maintains the therapeutic quality of the wellness app.
```

---

## Implementation Priority

### Phase 1 (Immediate - Required for iOS App)
1. URL parameter detection (`theme`, `device`, `source`)
2. Basic light/dark theme CSS variables
3. Theme application on page load

### Phase 2 (Enhanced Experience)
1. Smooth theme transitions
2. System theme change detection
3. Theme preference persistence

### Phase 3 (Polish)
1. Device-specific optimizations
2. Advanced animations
3. Analytics integration

## Testing URLs

After implementation, test with these URLs:

- Light theme: `https://zenya-web.vercel.app?theme=light&device=phone&source=ios`
- Dark theme: `https://zenya-web.vercel.app?theme=dark&device=tablet&source=ios`
- No parameters: `https://zenya-web.vercel.app` (should fallback to system preference)

---

## Support

For questions about the iOS implementation or theme requirements, reference:
- `ActivationLandingView.swift` - URL generation logic
- `InAppWebView.swift` - WebView implementation
- `AdaptiveColorSystem.swift` - Color system used in iOS app
- `OnboardingDesignSystem.swift` - Design tokens and components

---

*Last updated: October 23, 2025*