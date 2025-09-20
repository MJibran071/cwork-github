import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Menubar widget for desktop applications that provides quick access
/// to app-specific commands and navigation for the crypto escrow platform
class AppMenubar extends StatelessWidget {
  const AppMenubar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final square = SizedBox.square(
      dimension: 16,
      child: Center(
        child: SizedBox.square(
          dimension: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.foreground,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
    final divider = ShadSeparator.horizontal(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.muted,
    );

    return ShadMenubar(
      items: [
        // Projects Menu
        ShadMenubarItem(
          items: [
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.plus),
              child: Text('New Project'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.folderOpen),
              child: Text('Open Project'),
            ),
            divider,
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.list),
              child: Text('Project List'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.search),
              child: Text('Search Projects'),
            ),
          ],
          child: const Text('Projects'),
        ),

        // Escrow Menu
        ShadMenubarItem(
          items: [
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.wallet),
              child: Text('New Escrow'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.dollarSign),
              child: Text('Deposit Funds'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.arrowUpRight),
              child: Text('Withdraw Funds'),
            ),
            divider,
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.history),
              child: Text('Transaction History'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.fileText),
              child: Text('Escrow Reports'),
            ),
          ],
          child: const Text('Escrow'),
        ),

        // Messages Menu
        ShadMenubarItem(
          items: [
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.messageSquare),
              child: Text('New Message'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.inbox),
              child: Text('Inbox'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.send),
              child: Text('Sent'),
            ),
            divider,
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.bell),
              child: Text('Notifications'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.settings),
              child: Text('Message Settings'),
            ),
          ],
          child: const Text('Messages'),
        ),

        // Profile Menu
        ShadMenubarItem(
          items: [
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.user),
              child: Text('My Profile'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.settings),
              child: Text('Account Settings'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.shield),
              child: Text('Security'),
            ),
            divider,
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.info),
              child: Text('Help & Support'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.logOut),
              child: Text('Logout'),
            ),
          ],
          child: const Text('Profile'),
        ),

        // Tools Menu
        ShadMenubarItem(
          items: [
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.wallet),
              child: Text('Wallet Connect'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.trendingUp),
              child: Text('Analytics'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.fileText),
              child: Text('Reports'),
            ),
            divider,
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.settings),
              child: Text('App Settings'),
            ),
            const ShadContextMenuItem(
              leading: Icon(LucideIcons.refreshCw),
              child: Text('Refresh Data'),
            ),
          ],
          child: const Text('Tools'),
        ),
      ],
    );
  }
}