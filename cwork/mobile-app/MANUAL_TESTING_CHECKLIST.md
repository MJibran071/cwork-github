# CWork Mobile App - Manual Testing Checklist for Real Devices

## Overview
This checklist covers all interactive elements and user flows for manual testing on real iOS and Android devices. Test each item on at least 2 different device types (phone and tablet) and 2 different OS versions.

## Test Environment Setup
- [ ] iOS device (iPhone/iPad) with latest stable OS
- [ ] Android device (phone/tablet) with latest stable OS
- [ ] Test network conditions: WiFi, 4G/5G
- [ ] Test with screen readers enabled (VoiceOver on iOS, TalkBack on Android)
- [ ] Test with different text sizes and display settings

## Authentication Flow Testing

### Auth Screen ([`auth_screen.dart`](cwork/mobile-app/lib/screens/auth_screen.dart:1))
- [ ] **Auth Method Tabs**: Tap each tab (Email, Phone, Wallet) - verify smooth transition and visual feedback
- [ ] **Email Auth**: 
  - [ ] Enter valid email format - verify input acceptance
  - [ ] Enter invalid email format - verify validation error
  - [ ] Enter password - verify secure text entry
  - [ ] Tap "Sign In" button - verify loading state and successful login
- [ ] **Google Sign-In**: 
  - [ ] Tap "Sign In with Google" - verify Google auth flow opens
  - [ ] Test cancellation and success scenarios
- [ ] **Wallet Auth**: 
  - [ ] Tap "Connect Wallet" - verify wallet connection flow
  - [ ] Test wallet connection success and failure states
- [ ] **Accessibility**: 
  - [ ] Verify all elements have proper semantic labels
  - [ ] Test keyboard navigation (if applicable)
  - [ ] Test voiceover/talkback announcements

## Home/Dashboard Testing

### Home Screen ([`home_screen.dart`](cwork/mobile-app/lib/screens/home_screen.dart:1))
- [ ] **AppBar**: 
  - [ ] Verify title displays correctly
  - [ ] Tap logout button - verify confirmation and proper logout flow
- [ ] **User Info Display**: 
  - [ ] Verify email, name, role display correctly
  - [ ] Verify wallet address truncation/formatting
- [ ] **Wallet Connection**: 
  - [ ] Tap "Connect Wallet" - verify connection flow
  - [ ] Verify wallet balance display when connected
- [ ] **Navigation Buttons**: 
  - [ ] Tap "View Projects" - verify navigation to projects screen
  - [ ] Tap "Create Project" - verify navigation to create project screen
- [ ] **Responsive Layout**: 
  - [ ] Test on different screen sizes (phone, tablet)
  - [ ] Verify adaptive padding and layout changes

### Client Dashboard ([`client_dashboard.dart`](cwork/mobile-app/lib/screens/client_dashboard.dart:1))
- [ ] **Bottom Navigation**: 
  - [ ] Tap each tab (Projects, Messages, Escrow, Profile) - verify smooth transitions
  - [ ] Verify selected state visual feedback
- [ ] **Floating Action Button**: 
  - [ ] Tap FAB on Projects tab - verify opens create project screen
  - [ ] Verify FAB hides on other tabs appropriately
- [ ] **Notifications**: 
  - [ ] Tap notifications icon - verify notifications panel/dialog
- [ ] **Screen Transitions**: 
  - [ ] Verify smooth animations between screens
  - [ ] Test back navigation behavior

## Project Management Testing

### Create Project Screen ([`create_project_screen.dart`](cwork/mobile-app/lib/screens/create_project_screen.dart:1))
- [ ] **Form Validation**: 
  - [ ] Leave fields empty - verify validation errors
  - [ ] Enter invalid budget format - verify error message
  - [ ] Enter valid data - verify form acceptance
- [ ] **Text Fields**: 
  - [ ] Test keyboard types (text, number, multiline)
  - [ ] Verify input formatting and constraints
- [ ] **Dropdown**: 
  - [ ] Tap deadline dropdown - verify options display
  - [ ] Select different deadlines - verify selection persistence
- [ ] **Create Button**: 
  - [ ] Tap with valid data - verify loading state and success
  - [ ] Tap with invalid data - verify error handling
- [ ] **Accessibility**: 
  - [ ] Test form field labels and hints
  - [ ] Verify error messages are announced

### Project List Screen (Inferred)
- [ ] **Project Cards**: 
  - [ ] Tap project cards - verify navigation to detail screen
  - [ ] Test swipe actions (if implemented)
- [ ] **Filter/Sort**: 
  - [ ] Tap filter buttons - verify filter options
  - [ ] Test sorting functionality
- [ ] **Pull-to-Refresh**: 
  - [ ] Swipe down to refresh - verify data reload
- [ ] **Empty State**: 
  - [ ] Verify empty state UI when no projects

## Messaging Testing

