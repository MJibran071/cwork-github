import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/screens/home_screen.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/services/wallet_service.dart';

// Mock services and providers for widget testing
class MockApiService extends ApiService {
  MockApiService() : super();

  @override
  String? get accessToken => 'mock-token';

  @override
  Future<Map<String, dynamic>> getProfile() async {
    return {
      'id': '1',
      'email': 'test@example.com',
      'name': 'Test User',
      'role': 'client',
      'walletAddress': '0x1234567890abcdef',
    };
  }

  @override
  Future<void> logout() async {
    // Mock logout
  }

  @override
  Future<void> clearTokens() async {
    // Mock clear tokens
  }
}

class MockWalletService extends WalletService {
  MockWalletService() : super();

  @override
  Future<void> initializeWalletConnect() async {
    // Mock initialization
  }

  @override
  Future<void> connectWallet() async {
    // Mock connection
  }

  @override
  Future<void> disconnectWallet() async {
    // Mock disconnect
  }
}

class MockAuthProvider extends AuthProvider {
  MockAuthProvider({bool isAuthenticated = false, bool isLoading = false}) {
    this._isAuthenticated = isAuthenticated;
    this._isLoading = isLoading;
    if (isAuthenticated) {
      this._userId = '1';
      this._email = 'test@example.com';
      this._name = 'Test User';
      this._role = 'client';
      this._walletAddress = '0x1234567890abcdef';
    }
  }

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  bool get isLoading => _isLoading;

  @override
  String get email => _email;

  @override
  String get name => _name;

  @override
  String get role => _role;

  @override
  String? get walletAddress => _walletAddress;
}

class MockWalletProvider extends WalletProvider {
  MockWalletProvider({bool isConnected = false, bool isLoading = false}) {
    this._isConnected = isConnected;
    this._isLoading = isLoading;
    if (isConnected) {
      this._address = '0x1234567890abcdef';
      this._balance = '1.5';
    }
  }

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get address => _address;

  @override
  String? get balance => _balance;
}

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('Shows loading state when providers are loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isLoading: true)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider(isLoading: true)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Redirects to login screen when not authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isAuthenticated: false)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Shows home content when authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isAuthenticated: true)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show home content
      expect(find.text('Welcome, Test User!'), findsOneWidget);
      expect(find.text('Email: test@example.com'), findsOneWidget);
      expect(find.text('Role: client'), findsOneWidget);
      expect(find.text('Wallet: 0x1234567890abcdef'), findsOneWidget);
      expect(find.text('Connect Wallet'), findsOneWidget);
      expect(find.text('View Projects'), findsOneWidget);
      expect(find.text('Create Project'), findsOneWidget);
    });

    testWidgets('Shows wallet info when wallet is connected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isAuthenticated: true)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider(isConnected: true)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show connected wallet info
      expect(find.text('Connected Wallet:'), findsOneWidget);
      expect(find.text('Address: 0x1234567890abcdef'), findsOneWidget);
      expect(find.text('Balance: 1.5 ETH'), findsOneWidget);
      expect(find.text('Connect Wallet'), findsNothing);
    });

    testWidgets('Logout button is present and tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isAuthenticated: true)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show logout button
      final logoutButton = find.byIcon(Icons.logout);
      expect(logoutButton, findsOneWidget);

      // Tap the logout button
      await tester.tap(logoutButton);
      await tester.pump();

      // Button should be tappable (no error thrown)
      expect(logoutButton, findsOneWidget);
    });

    testWidgets('Connect wallet button is present and tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isAuthenticated: true)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show connect wallet button
      final connectButton = find.text('Connect Wallet');
      expect(connectButton, findsOneWidget);

      // Tap the connect wallet button
      await tester.tap(connectButton);
      await tester.pump();

      // Button should be tappable (no error thrown)
      expect(connectButton, findsOneWidget);
    });

    testWidgets('View projects button is present and tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isAuthenticated: true)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show view projects button
      final viewProjectsButton = find.text('View Projects');
      expect(viewProjectsButton, findsOneWidget);

      // Tap the view projects button
      await tester.tap(viewProjectsButton);
      await tester.pump();

      // Button should be tappable (no error thrown)
      expect(viewProjectsButton, findsOneWidget);
    });

    testWidgets('Create project button is present and tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: MockApiService()),
            Provider<WalletService>.value(value: MockWalletService()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider(isAuthenticated: true)),
            ChangeNotifierProvider<WalletProvider>(create: (_) => MockWalletProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show create project button
      final createProjectButton = find.text('Create Project');
      expect(createProjectButton, findsOneWidget);

      // Tap the create project button
      await tester.tap(createProjectButton);
      await tester.pump();

      // Button should be tappable (no error thrown)
      expect(createProjectButton, findsOneWidget);
    });
  });
}