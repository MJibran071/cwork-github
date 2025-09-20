import 'package:flutter/material.dart';
import 'package:cwork_mobile/theme/app_theme.dart';
import 'package:cwork_mobile/widgets/loading_widget.dart';
import 'package:cwork_mobile/widgets/empty_state_widget.dart';

class EscrowScreen extends StatefulWidget {
  const EscrowScreen({super.key});

  @override
  State<EscrowScreen> createState() => _EscrowScreenState();
}

class _EscrowScreenState extends State<EscrowScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _escrowTransactions = [];

  @override
  void initState() {
    super.initState();
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        // Mock data for demonstration
        _escrowTransactions.addAll([
          {
            'id': '1',
            'projectName': 'Website Redesign',
            'client': 'TechCorp Inc.',
            'amount': 2500.00,
            'currency': 'USD',
            'status': 'active',
            'createdAt': '2024-01-15',
            'deadline': '2024-02-28',
          },
          {
            'id': '2',
            'projectName': 'Mobile App Development',
            'client': 'StartUpXYZ',
            'amount': 5000.00,
            'currency': 'USD',
            'status': 'completed',
            'createdAt': '2024-01-10',
            'completedAt': '2024-01-25',
          },
          {
            'id': '3',
            'projectName': 'Logo Design',
            'client': 'Creative Agency',
            'amount': 800.00,
            'currency': 'USD',
            'status': 'disputed',
            'createdAt': '2024-01-05',
            'disputeReason': 'Quality issues',
          },
        ]);
      });
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.successGreen;
      case 'completed':
        return AppTheme.primaryBlue;
      case 'disputed':
        return AppTheme.errorRed;
      case 'cancelled':
        return AppTheme.gray500;
      default:
        return AppTheme.gray500;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'disputed':
        return 'Disputed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(transaction['status']);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction['projectName'],
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getStatusText(transaction['status']),
                    style: AppTheme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Client: ${transaction['client']}',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${transaction['amount']} ${transaction['currency']}',
                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (transaction['status'] == 'active')
                  ElevatedButton(
                    onPressed: () {
                      // Handle action (e.g., release funds, dispute)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingXS,
                      ),
                      textStyle: AppTheme.textTheme.labelMedium,
                    ),
                    child: const Text('Manage'),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Divider(
              color: theme.colorScheme.surfaceContainerHighest,
              height: 1,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${transaction['createdAt']}',
                  style: AppTheme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (transaction['deadline'] != null)
                  Text(
                    'Deadline: ${transaction['deadline']}',
                    style: AppTheme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escrow Management',
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Manage your secure transactions and funds',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    final totalAmount = _escrowTransactions.fold<double>(
      0, (sum, transaction) => sum + transaction['amount']);
    final activeCount = _escrowTransactions
        .where((t) => t['status'] == 'active')
        .length;
    final completedCount = _escrowTransactions
        .where((t) => t['status'] == 'completed')
        .length;

    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Value',
                  '\$$totalAmount USD',
                  theme.colorScheme.primary,
                ),
                _buildStatItem(
                  'Active',
                  '$activeCount',
                  AppTheme.successGreen,
                ),
                _buildStatItem(
                  'Completed',
                  '$completedCount',
                  AppTheme.primaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: AppTheme.textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading escrow transactions...'),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildStatsCard(),
          Expanded(
            child: _escrowTransactions.isEmpty
                ? EmptyStateWidget(
                    type: EmptyStateType.noEscrow,
                    onAction: () {
                      // Navigate to projects or other action
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingXL),
                    itemCount: _escrowTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(_escrowTransactions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}