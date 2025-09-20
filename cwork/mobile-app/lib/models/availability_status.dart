// Availability Status Model
// Defines freelancer availability types and data structure

import 'package:flutter/material.dart';

/// The core status options for freelancer availability
enum AvailabilityType {
  available,    // Green - actively looking for work
  busy,         // Orange - working but might be open to new projects
  away,         // Yellow - temporarily unavailable (e.g., vacation)
  doNotDisturb, // Red - not accepting any new work
}

/// Extension methods for AvailabilityType to provide UI properties
extension AvailabilityTypeExtension on AvailabilityType {
  String get displayName {
    switch (this) {
      case AvailabilityType.available:
        return 'Available';
      case AvailabilityType.busy:
        return 'Busy';
      case AvailabilityType.away:
        return 'Away';
      case AvailabilityType.doNotDisturb:
        return 'Do Not Disturb';
    }
  }

  Color get color {
    switch (this) {
      case AvailabilityType.available:
        return Colors.green;
      case AvailabilityType.busy:
        return Colors.orange;
      case AvailabilityType.away:
        return Colors.yellow[700]!;
      case AvailabilityType.doNotDisturb:
        return Colors.red;
    }
  }
}

/// The complete availability data model
class Availability {
  final AvailabilityType status;
  final String customMessage; // e.g., "Available for quick turnarounds!", "Back on Jan 15th"
  final DateTime? updatedAt;

  const Availability({
    required this.status,
    this.customMessage = '',
    this.updatedAt,
  });

  // A default/initial state
  static Availability get initial => const Availability(
        status: AvailabilityType.available,
        customMessage: '',
      );

  // Helper method to copy with new values
  Availability copyWith({
    AvailabilityType? status,
    String? customMessage,
    DateTime? updatedAt,
  }) {
    return Availability(
      status: status ?? this.status,
      customMessage: customMessage ?? this.customMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'customMessage': customMessage,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON for API response parsing
  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      status: AvailabilityType.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AvailabilityType.available,
      ),
      customMessage: json['customMessage'] ?? '',
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}