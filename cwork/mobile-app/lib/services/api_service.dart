// API Service - Centralized HTTP client for backend communication
// Handles authentication, token management, and all API requests
// Uses ChangeNotifier for state management and token updates

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cwork_mobile/models/availability_status.dart';

/// Custom exception for API errors with specific error codes
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;

  ApiException(this.message, this.statusCode, {this.errorCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode${errorCode != null ? ', Code: $errorCode' : ''})';
}

/// Central API service for handling all HTTP requests to backend services
/// Manages authentication tokens, request routing, and error handling
/// Supports multiple backend services with automatic URL routing
class ApiService with ChangeNotifier {
  // Default base URLs for different backend services
  static const String _authBaseUrl = 'http://localhost:3000'; // Default auth service
  static const String _marketplaceBaseUrl = 'http://localhost:3001'; // Default marketplace service
  
  // Private token storage
  String? _accessToken;   // JWT access token for authenticated requests
  String? _refreshToken; // Refresh token for obtaining new access tokens

  // Public getters for token access
  String? get accessToken => _accessToken;   // Current access token
  String? get refreshToken => _refreshToken; // Current refresh token

  /// Constructor - automatically loads saved tokens from storage
  ApiService() {
    _loadTokens(); // Load tokens when service is initialized
  }

