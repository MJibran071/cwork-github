import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/services/wallet_service.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/screens/client_dashboard.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _selectedAuthMethod = 0; // 0: Email, 1: Phone, 2: Wallet
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill demo credentials for testing
    _emailController.text = 'test@example.com';
    _passwordController.text = 'password123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await apiService.login(email, password);
      authProvider.login(
        userId: response['user']['id'],
        email: response['user']['email'],
        name: response['user']['name'],
        role: response['user']['role'],
        walletAddress: response['user']['walletAddress'],
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ClientDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        
        if (idToken != null) {
          final response = await apiService.googleLogin(idToken);
          authProvider.login(
            userId: response['user']['id'],
            email: response['user']['email'],
            name: response['user']['name'],
            role: response['user']['role'],
            walletAddress: response['user']['walletAddress'],
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClientDashboard()),
          );
        } else {
          throw Exception('Google sign-in failed: No ID token received');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectWallet() async {
    setState(() => _isLoading = true);
    final walletService = Provider.of<WalletService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await walletService.connectWallet();
      if (walletService.isConnected && walletService.currentAddress != null) {
        // Get nonce from backend for web3 login
        final nonceData = await apiService.generateNonce(walletService.currentAddress!.hex);
        final nonce = nonceData['nonce'];
        final message = nonceData['message'];
        
        // Sign the message
        final signature = await walletService.signMessage(message);
        
        // Login with signature
        final loginResponse = await apiService.web3Login(
          walletService.currentAddress!.hex,
          signature,
          nonce,
        );
        
        authProvider.login(
          userId: loginResponse['user']['id'],
          email: loginResponse['user']['email'],
          name: loginResponse['user']['name'],
          role: loginResponse['user']['role'],
          walletAddress: loginResponse['user']['walletAddress'],
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ClientDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wallet connection failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Text(
              'Welcome to\nCryptoFreelance',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hire freelancers or find work with secure crypto escrow payments',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            // Auth method selector
            Row(
              children: [
                _buildAuthMethodTab(0, 'Email'),
                _buildAuthMethodTab(1, 'Phone'),
                _buildAuthMethodTab(2, 'Wallet'),
              ],
            ),
            const SizedBox(height: 20),
            // Auth form based on selection
            Expanded(
              child: IndexedStack(
                index: _selectedAuthMethod,
                children: [
                  _buildEmailAuth(),
                  _buildPhoneAuth(),
                  _buildWalletAuth(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthMethodTab(int index, String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAuthMethod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _selectedAuthMethod == index 
                  ? Colors.blue 
                  : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: _selectedAuthMethod == index 
                ? FontWeight.bold 
                : FontWeight.normal,
              color: _selectedAuthMethod == index 
                ? Colors.blue 
                : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailAuth() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Sign In'),
          ),
        ),
        const SizedBox(height: 20),
        const Text('OR'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: const Icon(Icons.g_mobiledata, color: Colors.red),
            label: _isLoading ? const CircularProgressIndicator() : const Text('Sign In with Google'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () {},
            icon: const Icon(Icons.facebook, color: Colors.blue),
            label: const Text('Sign In with Facebook'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () {},
            icon: const Icon(Icons.abc, color: Colors.lightBlue),
            label: const Text('Sign In with Twitter'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () {},
            icon: const Icon(Icons.code, color: Colors.black),
            label: const Text('Sign In with GitHub'),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneAuth() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletAuth() {
    return Column(
      children: [
        const Text('Connect your crypto wallet to continue'),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _connectWallet,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Connect Wallet'),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          children: [
            _buildWalletOption('MetaMask', Icons.account_balance_wallet),
            _buildWalletOption('Binance', Icons.account_balance),
            _buildWalletOption('WalletConnect', Icons.link),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletOption(String name, IconData icon) {
    return Chip(
      avatar: Icon(icon),
      label: Text(name),
    );
  }
}