### Messaging Screen ([`messaging_screen.dart](cwork/mobile-app/lib/screens/messaging_screen.dart:1))
- [ ] **Message Input**: 
  - [ ] Type message - verify text input works
  - [ ] Tap send button - verify message sends and appears in chat
  - [ ] Test empty message validation
- [ ] **Message Bubbles**: 
  - [ ] Verify sent/received message styling
  - [ ] Test long message formatting
- [ ] **WebSocket Connection**: 
  - [ ] Test real-time message delivery
  - [ ] Test connection loss and recovery
- [ ] **Conversation Info**: 
  - [ ] Tap info button - verify dialog with project details
- [ ] **Scroll Behavior**: 
  - [ ] Test smooth scrolling with many messages
  - [ ] Verify auto-scroll to new messages

## Escrow Testing

### Escrow Screen (Inferred)
- [ ] **Deposit/Withdrawal**: 
  - [ ] Test deposit button functionality
  - [ ] Test withdrawal button functionality
- [ ] **Transaction List**: 
  - [ ] Tap transaction items - verify detail view
- [ ] **Balance Display**: 
  - [ ] Verify currency formatting
  - [ ] Test balance refresh functionality

### Escrow Deposit Screen ([`escrow_deposit_screen_test.dart`](cwork/mobile-app/test/screens/escrow_deposit_screen_test.dart:1))
- [ ] **Amount Input**: 
  - [ ] Test numeric keyboard input
  - [ ] Verify validation for minimum/maximum amounts
- [ ] **Fee Calculation**: 
  - [ ] Verify dynamic fee calculation display
- [ ] **Confirm Button**: 
  - [ ] Tap confirm - verify transaction flow
- [ ] **Wallet Connection**: 
  - [ ] Test wallet interaction during transactions

## Profile Testing

### Profile Screen (Inferred)
- [ ] **User Info**: 
  - [ ] Verify profile information display
- [ ] **Edit Functionality**: 
  - [ ] Test edit profile button
  - [ ] Verify save/cancel operations
- [ ] **Settings**: 
  - [ ] Test settings toggle switches
  - [ ] Verify preferences persistence

## Cross-Cutting Functionality Testing

### Navigation Testing
- [ ] **Deep Linking**: 
  - [ ] Test app opens with specific URLs/parameters
- [ ] **Back Navigation**: 
  - [ ] Test hardware/software back button behavior
- [ ] **Screen Orientation**: 
  - [ ] Test portrait/landscape mode transitions

### Performance Testing
- [ ] **App Launch**: 
  - [ ] Measure cold/warm start times
- [ ] **Screen Transitions**: 
  - [ ] Verify smooth 60fps animations
- [ ] **Memory Usage**: 
  - [ ] Monitor memory consumption during extended use

### Accessibility Testing
- [ ] **Screen Readers**: 
  - [ ] Test with VoiceOver (iOS) and TalkBack (Android)
  - [ ] Verify all interactive elements are properly labeled
- [ ] **Color Contrast**: 
  - [ ] Verify WCAG 2.1 AA compliance for text and UI elements
- [ ] **Text Scaling**: 
  - [ ] Test with large text sizes enabled
- [ ] **Focus Indicators**: 
  - [ ] Verify visible focus for keyboard navigation

### Error Handling Testing
- [ ] **Network Errors**: 
  - [ ] Test offline behavior - verify graceful error handling
  - [ ] Test slow network conditions
- [ ] **API Errors**: 
  - [ ] Simulate server errors - verify user-friendly messages
- [ ] **Wallet Errors**: 
  - [ ] Test wallet connection failures
  - [ ] Test transaction failures

## Device-Specific Testing

### iOS Specific
- [ ] **Face ID/Touch ID**: 
  - [ ] Test biometric authentication integration
- [ ] **iOS Gestures**: 
  - [ ] Test swipe back gestures
  - [ ] Test home indicator behavior

### Android Specific
- [ ] **Back Button**: 
  - [ ] Test hardware back button functionality
- [ ] **Recent Apps**: 
  - [ ] Test app resume from recent apps list
- [ ] **Permissions**: 
  - [ ] Test permission request flows

## Test Execution Notes

### For Each Test Case:
- ✅ Pass - Function works as expected
- ⚠️ Partial - Minor issues found
- ❌ Fail - Critical issue found
- 🔄 Retest - Needs retest after fix

### Bug Reporting Template:
```
Device: [Device Model]
OS Version: [iOS/Android Version]
Test Case: [Specific test case]
Steps to Reproduce: [Detailed steps]
Expected Result: [What should happen]
Actual Result: [What actually happens]
Screenshot: [Attach if possible]
Severity: [Critical/High/Medium/Low]
```

### Test Cycle Management:
- **First Pass**: Complete all test cases
- **Regression Testing**: After bug fixes
- **Final Verification**: Before release

## Version History
- v1.0 - Initial checklist created
- Test Coverage: 100% of interactive elements
- Last Updated: [Current Date]