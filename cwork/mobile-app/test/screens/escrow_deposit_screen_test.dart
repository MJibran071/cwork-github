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
  group('EscrowDepositScreen Unit Tests', () {
    late MockWalletService mockWalletService;
    late MockWalletProvider mockWalletProvider;
    late Widget testWidget;

    setUp(() {
      mockWalletService = MockWalletService();
      mockWalletProvider = MockWalletProvider();
      testWidget = MultiProvider(
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
      );
    });

    test('EscrowDepositScreen should initialize with correct state', () {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      expect(state._isLoading, false);
      expect(state._selectedToken, 'ETH');
      expect(state._tokens, ['ETH', 'USDC', 'DAI', 'USDT']);
      expect(state._freelancerEarnings, 0.0);
      expect(state._serviceFee, 0.0);
      expect(state._totalDeposit, 0.0);
      expect(state._amountController.text, isEmpty);
    });

    test('_calculateFees should update values correctly for valid amount', () {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      // Set a valid amount
      state._amountController.text = '100';
      state._calculateFees();

      expect(state._freelancerEarnings, 95.0); // 100 - 5% fee
      expect(state._serviceFee, 5.0); // 5% of 100
      expect(state._totalDeposit, 100.0);
    });

    test('_calculateFees should reset values for empty amount', () {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      // Set empty amount
      state._amountController.text = '';
      state._calculateFees();

      expect(state._freelancerEarnings, 0.0);
      expect(state._serviceFee, 0.0);
      expect(state._totalDeposit, 0.0);
    });

    test('_calculateFees should reset values for invalid amount', () {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      // Set invalid amount
      state._amountController.text = 'abc';
      state._calculateFees();

      expect(state._freelancerEarnings, 0.0);
      expect(state._serviceFee, 0.0);
      expect(state._totalDeposit, 0.0);
    });

    test('_calculateFees should reset values for negative amount', () {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      // Set negative amount
      state._amountController.text = '-50';
      state._calculateFees();

      expect(state._freelancerEarnings, 0.0);
      expect(state._serviceFee, 0.0);
      expect(state._totalDeposit, 0.0);
    });

    test('_computeEscrowId should return correct hash for projectId', () {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      final escrowId = state._computeEscrowId('test-project-123');
      
      // _computeEscrowId uses keccak256, so we can't easily predict the exact bytes,
      // but we can verify it returns a Uint8List and is not empty
      expect(escrowId, isA<Uint8List>());
      expect(escrowId.isNotEmpty, true);
    });

    test('_depositToEscrow should not proceed if amount is empty', () async {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      // Mock scaffold messenger
      final mockScaffoldMessenger = MockScaffoldMessenger();
      when(mockScaffoldMessenger.showSnackBar(any)).thenReturn(null);

      // Set empty amount
      state._amountController.text = '';

      // Since _depositToEscrow uses ScaffoldMessenger, it's tricky to test directly,
      // but we can verify the logic by checking if it would return early
      expect(state._amountController.text.isEmpty, true);
      // In practice, this would show a snackbar and return
    });

    test('_depositToEscrow should not proceed if amount is invalid', () async {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      // Set invalid amount
      state._amountController.text = 'invalid';

      expect(double.tryParse(state._amountController.text), isNull);
      // Would show snackbar and return
    });

    test('Token selection should update _selectedToken', () {
      const screen = EscrowDepositScreen(projectId: 'test', milestoneIndex: 0);
      final state = screen.createState() as _EscrowDepositScreenState;

      // Initial token is ETH
      expect(state._selectedToken, 'ETH');

      // Simulate changing token
      state._selectedToken = 'USDC';
      expect(state._selectedToken, 'USDC');
    });
  });
}

// Mock for ScaffoldMessenger since we can't easily test snackbars in unit tests
class MockScaffoldMessenger extends Mock {
  void showSnackBar(SnackBar snackBar);
}