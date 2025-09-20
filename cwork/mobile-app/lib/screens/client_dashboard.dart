// Client Dashboard Screen - Main navigation hub for CWork application
// Provides bottom navigation between Projects, Messages, Escrow, and Profile sections
// Includes floating action button for project creation on Projects tab

import 'package:flutter/material.dart';
import 'package:cwork_mobile/screens/project_list_screen.dart';
import 'package:cwork_mobile/screens/messaging_screen.dart';
import 'package:cwork_mobile/screens/escrow_screen.dart';
import 'package:cwork_mobile/screens/profile_screen.dart';
import 'package:cwork_mobile/screens/create_project_screen.dart';
import 'package:cwork_mobile/widgets/animated_icon_button.dart';
import 'package:cwork_mobile/widgets/animated_floating_action_button.dart';
import 'package:cwork_mobile/theme/app_theme.dart';

/// Main dashboard widget for client users
/// Manages navigation between different application sections
/// Stateful widget to track current tab selection
class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

/// State class for ClientDashboard managing navigation state and screen configuration
class _ClientDashboardState extends State<ClientDashboard> {
  int _currentIndex = 0; // Tracks the currently selected tab index

  /// List of screens corresponding to bottom navigation items
  /// Index 0: Projects screen - displays user's project list
  /// Index 1: Messaging screen - shows conversations (currently with demo data)
  /// Index 2: Escrow screen - manages financial transactions and escrow accounts
  /// Index 3: Profile screen - displays user profile and settings
  final List<Widget> _screens = [
    const ProjectListScreen(),
    const MessagingScreen(
      projectId: 'default-project-id', // Demo project ID for messaging
      recipientName: 'Recipient',     // Demo recipient name
      recipientTitle: 'Developer',     // Demo recipient title
    ),
    const EscrowScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar with application title and notifications button
      appBar: AppBar(
        title: Text(
          'Cwork',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        actions: [
          // Notification button in app bar (currently placeholder)
          AnimatedIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () {},
            tooltip: 'Notifications',
            iconColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      
      // Main content area - displays the currently selected screen
      body: _screens[_currentIndex],
      
      // Floating Action Button - only shown on Projects tab (index 0)
      // Allows users to create new projects
      floatingActionButton: _currentIndex == 0
       ? AnimatedFloatingActionButton(
           onPressed: () {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
             );
           },
           child: const Icon(Icons.add, size: 24),
         )
       : null,
      
      // Bottom Navigation Bar for main app navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index), // Update selected tab
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedLabelStyle: AppTheme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.textTheme.labelSmall,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 24),
              activeIcon: Icon(Icons.dashboard, size: 24),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined, size: 24),
              activeIcon: Icon(Icons.message, size: 24),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
              activeIcon: Icon(Icons.account_balance_wallet, size: 24),
              label: 'Escrow',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined, size: 24),
              activeIcon: Icon(Icons.person, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}