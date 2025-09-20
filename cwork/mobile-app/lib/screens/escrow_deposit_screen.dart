import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:web3dart/crypto.dart' as crypto;

class EscrowDepositScreen extends StatefulWidget {
  final String projectId;
  final int milestoneIndex;

  const EscrowDepositScreen({
    super.key,
    required this.projectId,
    required this.milestoneIndex,
  });

  @override
  State<EscrowDepositScreen> createState() => _EscrowDepositScreenState();
}

class _EscrowDepositScreenState extends State<EscrowDepositScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _selectedToken = 'ETH';
  final List<String> _tokens = ['ETH', 'USDC', 'DAI', 'USDT'];
  double _freelancerEarnings = 0.0;
  double _serviceFee = 0.0;
  double _totalDeposit = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateFees);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateFees);
    _amountController.dispose();
    super.dispose();
  }

  void _calculateFees() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _freelancerEarnings = 0.0;
        _serviceFee = 0.0;
        _totalDeposit = 0.0;
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _freelancerEarnings = 0.0;
        _serviceFee = 0.0;
        _totalDeposit = 0.0;
      });
      return;
    }

    setState(() {
      _serviceFee = amount * 0.05; // 5% service fee
      _freelancerEarnings = amount - _serviceFee;
      _totalDeposit = amount;
    });
  }

  Future<void> _depositToEscrow() async {
    if (_isLoading) return;

    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    try {
      // Use API service for deposit since WalletConnect is disabled for web
      await apiService.depositToEscrow(
        widget.projectId,
        amountValue,
        _selectedToken!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funds deposited to escrow successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deposit failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Uint8List _computeEscrowId(String projectId) {
    // Use keccak256 for Ethereum compatibility
    final bytes = utf8.encode(projectId);
    final hash = crypto.keccak256(bytes);
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit to Escrow'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deposit Funds',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Secure your project by depositing funds into escrow. Funds will be released to the freelancer upon project completion.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedToken,
              decoration: const InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
              ),
              items: _tokens
                  .map((token) => DropdownMenuItem(
                        value: token,
                        child: Text(token),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedToken = value),
            ),
            const SizedBox(height: 16),
            if (walletProvider.isConnected)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet Balance:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(walletProvider.balance ?? '0.0 ETH'),
                ],
              ),
            const SizedBox(height: 16),
            
            // Fee breakdown section
            if (_totalDeposit > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Breakdown:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Freelancer receives:'),
                      Text('\$${_freelancerEarnings.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cwork Service Fee (5%):'),
                      Text('\$${_serviceFee.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total to deposit:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${_totalDeposit.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _depositToEscrow,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Deposit to Escrow'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'By depositing funds, you agree to the escrow terms:\n'
              '- Funds are held securely in smart contract\n'
              '- Release requires mutual agreement or dispute resolution\n'
              '- 5% platform fee applies',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}