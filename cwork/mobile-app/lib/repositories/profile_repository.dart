// Profile Repository - Handles profile-related data operations
// Separates data layer from business logic

import 'package:cwork_mobile/models/availability_status.dart';
import 'package:cwork_mobile/services/api_service.dart';

/// Custom exception for repository failures
class RepositoryException implements Exception {
  final String message;
  final int? statusCode;

  RepositoryException(this.message, {this.statusCode});

  @override
  String toString() => 'RepositoryException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Repository for handling profile-related operations
/// Abstracts API calls and provides clean interface for BLoC layer
class ProfileRepository {
  final ApiService apiService;

  ProfileRepository({required this.apiService});

  /// Fetches the user's current availability status
  /// @return Availability object with status and custom message
  /// @throws RepositoryException if API call fails
  Future<Availability> getAvailability() async {
    try {
      final response = await apiService.getAvailability();
      return Availability.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to load availability status');
    }
  }

  /// Updates the user's availability status
  /// @param newAvailability The new availability settings
  /// @return Updated Availability object
  /// @throws RepositoryException if API call fails
  Future<Availability> updateAvailability(Availability newAvailability) async {
    try {
      final response = await apiService.updateAvailability(
        newAvailability.status,
        customMessage: newAvailability.customMessage,
      );
      return Availability.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to update availability status');
    }
  }

  /// Updates only the custom message for availability
  /// @param customMessage The new custom message
  /// @return Updated Availability object
  /// @throws RepositoryException if API call fails
  Future<Availability> updateAvailabilityMessage(String customMessage) async {
    try {
      final response = await apiService.updateAvailabilityMessage(customMessage);
      return Availability.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to update availability message');
    }
  }
}