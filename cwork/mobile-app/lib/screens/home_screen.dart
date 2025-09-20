import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/services/wallet_service.dart';
import 'package:cwork_mobile/theme/app_theme.dart';
import 'package:cwork_mobile/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final walletService = Provider.of<WalletService>(context, listen: false);

    // Initialize wallet connect
    await walletService.initializeWalletConnect();
    
    // Check if user is authenticated
    if (apiService.accessToken != null) {
      try {
        final profile = await apiService.getProfile();
        authProvider.login(
          userId: profile['id'],
          email: profile['email'],
          name: profile['name'],
          role: profile['role'],
          walletAddress: profile['walletAddress'],
        );
      } catch (e) {
        // Token might be invalid, clear it
        await apiService.clearTokens();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    if (authProvider.isLoading || walletProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    final bool isMobile = AppTheme.isMobile(context);
    final bool isTablet = AppTheme.isTablet(context);
    final bool isDesktop = AppTheme.isDesktop(context);

    // Responsive padding based on device
    final double horizontalPadding = isMobile
        ? AppTheme.spacingM
        : isTablet
            ? AppTheme.spacingXL
            : AppTheme.spacingXXL;

    final double verticalPadding = isMobile
        ? AppTheme.spacingM
        : AppTheme.spacingL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CWork - Crypto Escrow'),
        actions: [
          Semantics(
            button: true,
            label: 'Logout button',
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final apiService = Provider.of<ApiService>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final walletService = Provider.of<WalletService>(context, listen: false);
                
                await apiService.logout();
                authProvider.logout();
                await walletService.disconnectWallet();
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive layout: for wider screens, use centered container with max width
          if (isDesktop || isTablet) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildHomeContent(
                  context,
                  authProvider: authProvider,
                  walletProvider: walletProvider,
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
              ),
            );
          }

          // Mobile layout: full width with scrolling
          return SingleChildScrollView(
            child: _buildHomeContent(
              context,
              authProvider: authProvider,
              walletProvider: walletProvider,
              horizontalPadding: horizontalPadding,
              verticalPadding: verticalPadding,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context, {
    required AuthProvider authProvider,
    required WalletProvider walletProvider,
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Welcome, ${authProvider.name}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Semantics(
            textField: true,
            child: Text(
              'Email: ${authProvider.email}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Semantics(
            textField: true,
            child: Text(
              'Role: ${authProvider.role}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (authProvider.walletAddress != null)
            Semantics(
              textField: true,
              child: Text(
                'Wallet: ${authProvider.walletAddress}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          
          const SizedBox(height: AppTheme.spacingL),
          if (walletProvider.isConnected)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Connected Wallet:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Semantics(
                  textField: true,
                  child: Text(
                    'Address: ${walletProvider.address?.hex}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (walletProvider.balance != null)
                  Semantics(
                    textField: true,
                    child: Text(
                      'Balance: ${walletProvider.balance} ETH',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            )
          else
            Semantics(
              button: true,
              label: 'Connect wallet button',
              child: ElevatedButton(
                onPressed: () async {
                  final walletService = Provider.of<WalletService>(context, listen: false);
                  await walletService.connectWallet();
                },
                child: const Text('Connect Wallet'),
              ),
            ),
          
          const SizedBox(height: AppTheme.spacingL),
          Semantics(
            button: true,
            label: 'View projects button',
            child: ElevatedButton(
              onPressed: () {
                // Navigate to projects screen
              },
              child: const Text('View Projects'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Semantics(
            button: true,
            label: 'Create project button',
            child: ElevatedButton(
              onPressed: () {
                // Navigate to create project screen
              },
              child: const Text('Create Project'),
            ),
          ),
        ],
      ),
    );
  }
}