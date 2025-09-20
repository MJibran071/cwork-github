# Asset Optimization Guide for CWork Mobile App

This document outlines the asset optimization strategy for the CWork mobile application, ensuring optimal performance across all screen sizes and resolutions.

## Asset Directory Structure

```
assets/
├── images/          # PNG/JPEG images with multiple resolutions
│   ├── 1.0x/       # Base resolution (1x)
│   ├── 2.0x/       # High resolution (2x)
│   └── 3.0x/       # Extra high resolution (3x)
├── icons/          # App icons and UI icons
│   ├── 1.0x/
│   ├── 2.0x/
│   └── 3.0x/
└── svg/            # Vector graphics (SVG format)
    ├── app_logo.svg
    ├── wallet_icon.svg
    ├── project_icon.svg
    └── escrow_icon.svg
```

## Resolution Guidelines

### For PNG/JPEG Images:
- **1.0x**: Base resolution (e.g., 48x48px)
- **2.0x**: 2x resolution (e.g., 96x96px)  
- **3.0x**: 3x resolution (e.g., 144x144px)

### For Icons:
- Use Material Design icons where possible
- Custom icons should follow the same resolution structure
- Prefer SVG for custom icons when possible

## SVG Optimization Best Practices

1. **Minimize file size**: Remove unnecessary metadata, comments, and whitespace
2. **Optimize paths**: Use simplified path data where possible
3. **Responsive design**: Design SVGs to scale properly at different sizes
4. **Accessibility**: Include proper titles and descriptions for screen readers

## Flutter SVG Usage

```dart
import 'package:flutter_svg/flutter_svg.dart';

// Basic SVG usage
SvgPicture.asset(
  'assets/svg/app_logo.svg',
  width: 100,
  height: 100,
  semanticsLabel: 'CWork App Logo',
);

// With color theming
SvgPicture.asset(
  'assets/svg/wallet_icon.svg',
  color: Theme.of(context).colorScheme.primary,
);
```

## Performance Considerations

1. **Preload common assets**: Load frequently used assets at app startup
2. **Cache strategically**: Implement proper caching for network-loaded assets
3. **Lazy loading**: Load assets only when needed
4. **Memory management**: Dispose of assets when no longer needed

## Testing Checklist

- [ ] Test assets on different screen densities (1x, 2x, 3x)
- [ ] Verify SVG rendering on all target devices
- [ ] Check color contrast for accessibility
- [ ] Test loading performance with large assets
- [ ] Verify asset caching behavior

## Recommended Tools

- **SVG Optimization**: SVGO, Figma Export
- **Image Compression**: TinyPNG, ImageOptim
- **Icon Generation**: Android Studio Image Asset Studio, Xcode Asset Catalog
- **Testing**: Device lab with multiple screen densities