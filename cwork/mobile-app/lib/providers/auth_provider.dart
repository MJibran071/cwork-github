// Authentication Provider - Manages user authentication state
// Uses ChangeNotifier for state management and UI updates
// Handles login, logout, and profile updates

import 'package:flutter/foundation.dart';

/// Manages authentication state and user profile information
/// Notifies listeners when authentication state changes
class AuthProvider with ChangeNotifier {
  // Private state variables
  bool _isAuthenticated = false;    // Whether user is logged in
  String? _userId;                   // Unique user identifier
  String? _email;                   // User's email address
  String? _name;                    // User's display name
  String? _role;                    // User role (e.g., 'client', 'freelancer')
  String? _walletAddress;           // Connected wallet address
  bool _isLoading = false;           // Loading state for auth operations

  // Public getters for state access
  bool get isAuthenticated => _isAuthenticated;  // Current authentication status
  String? get userId => _userId;                 // User ID if authenticated
  String? get email => _email;                   // User's email if available
  String? get name => _name;                     // User's name if available
  String? get role => _role;                     // User's role if available
  String? get walletAddress => _walletAddress;   // Connected wallet address
  bool get isLoading => _isLoading;               // Current loading state

  /// Sets the loading state and notifies listeners
  /// @param loading Boolean indicating if operation is in progress
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // Notify widgets to rebuild
  }

  /// Logs in a user with provided credentials and profile information
  /// Updates all user state fields and sets authenticated status
  /// @param userId Unique identifier for the user
  /// @param email User's email address
  /// @param name User's display name
  /// @param role User's role in the system
  /// @param walletAddress Optional connected wallet address
  void login({
    required String userId,
    required String email,
    required String name,
    required String role,
    String? walletAddress,
  }) {
    _isAuthenticated = true;        // Set authenticated status
    _userId = userId;              // Store user ID
    _email = email;                // Store email
    _name = name;                  // Store name
    _role = role;                  // Store role
    _walletAddress = walletAddress; // Store wallet address
    notifyListeners();             // Notify all listeners of state change
  }

  /// Logs out the current user and clears all user data
  /// Resets all state fields to null and sets authenticated to false
  void logout() {
    _isAuthenticated = false;  // Reset authentication status
    _userId = null;            // Clear user ID
    _email = null;             // Clear email
    _name = null;              // Clear name
    _role = null;              // Clear role
    _walletAddress = null;     // Clear wallet address
    notifyListeners();         // Notify all listeners of state change
  }

  /// Updates user profile information with provided values
  /// Only updates fields that are provided (non-null)
  /// @param name Optional new display name
  /// @param walletAddress Optional new wallet address
  void updateProfile({
    String? name,
    String? walletAddress,
  }) {
    if (name != null) _name = name;  // Update name if provided
    if (walletAddress != null) _walletAddress = walletAddress; // Update wallet address if provided
    notifyListeners(); // Notify all listeners of state change
  }
}