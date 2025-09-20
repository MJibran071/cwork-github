import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwork_mobile/screens/login_screen.dart';
import 'package:cwork_mobile/theme/app_theme.dart';

void main() {
  testWidgets('LoginScreen golden test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );

    // Wait for the initial frame to render completely
    await tester.pumpAndSettle();

    // Verify that the initial state is correct (login mode)
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsNothing);

    // Take a golden screenshot of the login screen
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen_initial.png'),
    );

    // Test the register mode
    await tester.tap(find.text('Need an account? Register'));
    await tester.pumpAndSettle();

    // Verify register mode is active
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login'), findsNothing);

    // Take a golden screenshot of the register screen
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen_register.png'),
    );
  });

  testWidgets('LoginScreen dark mode golden test', (WidgetTester tester) async {
    // Build our app with dark theme and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Take a golden screenshot of the login screen in dark mode
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen_dark_mode.png'),
    );
  });

  testWidgets('LoginScreen responsive golden tests', (WidgetTester tester) async {
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
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_${variant.key}.png'),
      );
    }

    // Reset the window to default after tests
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  });
}