# CWork Mobile App - Performance Testing Guide

## Overview
This guide covers performance testing using Flutter DevTools and other tools to ensure optimal UI performance, smooth animations, and efficient resource usage.

## Flutter DevTools Setup

### Installation
Flutter DevTools comes bundled with the Flutter SDK. To launch:

```bash
# Run your app in profile mode (for performance testing)
flutter run --profile

# In another terminal, launch DevTools
flutter devtools
```

### Connecting to Running App
1. Start your app in profile mode
2. Open DevTools and connect to the running app
3. Use the various tabs for performance analysis

## Performance Metrics to Monitor

### 1. Frame Rendering Performance
- **Target**: 60fps (16.67ms per frame)
- **Acceptable**: 50-60fps 
- **Poor**: Below 30fps

### 2. Memory Usage
- **Heap memory**: Monitor for leaks
- **Graphics memory**: Texture and buffer usage
- **Native memory**: Platform-specific allocations

### 3. CPU Usage
- **UI Thread**: Should be below 16ms per frame
- **Raster Thread**: GPU processing time
- **Background threads**: Network and computation

### 4. App Startup Time
- **Cold start**: < 3 seconds
- **Warm start**: < 1.5 seconds
- **Hot restart**: < 1 second

### 5. Battery Impact
- Monitor energy consumption during typical usage
- Identify battery-draining operations

## Using Flutter DevTools for Performance Testing

### Performance View
1. **Frame Timing Chart**: Visualize frame rendering times
2. **CPU Profiler**: Identify expensive methods
3. **Memory View**: Track memory allocations and leaks
4. **Network View**: Monitor API call performance
5. **Logging View**: Debug performance issues

### Key Features to Use
- **Timeline Events**: Record and analyze frame-by-frame performance
- **CPU Profiler**: Sample CPU usage to find bottlenecks
- **Memory Inspector**: Take heap snapshots to find leaks
- **Performance Overlay**: Enable in-app performance indicators

## Performance Testing Scenarios

### 1. Navigation Testing
- Test screen transitions between all major screens
- Measure animation smoothness
- Check for jank or stuttering

### 2. List Scrolling Performance
- Test with large lists (100+ items)
- Monitor frame drops during rapid scrolling
- Check memory usage during scrolling

### 3. Form Input Testing
- Test typing performance in text fields
- Monitor UI responsiveness during input
- Check for lag with complex forms

### 4. Network Operation Testing
- Test performance during API calls
- Monitor UI responsiveness during loading
- Check error handling performance

### 5. Wallet Operations Testing
- Test blockchain transaction performance
- Monitor UI during wallet connection
- Check transaction confirmation times

## Automated Performance Testing

### Integration with CI/CD
Add performance testing to your CI pipeline:

```yaml
# GitHub Actions example
name: Performance Tests
on: [push, pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --profile --coverage
      - run: flutter drive --profile --target=test_driver/app.dart
```

### Performance Test Driver
Create a test driver for automated performance tests:

```dart
// test_driver/performance_test.dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    if (driver != null) {
      await driver.close();
    }
  });

  test('scroll performance test', () async {
    final timeline = await driver.traceAction(() async {
      await driver.scrollUntilVisible(
        find.byValueKey('project-list'),
        find.byValueKey('project-item-50'),
        dyScroll: -300.0,
      );
    });

    final summary = TimelineSummary.summarize(timeline);
    await summary.writeSummaryToFile('scroll_performance', pretty: true);
    await summary.writeTimelineToFile('scroll_performance', pretty: true);
  });
}
```

## Lighthouse Audits (For Web Version)

If you have a web build, use Lighthouse:

```bash
# Build for web
flutter build web

# Serve locally and run Lighthouse
python3 -m http.server 8000
# Then run Lighthouse from Chrome DevTools
```

### Lighthouse Metrics
- **Performance Score**: > 90
- **First Contentful Paint**: < 1.8s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **Total Blocking Time**: < 200ms

## Performance Optimization Techniques

### 1. Widget Optimization
- Use `const` constructors where possible
- Implement `shouldRepaint` for custom painters
- Use `RepaintBoundary` for complex widgets

### 2. List Optimization
- Use `ListView.builder` for lazy loading
- Implement pagination for large datasets
- Use `AutomaticKeepAliveClientMixin` where appropriate

### 3. Image Optimization
- Compress images appropriately
- Use `cached_network_image` for network images
- Implement placeholder and error widgets

### 4. Network Optimization
- Cache API responses
- Use lazy loading for images
- Implement efficient data structures

### 5. Memory Management
- Dispose controllers and listeners
- Use weak references where appropriate
- Monitor for memory leaks with DevTools

## Performance Baseline Establishment

### Create Performance Baselines
Establish baseline metrics for key user flows:

```dart
// Example performance test
test('home screen performance baseline', () async {
  final stopwatch = Stopwatch()..start();
  
  // Perform typical user actions
  await tester.tap(find.byKey(Key('view-projects-button')));
  await tester.pumpAndSettle();
  
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

### Monitor Performance Regressions
Set up alerts for performance regressions:
- Frame time increases > 20%
- Memory usage increases > 50MB
- Startup time increases > 500ms

## Tools and Resources

### Flutter DevTools Features
- **Timeline**: Frame-by-frame performance analysis
- **CPU Profiler**: Method-level CPU usage
- **Memory**: Heap snapshots and allocation tracking
- **Network**: HTTP request timing and volume
- **Logging**: Integrated logging with performance data

### Third-Party Tools
- **Firebase Performance Monitoring**: Real-user monitoring
- **New Relic**: Advanced performance analytics
- **Sentry**: Performance and error tracking
- **Charles Proxy**: Network performance analysis

### Command Line Tools
```bash
# Build analysis
flutter analyze
flutter build apk --analyze-size
flutter build ios --analyze-size

# Performance testing
flutter run --profile --trace-startup
flutter drive --profile --target=test_driver/app.dart
```

## Performance Testing Checklist

### Pre-Release Performance Testing
- [ ] Frame rate maintained at 50-60fps on target devices
- [ ] Memory usage stable during extended use
- [ ] No memory leaks detected
- [ ] Startup time within acceptable limits
- [ ] Battery impact minimal during typical usage
- [ ] Network operations efficient and responsive
- [ ] Accessibility performance acceptable
- [ ] No regression from previous performance baselines

### Device-Specific Testing
- [ ] Test on lowest supported device specifications
- [ ] Test on newest device models
- [ ] Verify performance across different network conditions
- [ ] Test with accessibility features enabled

## Version History
- v1.0: Initial performance testing guide
- Includes Flutter DevTools setup and usage
- Covers key performance metrics and baselines
- Last Updated: [Current Date]