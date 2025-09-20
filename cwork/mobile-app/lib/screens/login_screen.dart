// Login and Registration Screen for CWork Mobile Application
// Handles both traditional email/password authentication and Web3 wallet-based login
// Supports responsive design for mobile, tablet, and desktop devices

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/services/wallet_service.dart';
import 'package:cwork_mobile/theme/app_theme.dart';

/// Stateful widget that provides login and registration functionality
/// Toggles between login and registration modes with form validation
/// Supports both traditional email/password and Web3 wallet authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

/// State class for LoginScreen managing form state, validation, and authentication logic
class LoginScreenState extends State<LoginScreen> {
  // Form controllers for input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // State variables
  bool _isRegistering = false;  // Toggles between login and registration modes
  bool _isLoading = false;      // Indicates when authentication is in progress
  String? _selectedRole;        // User role selection (client/developer)

  // Public getters for testing - allow unit tests to access private state
  bool get isRegistering => _isRegistering;
  bool get isLoading => _isLoading;
  String? get selectedRole => _selectedRole;

  /// Validates email format - must be non-empty and contain '@' symbol
  /// @param email The email address to validate
  /// @return bool True if email is valid, false otherwise
  bool validateEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  /// Validates password - must be non-empty
  /// @param password The password to validate
  /// @return bool True if password is valid, false otherwise
  bool validatePassword(String password) {
    return password.isNotEmpty;
  }

  /// Validates name - required only in registration mode
  /// @param name The name to validate
  /// @return bool True if name is valid for current mode
  bool validateName(String name) {
    return _isRegistering ? name.isNotEmpty : true;
  }

