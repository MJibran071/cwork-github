// Main entry point for CWork Mobile Application
// Sets up environment variables, providers, and root widget

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/services/wallet_service.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/screens/client_dashboard.dart';
import 'package:cwork_mobile/theme/app_theme.dart';

/// Application entry point
/// Initializes environment variables and starts the Flutter app
Future<void> main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Run the main application widget
  runApp(const CWorkApp());
}

/// Root widget of the CWork application
/// Sets up provider architecture and material app configuration
class CWorkApp extends StatelessWidget {
  const CWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provides wallet service for blockchain interactions
        ChangeNotifierProvider(create: (_) => WalletService()),
        
        // Provides API service for backend communication
        ChangeNotifierProvider(create: (_) => ApiService()),
        
        // Provides wallet state management (connection status, address, balance)
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        
        // Provides authentication state management (user session, login status)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Cwork', // Application name
        theme: AppTheme.lightTheme, // Light theme configuration
        darkTheme: AppTheme.darkTheme, // Dark theme configuration
        themeMode: ThemeMode.system, // Follow system theme preference
        home: const ClientDashboard(), // Main dashboard screen
        debugShowCheckedModeBanner: false, // Hide debug banner in release mode
      ),
    );
  }
}