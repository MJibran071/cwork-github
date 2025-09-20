// User Profile Model
// Contains user information including availability status

import 'package:cwork_mobile/models/availability_status.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String? walletAddress;
  final Availability availability;
  final int activeProjectCount; // For automated status calculation

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.walletAddress,
    required this.availability,
    this.activeProjectCount = 0,
  });

  // Create from JSON for API response parsing
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'client',
      walletAddress: json['walletAddress'],
      availability: json['availability'] != null
          ? Availability.fromJson(json['availability'])
          : Availability.initial,
      activeProjectCount: json['activeProjectCount'] ?? 0,
    );
  }

  // Convert to JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'walletAddress': walletAddress,
      'availability': availability.toJson(),
      'activeProjectCount': activeProjectCount,
    };
  }

  // Helper method to copy with new values
  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? walletAddress,
    Availability? availability,
    int? activeProjectCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      walletAddress: walletAddress ?? this.walletAddress,
      availability: availability ?? this.availability,
      activeProjectCount: activeProjectCount ?? this.activeProjectCount,
    );
  }

  // Check if user is a freelancer (typically needs availability status)
  bool get isFreelancer => role == 'freelancer';
}