import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/screens/login_screen.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/services/wallet_service.dart';
import 'package:cwork_mobile/theme/app_theme.dart';

// Mock services and providers for widget testing
class MockApiService extends ApiService {
  MockApiService() : super();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    return {
      'user': {
        'id': '1',
        'email': email,
        'name': 'Test User',
        'role': 'client',
        'walletAddress': '0x1234567890abcdef',
      }
    };
  }

  @override
  Future<Map<String, dynamic>> register(
      String email, String password, String name, String? phone, String role) async {
    return {
      'user': {
        'id': '1',
        'email': email,
        'name': name,
        'role': role,
        'walletAddress': '0x1234567890abcdef',
      }
    };
  }
}

class MockWalletService extends WalletService {
  MockWalletService() : super();

  @override
  Future<void> connectWallet() async {
    // Mock connection
  }

  @override
  Future<String> signMessage(String message) async {
    return 'mock-signature';
  }
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Initial login screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial login UI elements
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Connect Wallet & Login'), findsOneWidget);
      expect(find.text('Need an account? Register'), findsOneWidget);
      expect(find.text('Full Name'), findsNothing); // Should not be visible in login mode
      expect(find.text('Role'), findsNothing); // Should not be visible in login mode
    });

    testWidgets('Toggling to register mode shows additional fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the register button
      await tester.tap(find.text('Need an account? Register'));
      await tester.pumpAndSettle();

      // Verify register UI elements are visible
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Phone (Optional)'), findsOneWidget);
      expect(find.text('Already have an account? Login'), findsOneWidget);
    });

    testWidgets('Email and password fields accept input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text in email field
      await tester.enterText(find.byKey(const Key('email-field')), 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);

      // Enter text in password field
      await tester.enterText(find.byKey(const Key('password-field')), 'password123');
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Login button is enabled with valid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially button should be enabled
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, true);

      // Enter invalid email
      await tester.enterText(find.byKey(const Key('email-field')), 'invalid-email');
      await tester.enterText(find.byKey(const Key('password-field')), 'password123');
      await tester.pump();

      // Button should still be enabled (validation happens on submit)
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, true);
    });

    testWidgets('Role dropdown selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to register mode
      await tester.tap(find.text('Need an account? Register'));
      await tester.pumpAndSettle();

      // Tap the role dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select 'Developer' role
      await tester.tap(find.text('Developer').last);
      await tester.pumpAndSettle();

      // Verify role is selected
      expect(find.text('Developer'), findsWidgets);
    });

    testWidgets('Wallet connect button is available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify wallet connect button exists
      expect(find.text('Connect Wallet & Login'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled, true);
    });
  });
}