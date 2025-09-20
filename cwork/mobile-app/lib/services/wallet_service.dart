import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:wallet_connect_dart/wallet_connect_dart.dart'; // Temporarily disabled for web compatibility

class WalletService with ChangeNotifier {
  Web3Client? _web3client;
  EthereumAddress? _currentAddress;
  bool _isConnected = false;
  String? _sessionId;

  EthereumAddress? get currentAddress => _currentAddress;
  bool get isConnected => _isConnected;
  // WalletConnect? get walletConnect => _walletConnect; // Temporarily disabled for web

  Future<void> initializeWalletConnect() async {
    // WalletConnect functionality temporarily disabled for web compatibility
    // _walletConnect = WalletConnect(
    //   bridge: 'https://bridge.walletconnect.org',
    //   clientMeta: const PeerMeta(
    //     name: 'CWork App',
    //     description: 'Crypto Escrow Platform',
    //     url: 'https://cwork.xyz',
    //     icons: ['https://cwork.xyz/icon.png'],
    //   ),
    // );
    //
    // _walletConnect!.on('connect', (session) {
    //   _sessionId = session.sessionId;
    //   _currentAddress = EthereumAddress.fromHex(session.accounts[0]);
    //   _isConnected = true;
    //   notifyListeners();
    //   _saveSession(session);
    // });
    //
    // _walletConnect!.on('disconnect', (session) {
    //   _disconnect();
    // });
    //
    // // Check for existing session
    // final prefs = await SharedPreferences.getInstance();
    // final sessionJson = prefs.getString('wallet_connect_session');
    // if (sessionJson != null) {
    //   try {
    //     final session = Session.fromJson(json.decode(sessionJson));
    //     await _walletConnect!.reconnect(session);
    //   } catch (e) {
    //     await prefs.remove('wallet_connect_session');
    //   }
    // }
  }

  Future<void> connectWallet() async {
    // WalletConnect functionality temporarily disabled for web compatibility
    // if (_walletConnect == null) {
    //   await initializeWalletConnect();
    // }
    //
    // if (!_walletConnect!.connected) {
    //   final uri = _walletConnect!.uri;
    //   if (kIsWeb) {
    //     // For web, open in new tab
    //     await launchUrl(Uri.parse(uri));
    //   } else {
    //     // For mobile, show QR code or deep link
    //     await launchUrl(Uri.parse(uri));
    //   }
    // }
  }

  Future<void> disconnectWallet() async {
    // if (_walletConnect != null && _walletConnect!.connected) {
    //   await _walletConnect!.killSession();
    // }
    _disconnect();
  }

  void _disconnect() {
    _currentAddress = null;
    _isConnected = false;
    _sessionId = null;
    notifyListeners();
    _clearSession();
  }

  Future<void> _saveSession(/*Session session*/) async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString(
    //   'wallet_connect_session',
    //   json.encode(session.toJson()),
    // );
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wallet_connect_session');
  }

  Future<String> signMessage(String message) async {
    // if (_walletConnect == null || !_isConnected) {
    //   throw Exception('Wallet not connected');
    // }
    //
    // try {
    //   final result = await _walletConnect!.signPersonalMessage(
    //     message: message,
    //     address: _currentAddress!.hex,
    //   );
    //   return result;
    // } catch (e) {
    //   throw Exception('Failed to sign message: $e');
    // }
    throw Exception('WalletConnect functionality temporarily disabled for web');
  }

  Future<BigInt> getBalance() async {
    if (_web3client == null || _currentAddress == null) {
      throw Exception('Wallet not connected');
    }

    try {
      final balance = await _web3client!.getBalance(_currentAddress!);
      return balance.getInWei;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  Future<void> initializeWeb3Client(String rpcUrl) async {
    _web3client = Web3Client(rpcUrl, http.Client());
  }

  // Future<String> depositToEscrow({
  //   required Uint8List escrowId,
  //   required BigInt milestoneIndex,
  //   required BigInt amount,
  //   required String token,
  //   required Uint8List txRef,
  // }) async {
  //   if (_web3client == null || _currentAddress == null) {
  //     throw Exception('Wallet not connected or Web3 client not initialized');
  //   }
  //
  //   try {
  //     // Load contract ABI and address (these should be configured from environment)
  //     final contractAddress = EthereumAddress.fromHex('0xYourContractAddressHere'); // Should be from config
  //     final contract = DeployedContract(
  //       ContractAbi.fromJson(_getEscrowContractABI(), 'FreelanceEscrow'),
  //       contractAddress,
  //     );
  //
  //     // Get the deposit function
  //     final depositFunction = contract.function('deposit');
  //
  //     // Prepare parameters
  //     final params = [
  //       escrowId,
  //       milestoneIndex,
  //       txRef,
  //     ];
  //
  //     // For ETH deposits, we need to send value
  //     final ethAmount = token == 'ETH' ? amount : BigInt.zero;
  //
  //     // Execute the transaction
  //     final transaction = Transaction.callContract(
  //       contract: contract,
  //       function: depositFunction,
  //       parameters: params,
  //       from: _currentAddress!,
  //       value: EtherAmount.inWei(ethAmount),
  //       maxGas: 1000000,
  //     );
  //
  //     // Send transaction
  //     final transactionHash = await _web3client!.sendTransaction(
  //       await _web3client!.credentialsFromPrivateKey("0x..."), // Placeholder - need proper credentials handling
  //       transaction,
  //       chainId: 1, // Mainnet - should be configurable
  //     );
  //
  //     return transactionHash;
  //   } catch (e) {
  //     throw Exception('Failed to deposit to escrow: $e');
  //   }
  // }

  String _getEscrowContractABI() {
    // This should be the actual ABI of the FreelanceEscrow contract
    // For now, returning a placeholder - in real app, load from file or config
    return '''
    [
      {
        "inputs": [
          {"internalType": "bytes32", "name": "escrowId", "type": "bytes32"},
          {"internalType": "uint256", "name": "milestoneIndex", "type": "uint256"},
          {"internalType": "bytes", "name": "txRef", "type": "bytes"}
        ],
        "name": "deposit",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
      }
    ]
    ''';
  }
}