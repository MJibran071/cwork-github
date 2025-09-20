# CWork Mobile App - Smoke Test Checklist

## Overview
This smoke test checklist ensures critical functionality works before every release. Execute this checklist before deploying to production environments.

## Pre-Release Smoke Testing

### Build Verification
- [ ] App builds successfully without errors
- [ ] All dependencies resolve correctly
- [ ] No deprecated APIs or packages in use
- [ ] Code analysis passes (flutter analyze)
- [ ] Test suite passes (flutter test)

### Installation Testing
- [ ] App installs successfully on target devices
- [ ] App launches without crashes
- [ ] App permissions requested appropriately
- [ ] App appears in device app list correctly

## Critical Functionality Testing

### Authentication Flow
- [ ] Email login works with valid credentials
- [ ] Email login shows appropriate error for invalid credentials
- [ ] Google Sign-In initiates properly
- [ ] Wallet connection flow works
- [ ] Logout functionality works correctly

### Navigation Testing
- [ ] Bottom navigation works between all tabs
- [ ] Screen transitions are smooth
- [ ] Back navigation works correctly
- [ ] Deep linking works (if supported)

### Core Features Testing

#### Project Management
- [ ] Create new project form works
- [ ] Project validation shows appropriate errors
- [ ] Project list displays correctly
- [ ] Project detail view works

#### Messaging
- [ ] Message sending works
- [ ] Message receiving works
- [ ] Message history loads
- [ ] WebSocket connection establishes

#### Escrow Functionality
- [ ] Escrow deposit screen loads
- [ ] Balance displays correctly
- [ ] Transaction initiation works
- [ ] Transaction history displays

### Performance Smoke Tests
- [ ] App cold start < 3 seconds
- [ ] Screen transitions < 500ms
- [ ] No noticeable jank or stuttering
- [ ] Memory usage stable during basic usage

## Device-Specific Smoke Testing

### iOS Devices
- [ ] iPhone (latest model) - All critical functionality
- [ ] iPad (latest model) - Adaptive layout testing
- [ ] Legacy device (oldest supported) - Basic functionality

### Android Devices
- [ ] Google Pixel (latest) - All critical functionality
- [ ] Samsung Galaxy (latest) - Manufacturer-specific testing
- [ ] Budget device (oldest supported) - Basic functionality

## Network Condition Testing
- [ ] WiFi connection - All functionality works
- [ ] 4G/5G connection - All functionality works
- [ ] Offline mode - Appropriate error handling
- [ ] Network recovery - Reconnection works

## Accessibility Smoke Testing
- [ ] VoiceOver/TalkBack - All interactive elements accessible
- [ ] Large text mode - UI adapts correctly
- [ ] High contrast mode - UI remains usable
- [ ] Reduced motion - Animations respect setting

## Localization Testing
- [ ] Default language (English) - All text displays correctly
- [ ] RTL language (if supported) - Layout adapts correctly
- [ ] Special characters - Handle correctly in all inputs

## Security Smoke Testing
- [ ] Sensitive data not logged
- [ ] HTTPS connections enforced
- [ ] Authentication tokens handled securely
- [ ] No exposed API keys in client code

## Error Handling Verification
- [ ] Network errors handled gracefully
- [ ] API failures show user-friendly messages
- [ ] Invalid user input handled appropriately
- [ ] Crash reporting working (if implemented)

## Post-Release Verification
- [ ] App Store/Play Store listing correct
- [ ] Update mechanism works
- [ ] Version number incremented correctly
- [ ] Release notes accurate and complete

## Smoke Test Execution Template

### Test Execution Record
```
Date: [Date]
Tester: [Name]
App Version: [Version]
Build Number: [Build]

Device: [Device Model]
OS Version: [OS Version]
Network: [Network Type]

Results:
- [ ] Build Verification: PASS/FAIL
- [ ] Installation: PASS/FAIL
- [ ] Authentication: PASS/FAIL
- [ ] Navigation: PASS/FAIL
- [ ] Core Features: PASS/FAIL
- [ ] Performance: PASS/FAIL
- [ ] Accessibility: PASS/FAIL
- [ ] Error Handling: PASS/FAIL

Issues Found:
- [Issue 1]
- [Issue 2]

Status: ✅ READY FOR RELEASE / ❌ BLOCKED
```

### Quick Smoke Test (5-minute version)
For urgent releases, run this abbreviated checklist:

- [ ] App builds successfully
- [ ] App installs and launches
- [ ] Login works
- [ ] Main navigation works
- [ ] Critical feature (create project) works
- [ ] No crashes during basic usage

## Automation Support

### Automated Smoke Tests
Consider automating these smoke tests:

```dart
// Example smoke test
test('smoke test - authentication and basic navigation', () async {
  // Test login
  await tester.enterText(find.byKey(Key('email-field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password-field')), 'password123');
  await tester.tap(find.byKey(Key('login-button')));
  await tester.pumpAndSettle();
  
  // Verify logged in state
  expect(find.text('Welcome,'), findsOneWidget);
  
  // Test navigation
  await tester.tap(find.byKey(Key('projects-tab')));
  await tester.pumpAndSettle();
  expect(find.byKey(Key('project-list')), findsOneWidget);
});
```

### CI/CD Integration
Add smoke tests to your deployment pipeline:

```yaml
name: Smoke Tests
on: [deployment]

jobs:
  smoke-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/smoke_test.dart
```

## Version History
- v1.0: Initial smoke test checklist
- Covers all critical functionality paths
- Designed for pre-release validation
- Last Updated: [Current Date]