  /// Loads authentication tokens from persistent storage
  /// Called during initialization to restore session
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');   // Load access token
    _refreshToken = prefs.getString('refresh_token'); // Load refresh token
    notifyListeners(); // Notify listeners of token state change
  }

  /// Saves authentication tokens to persistent storage
  /// Updates internal state and notifies listeners
  /// @param accessToken The JWT access token to save
  /// @param refreshToken The refresh token to save
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);   // Save access token
    await prefs.setString('refresh_token', refreshToken); // Save refresh token
    _accessToken = accessToken;   // Update internal state
    _refreshToken = refreshToken; // Update internal state
    notifyListeners(); // Notify listeners of token state change
  }

  /// Clears all authentication tokens from storage and memory
  /// Used during logout or when tokens are invalid
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');   // Remove access token
    await prefs.remove('refresh_token'); // Remove refresh token
    _accessToken = null;   // Clear from memory
    _refreshToken = null; // Clear from memory
    notifyListeners(); // Notify listeners of token state change
  }

  /// Internal method to make HTTP requests with proper routing and headers
  /// Automatically routes requests to appropriate backend service
  /// @param method HTTP method (GET, POST, PUT, DELETE)
  /// @param path API endpoint path
  /// @param body Optional request body
  /// @return HTTP response
  Future<http.Response> _request(String method, String path, {Object? body}) async {
    // Determine which base URL to use based on the path
    final String baseUrl;
    if (path.startsWith('/auth') || path.startsWith('/users') || path.startsWith('/web3')) {
      baseUrl = dotenv.get('AUTH_API_BASE_URL') ?? _authBaseUrl; // Use auth service
    } else {
      baseUrl = dotenv.get('MARKETPLACE_API_BASE_URL') ?? _marketplaceBaseUrl; // Use marketplace service
    }
    
    final url = Uri.parse('$baseUrl$path'); // Construct full URL
    final headers = {
      'Content-Type': 'application/json', // JSON content type
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken', // Add auth header if token exists
    };

    // Execute appropriate HTTP method
    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: body != null ? json.encode(body) : null);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: body != null ? json.encode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method');
      }
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}', 0);
    }

    // Check for error responses and throw specific exceptions
    if (response.statusCode >= 400) {
      try {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Request failed with status ${response.statusCode}';
        final errorCode = errorData['error'];
        throw ApiException(errorMessage, response.statusCode, errorCode: errorCode);
      } catch (_) {
        // If response body is not JSON, use generic error
        throw ApiException('Request failed with status ${response.statusCode}', response.statusCode);
      }
    }

    return response;
  }

  /// Authenticates user with email and password credentials
  /// @param email User's email address
  /// @param password User's password
  /// @return User data and tokens
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _request('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });

    final data = json.decode(response.body);
    await _saveTokens(data['accessToken'], data['refreshToken']); // Save received tokens
    return data; // Return user data
  }

  /// Registers a new user account
  /// @param email User's email address
  /// @param password User's password
  /// @param name User's full name
  /// @param phone Optional phone number
  /// @param role User role (e.g., 'client', 'freelancer')
  /// @return User data and tokens
  Future<Map<String, dynamic>> register(String email, String password, String name, String? phone, String role) async {
    final response = await _request('POST', '/auth/register', body: {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'role': role,
    });

    final data = json.decode(response.body);
    await _saveTokens(data['accessToken'], data['refreshToken']); // Save received tokens
    return data; // Return user data
  }

  /// Authenticates user using Web3 wallet signature
  /// @param address Ethereum wallet address
  /// @param signature Signed message from wallet
  /// @param nonce Server-generated nonce for verification
  /// @return User data and tokens
  Future<Map<String, dynamic>> web3Login(String address, String signature, String nonce) async {
    final response = await _request('POST', '/auth/web3/login', body: {
      'address': address,
      'signature': signature,
      'nonce': nonce,
    });

    final data = json.decode(response.body);
    await _saveTokens(data['accessToken'], data['refreshToken']); // Save received tokens
    return data; // Return user data
  }

  /// Authenticates user using Google OAuth ID token
  /// @param idToken Google OAuth ID token
  /// @return User data and tokens
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await _request('POST', '/auth/google/login', body: {
      'idToken': idToken,
    });

    final data = json.decode(response.body);
    await _saveTokens(data['accessToken'], data['refreshToken']); // Save received tokens
    return data; // Return user data
  }

  /// Fetches current user's profile information
  /// @return User profile data
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _request('GET', '/users/profile');
    return json.decode(response.body); // Return profile data
  }

  /// Logs out the current user and clears local tokens
  /// Calls server logout endpoint and clears local storage
  Future<void> logout() async {
    await _request('POST', '/auth/logout'); // Notify server of logout
    await clearTokens(); // Clear local tokens
  }

  /// Refreshes authentication tokens using refresh token
  /// @return New access and refresh tokens
  Future<Map<String, dynamic>> refreshAuthToken() async {
    final response = await _request('POST', '/auth/refresh', body: {
      'refreshToken': _refreshToken, // Use current refresh token
    });

    final data = json.decode(response.body);
    await _saveTokens(data['accessToken'], data['refreshToken']); // Save new tokens
    return data; // Return token data
  }

  // ========== PROJECT-RELATED METHODS ========== //

  /// Fetches list of projects for the current user
  /// @return List of project objects
  Future<List<dynamic>> getProjects() async {
    final response = await _request('GET', '/projects');
    return json.decode(response.body); // Return project list
  }

  /// Fetches details of a specific project
  /// @param projectId ID of the project to fetch
  /// @return Project details object
  Future<Map<String, dynamic>> getProject(String projectId) async {
    final response = await _request('GET', '/projects/$projectId');
    return json.decode(response.body); // Return project details
  }

  /// Creates a new project
  /// @param projectData Project creation data
  /// @return Created project object
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData) async {
    final response = await _request('POST', '/projects', body: projectData);
    return json.decode(response.body); // Return created project
  }

  /// Updates an existing project
  /// @param projectId ID of the project to update
  /// @param updates Map of fields to update
  /// @return Updated project object
  Future<Map<String, dynamic>> updateProject(String projectId, Map<String, dynamic> updates) async {
    final response = await _request('PUT', '/projects/$projectId', body: updates);
    return json.decode(response.body); // Return updated project
  }

  /// Deletes a project
  /// @param projectId ID of the project to delete
  Future<void> deleteProject(String projectId) async {
    final response = await _request('DELETE', '/projects/$projectId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete project: ${response.statusCode}'); // Throw on failure
    }
  }

  // ========== ESCROW-RELATED METHODS ========== //

  /// Deposits funds into project escrow
  /// @param projectId ID of the project
  /// @param amount Amount to deposit
  /// @param token Token symbol (e.g., 'ETH', 'USDC')
  /// @return Escrow deposit confirmation
  Future<Map<String, dynamic>> depositToEscrow(String projectId, double amount, String token) async {
    final response = await _request('POST', '/escrow/deposit', body: {
      'projectId': projectId,
      'amount': amount,
      'token': token,
    });
    return json.decode(response.body); // Return deposit confirmation
  }

  /// Releases escrow funds to the freelancer
  /// @param projectId ID of the project
  /// @return Escrow release confirmation
  Future<Map<String, dynamic>> releaseEscrow(String projectId) async {
    final response = await _request('POST', '/escrow/release', body: {
      'projectId': projectId,
    });
    return json.decode(response.body); // Return release confirmation
  }

  /// Refunds escrow funds back to the client
  /// @param projectId ID of the project
  /// @return Escrow refund confirmation
  Future<Map<String, dynamic>> refundEscrow(String projectId) async {
    final response = await _request('POST', '/escrow/refund', body: {
      'projectId': projectId,
    });
    return json.decode(response.body); // Return refund confirmation
  }

  /// Gets current escrow balance for a project
  /// @param projectId ID of the project
  /// @return Escrow balance information
  Future<Map<String, dynamic>> getEscrowBalance(String projectId) async {
    final response = await _request('GET', '/escrow/balance/$projectId');
    return json.decode(response.body); // Return balance information
  }

  // ========== MESSAGING-RELATED METHODS ========== //

  /// Fetches messages for a specific project
  /// @param projectId ID of the project
  /// @return List of message objects
  Future<List<dynamic>> getMessages(String projectId) async {
    final response = await _request('GET', '/messages/$projectId');
    return json.decode(response.body); // Return message list
  }

  /// Sends a message in a project conversation
  /// @param projectId ID of the project
  /// @param content Message content
  /// @return Sent message object
  Future<Map<String, dynamic>> sendMessage(String projectId, String content) async {
    final response = await _request('POST', '/messages', body: {
      'projectId': projectId,
      'content': content,
    });
    return json.decode(response.body); // Return sent message
  }

  /// Fetches proposals for a specific project
  /// @param projectId ID of the project
  /// @return List of proposal objects
  Future<List<dynamic>> getProposals(String projectId) async {
    final response = await _request('GET', '/projects/$projectId/proposals');
    return json.decode(response.body); // Return proposal list
  }

  /// Fetches milestones for a specific project
  /// @param projectId ID of the project
  /// @return List of milestone objects
  Future<List<dynamic>> getMilestones(String projectId) async {
    final response = await _request('GET', '/projects/$projectId/milestones');
    return json.decode(response.body); // Return milestone list
  }

  // ========== USER-RELATED METHODS ========== //

  /// Updates current user's profile information
  /// @param profileData Map of profile fields to update
  /// @return Updated profile object
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _request('PUT', '/users/profile', body: profileData);
    return json.decode(response.body); // Return updated profile
  }

  /// Fetches list of users (for admin or search functionality)
  /// @return List of user objects
  Future<List<dynamic>> getUsers() async {
    final response = await _request('GET', '/users');
    return json.decode(response.body); // Return user list
  }
  // ========== REVIEW-RELATED METHODS ========== //

  /// Fetches reviews for a specific user (reviews about the user)
  /// @param userId ID of the user to fetch reviews for
  /// @return List of review objects
  Future<List<dynamic>> getUserReviews(String userId) async {
    final response = await _request('GET', '/reviews/reviewed/$userId');
    return json.decode(response.body); // Return review list
  }

  /// Fetches review statistics for a specific user
  /// @param userId ID of the user to fetch review stats for
  /// @return Review statistics object
  Future<Map<String, dynamic>> getReviewStats(String userId) async {
    final response = await _request('GET', '/reviews/stats/$userId');
    return json.decode(response.body); // Return review stats
  }

  // ========== WEB3-SPECIFIC METHODS ========== //

  /// Generates a nonce for Web3 authentication
  /// @param address Ethereum wallet address
  /// @return Nonce generation response
  Future<Map<String, dynamic>> generateNonce(String address) async {
    final response = await _request('POST', '/web3/generate-nonce', body: {
      'address': address,
    });
    return json.decode(response.body); // Return nonce data
  }

  // ========== AVAILABILITY-RELATED METHODS ========== //

  /// Fetches the current user's availability status
  /// @return Availability object with status and custom message
  Future<Map<String, dynamic>> getAvailability() async {
    final response = await _request('GET', '/users/availability');
    return json.decode(response.body); // Return availability data
  }

  /// Updates the current user's availability status
  /// @param status The new availability status
  /// @param customMessage Optional custom message for the status
  /// @return Updated availability object
  Future<Map<String, dynamic>> updateAvailability(AvailabilityType status, {String? customMessage}) async {
    final response = await _request('PUT', '/users/availability', body: {
      'status': status.name,
      if (customMessage != null) 'customMessage': customMessage,
    });
    return json.decode(response.body); // Return updated availability
  }

  /// Updates only the custom message for availability
  /// @param customMessage The new custom message
  /// @return Updated availability object
  Future<Map<String, dynamic>> updateAvailabilityMessage(String customMessage) async {
    final response = await _request('PUT', '/users/availability/message', body: {
      'customMessage': customMessage,
    });
    return json.decode(response.body); // Return updated availability
  }

  /// Gets availability status for a specific user
  /// @param userId ID of the user to fetch availability for
  /// @return Availability object
  Future<Map<String, dynamic>> getUserAvailability(String userId) async {
    final response = await _request('GET', '/users/$userId/availability');
    return json.decode(response.body); // Return user availability
  }
}