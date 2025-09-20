// Wallet Provider - Manages blockchain wallet connection state
// Uses ChangeNotifier for state management and UI updates
// Handles wallet address, connection status, balance, and loading states

import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

/// Manages wallet connection state and blockchain-related information
/// Notifies listeners when wallet state changes (connection, balance, etc.)
class WalletProvider with ChangeNotifier {
  // Private state variables
  EthereumAddress? _address;     // Connected wallet address
  bool _isConnected = false;      // Whether wallet is connected
  String? _balance;               // Current wallet balance
  bool _isLoading = false;        // Loading state for wallet operations

  // Public getters for state access
  EthereumAddress? get address => _address;       // Current wallet address if connected
  bool get isConnected => _isConnected;           // Current connection status
  String? get balance => _balance;                // Current wallet balance
  bool get isLoading => _isLoading;               // Current loading state

  /// Sets the wallet address and updates connection status
  /// Automatically sets isConnected based on whether address is provided
  /// @param address The Ethereum address to set (null for disconnect)
  void setAddress(EthereumAddress? address) {
    _address = address;                          // Set wallet address
    _isConnected = address != null;             // Update connection status
    notifyListeners();                          // Notify widgets to rebuild
  }

  /// Sets the wallet balance and notifies listeners
  /// @param balance The balance string to display (e.g., "1.5 ETH")
  void setBalance(String balance) {
    _balance = balance;        // Set wallet balance
    notifyListeners();         // Notify widgets to rebuild
  }

  /// Sets the loading state for wallet operations
  /// @param loading Boolean indicating if operation is in progress
  void setLoading(bool loading) {
    _isLoading = loading;     // Set loading state
    notifyListeners();        // Notify widgets to rebuild
  }

  /// Disconnects the wallet and clears all wallet-related state
  /// Resets address, connection status, and balance to default values
  void disconnect() {
    _address = null;         // Clear wallet address
    _isConnected = false;    // Set disconnected status
    _balance = null;         // Clear balance
    notifyListeners();       // Notify all listeners of state change
  }
}