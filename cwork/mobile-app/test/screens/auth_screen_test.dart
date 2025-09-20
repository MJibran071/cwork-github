import 'package:flutter_test/flutter_test.dart';
import 'package:cwork_mobile/screens/auth_screen.dart';

// If _AuthScreenState is private, create a public testable subclass for testing:
class TestAuthScreenState extends AuthScreenState {
  TestAuthScreenState() : super();
      final state = TestAuthScreenState();

void main() {
  group('AuthScreen State Management', () {
    test('Initial state has correct default values', () {
      final state = _AuthScreenState();
      expect(state._selectedAuthMethod, 0); // Default to email auth
      expect(state._isLoading, false);
      expect(state._emailController.text, isEmpty);
      expect(state._passwordController.text, isEmpty);
      expect(state._phoneController.text, isEmpty);
    });

    test('Auth method selection changes correctly', () {
      final state = _AuthScreenState();
      
      // Initially email auth (index 0)
      expect(state._selectedAuthMethod, 0);
      
      // Change to phone auth (index 1)
      state.setState(() {
        state._selectedAuthMethod = 1;
      });
      expect(state._selectedAuthMethod, 1);
      
      // Change to wallet auth (index 2)
      state.setState(() {
        state._selectedAuthMethod = 2;
      });
      expect(state._selectedAuthMethod, 2);
      
      // Change back to email auth
      state.setState(() {
        state._selectedAuthMethod = 0;
      });
      expect(state._selectedAuthMethod, 0);
    });

    test('Loading state management works correctly', () {
      final state = _AuthScreenState();
      
      expect(state._isLoading, false);
      
      // Set loading to true
      state.setState(() {
        state._isLoading = true;
      });
      expect(state._isLoading, true);
      
      // Set loading to false
      state.setState(() {
        state._isLoading = false;
      });
      expect(state._isLoading, false);
    });

    test('Text controllers are properly disposed', () {
      final state = _AuthScreenState();
      
      // Verify controllers are initialized
      expect(state._emailController, isNotNull);
      expect(state._passwordController, isNotNull);
      expect(state._phoneController, isNotNull);
      
      // Dispose should not throw errors
      expect(() => state.dispose(), returnsNormally);
    });
  });

  group('AuthScreen Validation Logic', () {
    test('Email validation - empty email returns false', () {
      final state = _AuthScreenState();
      expect(state._validateEmail(''), false);
    });

    test('Email validation - valid email returns true', () {
      final state = _AuthScreenState();
      expect(state._validateEmail('test@example.com'), true);
    });

    test('Email validation - invalid email returns false', () {
      final state = _AuthScreenState();
      expect(state._validateEmail('invalid-email'), false);
    });

    test('Password validation - empty password returns false', () {
      final state = _AuthScreenState();
      expect(state._validatePassword(''), false);
    });

    test('Password validation - valid password returns true', () {
      final state = _AuthScreenState();
      expect(state._validatePassword('password123'), true);
    });

    test('Phone validation - empty phone returns false', () {
      final state = _AuthScreenState();
      expect(state._validatePhone(''), false);
    });

    test('Phone validation - valid phone returns true', () {
      final state = _AuthScreenState();
      expect(state._validatePhone('+1234567890'), true);
    });
  });
}

// Helper methods for testing private state
extension on _AuthScreenState {
  bool validateEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  bool validatePassword(String password) {
    return password.isNotEmpty;
  }

  bool validatePhone(String phone) {
    return phone.isNotEmpty;
  }
}