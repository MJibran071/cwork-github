import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';
import 'package:cwork_mobile/screens/home_screen.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/theme/app_theme.dart';

// Mock providers for testing
class MockAuthProvider extends AuthProvider {
  MockAuthProvider() : super();

  @override
  bool get isAuthenticated => true;

  @override
  bool get isLoading => false;

  @override
  String get name => 'John Doe';

  @override
  String get email => 'john.doe@example.com';

  @override
  String get role => 'client';

  @override
  String? get walletAddress => '0x1234567890abcdef';
}

class MockWalletProvider extends WalletProvider {
  MockWalletProvider() : super();

  @override
  bool get isConnected => true;

  @override
  bool get isLoading => false;

  @override
  EthereumAddress? get address => EthereumAddress.fromHex('0x1234567890abcdef');

  @override
  String? get balance => '1.5';
}

class MockUnauthAuthProvider extends AuthProvider {
  MockUnauthAuthProvider() : super();

  @override
  bool get isAuthenticated => false;

  @override
  bool get isLoading => false;
}

void main() {
  testWidgets('HomeScreen golden test - authenticated user', (WidgetTester tester) async {
    // Build our app with mock providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthProvider>.value(value: MockAuthProvider()),
          Provider<WalletProvider>.value(value: MockWalletProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    // Wait for the initial frame to render completely
    await tester.pumpAndSettle();

    // Verify that the user information is displayed
    expect(find.text('Welcome, John Doe!'), findsOneWidget);
    expect(find.text('Email: john.doe@example.com'), findsOneWidget);
    expect(find.text('Role: client'), findsOneWidget);
    expect(find.text('Wallet: 0x1234567890abcdef'), findsOneWidget);
    expect(find.text('Connected Wallet:'), findsOneWidget);
    expect(find.text('Balance: 1.5 ETH'), findsOneWidget);

    // Take a golden screenshot of the home screen
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen_authenticated.png'),
    );
  });

  testWidgets('HomeScreen golden test - unauthenticated user', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthProvider>.value(value: MockUnauthAuthProvider()),
          Provider<WalletProvider>.value(value: MockWalletProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should show login screen instead
    expect(find.byType(HomeScreen), findsNothing);
    // Note: This test might not capture the login screen golden since it's a different widget
    // For golden tests of unauthenticated state, we might need to test LoginScreen separately
  });

  testWidgets('HomeScreen dark mode golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthProvider>.value(value: MockAuthProvider()),
          Provider<WalletProvider>.value(value: MockWalletProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen_dark_mode.png'),
    );
  });

  testWidgets('HomeScreen responsive golden tests', (WidgetTester tester) async {
    // Test different screen sizes
    final testVariants = {
      'mobile': const Size(360, 640),    // Typical mobile size
      'tablet': const Size(768, 1024),   // Typical tablet size
      'desktop': const Size(1200, 800),  // Typical desktop size
    };

    for (final variant in testVariants.entries) {
      tester.binding.window.physicalSizeTestValue = variant.value;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: MockAuthProvider()),
            Provider<WalletProvider>.value(value: MockWalletProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen_${variant.key}.png'),
      );
    }

    // Reset the window to default after tests
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  });
}