  /// Clean up resources when widget is disposed
  /// Prevents memory leaks by disposing all text controllers
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Handles traditional email/password login authentication
  /// Validates inputs, calls API service, and updates auth state on success
  /// Shows appropriate error messages for validation failures or network errors
  Future<void> _handleEmailLogin() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation - ensure required fields are filled
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true); // Show loading state
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Call API to authenticate user
      final response = await apiService.login(email, password);
      
      // Update application auth state with user data
      authProvider.login(
        userId: response['user']['id'],
        email: response['user']['email'],
        name: response['user']['name'],
        role: response['user']['role'],
        walletAddress: response['user']['walletAddress'],
      );
    } catch (e) {
      // Show error message for failed login attempts
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false); // Reset loading state
    }
  }

  /// Handles user registration with email/password
  /// Validates required fields, calls registration API, and logs user in upon success
  /// Shows validation errors or registration failure messages
  Future<void> _handleRegister() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final role = _selectedRole ?? 'client'; // Default to 'client' role if not selected

    // Validate required fields for registration
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    setState(() => _isLoading = true); // Show loading state
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Call API to register new user
      final response = await apiService.register(email, password, name, phone, role);
      
      // Automatically log user in after successful registration
      authProvider.login(
        userId: response['user']['id'],
        email: response['user']['email'],
        name: response['user']['name'],
        role: response['user']['role'],
        walletAddress: response['user']['walletAddress'],
      );
    } catch (e) {
      // Show error message for failed registration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false); // Reset loading state
    }
  }

  /// Handles Web3 wallet-based authentication using signature verification
  /// Connects wallet, generates nonce, signs message, and authenticates with backend
  /// Provides seamless login experience for crypto-native users
  Future<void> _handleWeb3Login() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    setState(() => _isLoading = true); // Show loading state
    final walletService = Provider.of<WalletService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Step 1: Connect to user's cryptocurrency wallet
      await walletService.connectWallet();
      
      // Step 2: Get nonce and message from backend for signing
      final nonceData = await apiService.generateNonce(walletService.currentAddress!.hex);
      final nonce = nonceData['nonce'];
      final message = nonceData['message'];
      
      // Step 3: Sign the message using the connected wallet
      final signature = await walletService.signMessage(message);
      
      // Step 4: Authenticate with backend using wallet address and signature
      final loginResponse = await apiService.web3Login(
        walletService.currentAddress!.hex,
        signature,
        nonce,
      );
      
      // Step 5: Update application auth state with user data
      authProvider.login(
        userId: loginResponse['user']['id'],
        email: loginResponse['user']['email'],
        name: loginResponse['user']['name'],
        role: loginResponse['user']['role'],
        walletAddress: loginResponse['user']['walletAddress'],
      );
    } catch (e) {
      // Show error message for failed Web3 authentication
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Web3 login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false); // Reset loading state
    }
  }

  /// Builds the main widget tree with responsive layout
  /// Adapts to different screen sizes (mobile, tablet, desktop)
  /// Uses LayoutBuilder to determine optimal layout based on constraints
  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppTheme.isMobile(context);
    final bool isTablet = AppTheme.isTablet(context);
    final bool isDesktop = AppTheme.isDesktop(context);

    // Responsive padding calculations based on device type
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
        title: Text(_isRegistering ? 'Register' : 'Login'), // Dynamic title based on mode
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive layout strategy:
          // - For desktop/tablet: Center the form with max width constraint
          // - For mobile: Use full width with scrolling capability
          if (isDesktop || isTablet) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500), // Optimal form width for larger screens
                child: _buildLoginForm(
                  context,
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
              ),
            );
          }

          // Mobile layout: full width form with scroll support
          return SingleChildScrollView(
            child: _buildLoginForm(
              context,
              horizontalPadding: horizontalPadding,
              verticalPadding: verticalPadding,
            ),
          );
        },
      ),
    );
  }

  /// Builds the login/registration form with appropriate fields based on current mode
  /// Includes accessibility support through Semantics widgets
  /// @param context The build context
  /// @param horizontalPadding Responsive horizontal padding based on device
  /// @param verticalPadding Responsive vertical padding based on device
  /// @return Widget The complete form widget tree
  Widget _buildLoginForm(
    BuildContext context, {
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    final bool isMobile = AppTheme.isMobile(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Registration-specific fields (only shown in register mode)
          if (_isRegistering) ...[
            // Full Name Input Field
            Semantics(
              textField: true,
              label: 'Full name input field',
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Role Selection Dropdown
            Semantics(
              label: 'Role selection dropdown',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  hintText: 'Select your role',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'client',
                    child: Text('Client'),
                  ),
                  DropdownMenuItem(
                    value: 'developer',
                    child: Text('Developer'),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedRole = value),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Phone Number Input (Optional)
            Semantics(
              textField: true,
              label: 'Phone number input field (optional)',
              child: TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  hintText: 'Enter your phone number',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
          
          // Email Input Field (common to both login and register)
          Semantics(
            textField: true,
            label: 'Email address input field',
            child: TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Password Input Field (common to both login and register)
          Semantics(
            textField: true,
            label: 'Password input field',
            child: TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
              obscureText: true,
              textInputAction: _isRegistering ? TextInputAction.next : TextInputAction.done,
              autofillHints: const [AutofillHints.password],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Primary Action Button (Login/Register)
          if (_isLoading)
            const Center(child: CircularProgressIndicator()) // Show loader during authentication
          else
            Semantics(
              button: true,
              label: _isRegistering ? 'Register button' : 'Login button',
              child: ElevatedButton(
                onPressed: _isRegistering ? _handleRegister : _handleEmailLogin,
                child: Text(_isRegistering ? 'Register' : 'Login'),
              ),
            ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Web3 Wallet Login Button
          Semantics(
            button: true,
            label: 'Connect wallet and login button',
            child: OutlinedButton(
              onPressed: _isLoading ? null : _handleWeb3Login,
              child: const Text('Connect Wallet & Login'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Mode Toggle Button (Switch between login and register)
          Semantics(
            button: true,
            label: _isRegistering
                ? 'Switch to login form button'
                : 'Switch to registration form button',
            child: TextButton(
              onPressed: () {
                setState(() => _isRegistering = !_isRegistering);
              },
              child: Text(_isRegistering
                  ? 'Already have an account? Login'
                  : 'Need an account? Register'),
            ),
          ),
        ],
      ),
    );
  }
}