import 'package:flutter/material.dart';
import 'package:cwork_mobile/theme/app_theme.dart';

enum EmptyStateType {
  noProjects,
  noMessages,
  noEscrow,
  noResults,
  error,
  connectionError,
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? description;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.description,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, defaultTitle, defaultDescription, defaultActionText) = _getStateDetails(type);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            title ?? defaultTitle,
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            description ?? defaultDescription,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null) ...[
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXL,
                  vertical: AppTheme.spacingM,
                ),
              ),
              child: Text(actionText ?? defaultActionText),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, String, String, String) _getStateDetails(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.noProjects:
        return (
          Icons.work_outline,
          'No Projects Yet',
          'Start by creating your first project to get started with CryptoFreelance.',
          'Create Project'
        );
      case EmptyStateType.noMessages:
        return (
          Icons.chat_bubble_outline,
          'No Messages',
          'Your messages will appear here once you start conversations with clients or freelancers.',
          'Browse Projects'
        );
      case EmptyStateType.noEscrow:
        return (
          Icons.account_balance_wallet_outlined,
          'No Escrow Transactions',
          'Your escrow transactions will appear here once you start working on projects.',
          'Find Work'
        );
      case EmptyStateType.noResults:
        return (
          Icons.search_off,
          'No Results Found',
          'Try adjusting your search criteria or filters to find what you\'re looking for.',
          'Clear Filters'
        );
      case EmptyStateType.error:
        return (
          Icons.error_outline,
          'Something Went Wrong',
          'We encountered an unexpected error. Please try again later.',
          'Retry'
        );
      case EmptyStateType.connectionError:
        return (
          Icons.wifi_off,
          'No Internet Connection',
          'Please check your internet connection and try again.',
          'Retry'
        );
    }
  }
}

class EmptyStateCard extends StatelessWidget {
  final EmptyStateType type;
  final String? customMessage;

  const EmptyStateCard({
    super.key,
    required this.type,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, description, _) = _getStateDetails(type);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title,
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              customMessage ?? description,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, String, String) _getStateDetails(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.noProjects:
        return (
          Icons.work_outline,
          'No Projects',
          'Create your first project to get started.',
          'Create Project'
        );
      case EmptyStateType.noMessages:
        return (
          Icons.chat_bubble_outline,
          'No Messages',
          'Start a conversation to see messages here.',
          'Browse Projects'
        );
      case EmptyStateType.noEscrow:
        return (
          Icons.account_balance_wallet_outlined,
          'No Escrow',
          'Your escrow transactions will appear here.',
          'Find Work'
        );
      case EmptyStateType.noResults:
        return (
          Icons.search_off,
          'No Results',
          'Try different search terms.',
          'Clear Filters'
        );
      case EmptyStateType.error:
        return (
          Icons.error_outline,
          'Error',
          'Something went wrong.',
          'Retry'
        );
      case EmptyStateType.connectionError:
        return (
          Icons.wifi_off,
          'Offline',
          'Check your internet connection.',
          'Retry'
        );
    }
  }
}