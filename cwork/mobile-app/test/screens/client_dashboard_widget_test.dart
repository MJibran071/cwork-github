import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwork_mobile/screens/client_dashboard.dart';
import 'package:cwork_mobile/screens/project_list_screen.dart';
import 'package:cwork_mobile/screens/messaging_screen.dart';
import 'package:cwork_mobile/screens/escrow_screen.dart';
import 'package:cwork_mobile/screens/profile_screen.dart';
import 'package:cwork_mobile/screens/create_project_screen.dart';

void main() {
  group('ClientDashboard Widget Tests', () {
    testWidgets('Initial dashboard renders with Projects tab active', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClientDashboard(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('CryptoFreelance'), findsOneWidget);

      // Verify notifications icon is present
      expect(find.byIcon(Icons.notifications), findsOneWidget);

      // Verify Projects tab is active (first tab)
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Escrow'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Projects screen is visible initially
      expect(find.byType(ProjectListScreen), findsOneWidget);

      // Verify floating action button is visible on Projects tab
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Navigation between tabs works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClientDashboard(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Verify Messages screen is visible
      expect(find.byType(MessagingScreen), findsOneWidget);
      expect(find.byType(ProjectListScreen), findsNothing);

      // Tap on Escrow tab
      await tester.tap(find.text('Escrow'));
      await tester.pumpAndSettle();

      // Verify Escrow screen is visible
      expect(find.byType(EscrowScreen), findsOneWidget);
      expect(find.byType(MessagingScreen), findsNothing);

      // Tap on Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify Profile screen is visible
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(EscrowScreen), findsNothing);

      // Tap back to Projects tab
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Verify Projects screen is visible again
      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('Floating action button only shows on Projects tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClientDashboard(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on Projects tab - FAB should be visible
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // FAB should not be visible on Messages tab
      expect(find.byType(FloatingActionButton), findsNothing);

      // Navigate to Escrow tab
      await tester.tap(find.text('Escrow'));
      await tester.pumpAndSettle();

      // FAB should not be visible on Escrow tab
      expect(find.byType(FloatingActionButton), findsNothing);

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // FAB should not be visible on Profile tab
      expect(find.byType(FloatingActionButton), findsNothing);

      // Navigate back to Projects tab
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // FAB should be visible again on Projects tab
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Floating action button navigates to CreateProjectScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClientDashboard(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify CreateProjectScreen is pushed
      expect(find.byType(CreateProjectScreen), findsOneWidget);
    });

    testWidgets('Notifications button is present and tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClientDashboard(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify notifications icon is present
      final notificationsButton = find.byIcon(Icons.notifications);
      expect(notificationsButton, findsOneWidget);

      // Tap the notifications button
      await tester.tap(notificationsButton);
      await tester.pump();

      // Button should be tappable (no error thrown)
      expect(notificationsButton, findsOneWidget);
    });

    testWidgets('Bottom navigation bar has correct icons and labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClientDashboard(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all navigation items have correct icons and labels
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.message), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Escrow'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}