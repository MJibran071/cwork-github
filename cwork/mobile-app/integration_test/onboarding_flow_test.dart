import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/main.dart' as app;
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:web3dart/web3dart.dart';

// Mock providers for integration testing
class MockAuthProvider extends Mock implements AuthProvider {
  Future<bool> register(String name, String email, String password) async {
    return super.noSuchMethod(
      Invocation.method(#register, [name, email, password]),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }

  // Add currentUser getter for testing
  Map<String, dynamic>? get currentUser => super.noSuchMethod(
    Invocation.getter(#currentUser),
    returnValue: null,
    returnValueForMissingStub: null,
  );

  // Add errorMessage getter for testing
  String? get errorMessage => super.noSuchMethod(
    Invocation.getter(#errorMessage),
    returnValue: null,
    returnValueForMissingStub: null,
  );
}
class MockWalletProvider extends Mock implements WalletProvider {
  Future<bool> connectWallet() async {
    return super.noSuchMethod(
      Invocation.method(#connectWallet, []),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow Integration Test', () {
    late MockAuthProvider mockAuthProvider;
    late MockWalletProvider mockWalletProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockWalletProvider = MockWalletProvider();
      
      // Setup mock behaviors
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockWalletProvider.isConnected).thenReturn(false);
      when(mockWalletProvider.isLoading).thenReturn(false);
    });

    testWidgets('should complete onboarding with email registration', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on the auth screen
      expect(find.text('Welcome to CWork'), findsOneWidget);
      expect(find.text('Connect your wallet or sign in with email'), findsOneWidget);

      // Tap on email registration
      await tester.tap(find.text('Sign up with Email'));
      await tester.pumpAndSettle();

      // Verify registration form is shown
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // Name, Email, Password

      // Fill out registration form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123!');

      // Mock successful registration
      when(mockAuthProvider.register('Test User', 'test@example.com', 'Password123!'))
          .thenAnswer((_) async => true);
      when(mockAuthProvider.isAuthenticated).thenReturn(true);

      // Tap register button
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify navigation to home screen after successful registration
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Welcome, Test User'), findsOneWidget);
    });

    testWidgets('should complete onboarding with wallet connection', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on the auth screen
      expect(find.text('Welcome to CWork'), findsOneWidget);

      // Tap on wallet connection
      await tester.tap(find.text('Connect Wallet'));
      await tester.pumpAndSettle();

      // Verify wallet connection dialog or screen
      expect(find.text('Connect Your Wallet'), findsOneWidget);

      // Mock successful wallet connection
      when(mockWalletProvider.connectWallet())
          .thenAnswer((_) async => true);
      when(mockWalletProvider.isConnected).thenReturn(true);
      when(mockWalletProvider.address).thenReturn(EthereumAddress.fromHex('0x1234567890abcdef'));
      when(mockWalletProvider.balance).thenReturn('1.5 ETH');

      // Tap connect button
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Verify wallet is connected and we're on home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('0x1234...cdef'), findsOneWidget); // Truncated address
    });

    testWidgets('should handle login flow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on login option
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // Verify login form is shown
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email, Password

      // Fill out login form
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');

      // Mock successful login
      when(mockAuthProvider.login(
        email: 'test@example.com',
        password: 'Password123!',
        userId: 'test_user_id',
        name: 'Test User',
        role: 'user',
      )).thenAnswer((_) async => true);
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.currentUser).thenReturn({'name': 'Test User', 'email': 'test@example.com'});

      // Tap login button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify navigation to home screen after successful login
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Welcome, Test User'), findsOneWidget);
    });

    testWidgets('should handle onboarding errors gracefully', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on email registration
      await tester.tap(find.text('Sign up with Email'));
      await tester.pumpAndSettle();

      // Try to register with invalid data
      await tester.enterText(find.byType(TextFormField).at(0), ''); // Empty name
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email'); // Invalid email
      await tester.enterText(find.byType(TextFormField).at(2), 'short'); // Short password

      // Tap register button - should show validation errors
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify validation errors are shown
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);

      // Mock registration failure
      when(mockAuthProvider.register('Test User', 'test@example.com', 'Password123!'))
          .thenAnswer((_) async => false);
      when(mockAuthProvider.errorMessage).thenReturn('Email already exists');

      // Fill with valid data but mock failure
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123!');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Email already exists'), findsOneWidget);
    });
  });
}