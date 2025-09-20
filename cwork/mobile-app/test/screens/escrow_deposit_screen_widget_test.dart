import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/services/wallet_service.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/screens/escrow_deposit_screen.dart';

// Mock WalletService
class MockWalletService extends Mock implements WalletService {}

// Mock WalletProvider
class MockWalletProvider extends Mock implements WalletProvider {}

void main() {
  group('EscrowDepositScreen Widget Tests', () {
    late MockWalletService mockWalletService;
    late MockWalletProvider mockWalletProvider;

    setUp(() {
      mockWalletService = MockWalletService();
      mockWalletProvider = MockWalletProvider();
      
      // Setup mock behaviors
      when(mockWalletProvider.isConnected).thenReturn(true);
      when(mockWalletProvider.balance).thenReturn('10.0 ETH');
    });

    testWidgets('should render all UI elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Deposit to Escrow'), findsOneWidget);

      // Verify main title and description
      expect(find.text('Deposit Funds'), findsOneWidget);
      expect(find.textContaining('Secure your project by depositing funds into escrow'), findsOneWidget);

      // Verify form fields
      expect(find.widgetWithText(TextFormField, 'Amount'), findsOneWidget);
      expect(find.widgetWithText(DropdownButtonFormField<String>, 'Token'), findsOneWidget);

      // Verify wallet balance is shown when connected
      expect(find.text('Wallet Balance:'), findsOneWidget);
      expect(find.text('10.0 ETH'), findsOneWidget);

      // Verify deposit button
      expect(find.widgetWithText(ElevatedButton, 'Deposit to Escrow'), findsOneWidget);

      // Verify terms text
      expect(find.textContaining('By depositing funds, you agree to the escrow terms'), findsOneWidget);
    });

    testWidgets('should show fee breakdown when amount is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Initially, fee breakdown should not be visible
      expect(find.text('Fee Breakdown:'), findsNothing);
      expect(find.text('Freelancer receives:'), findsNothing);

      // Enter an amount
      await tester.enterText(find.byType(TextFormField), '100');
      await tester.pump(); // Trigger the listener

      // Now fee breakdown should be visible
      expect(find.text('Fee Breakdown:'), findsOneWidget);
      expect(find.text('Freelancer receives:'), findsOneWidget);
      expect(find.text('\$95.00'), findsOneWidget); // 100 - 5% fee
      expect(find.text('\$5.00'), findsOneWidget); // 5% service fee
      expect(find.text('\$100.00'), findsOneWidget); // total deposit
    });

    testWidgets('should hide fee breakdown when amount is cleared', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Enter an amount
      await tester.enterText(find.byType(TextFormField), '100');
      await tester.pump();
      expect(find.text('Fee Breakdown:'), findsOneWidget);

      // Clear the amount
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      // Fee breakdown should be hidden
      expect(find.text('Fee Breakdown:'), findsNothing);
    });

    testWidgets('should allow token selection from dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Verify initial token is ETH
      expect(find.text('ETH'), findsOneWidget);

      // Tap the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verify all token options are available
      expect(find.text('ETH'), findsWidgets);
      expect(find.text('USDC'), findsOneWidget);
      expect(find.text('DAI'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);

      // Select USDC
      await tester.tap(find.text('USDC').last);
      await tester.pumpAndSettle();

      // Verify token changed to USDC
      expect(find.text('USDC'), findsOneWidget);
    });

    testWidgets('should show loading indicator when depositing', (WidgetTester tester) async {
      // Mock the deposit function to complete successfully
      when(mockWalletService.depositToEscrow(
        escrowId: anyNamed('escrowId'),
        milestoneIndex: anyNamed('milestoneIndex'),
        amount: anyNamed('amount'),
        token: anyNamed('token'),
        txRef: anyNamed('txRef'),
      )).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Enter an amount
      await tester.enterText(find.byType(TextFormField), '100');
      await tester.pump();

      // Tap the deposit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Deposit to Escrow'));
      await tester.pump(); // First pump to start loading

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Deposit to Escrow'), findsNothing); // Button text should be replaced

      // Complete the future
      await tester.pumpAndSettle();

      // Loading should be complete
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Deposit to Escrow'), findsOneWidget);
    });

    testWidgets('should show snackbar for empty amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Tap deposit button without entering amount
      await tester.tap(find.widgetWithText(ElevatedButton, 'Deposit to Escrow'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('should show snackbar for invalid amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Enter invalid amount
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();

      // Tap deposit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Deposit to Escrow'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Please enter a valid amount'), findsOneWidget);
    });

    testWidgets('should not show wallet balance when not connected', (WidgetTester tester) async {
      // Mock wallet as not connected
      when(mockWalletProvider.isConnected).thenReturn(false);
      when(mockWalletProvider.balance).thenReturn(null);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<WalletService>.value(value: mockWalletService),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(
            home: EscrowDepositScreen(
              projectId: 'test-project-123',
              milestoneIndex: 0,
            ),
          ),
        ),
      );

      // Wallet balance should not be shown
      expect(find.text('Wallet Balance:'), findsNothing);
      expect(find.text('10.0 ETH'), findsNothing);
    });
  });
}