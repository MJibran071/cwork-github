// Profile Events - Commands that trigger state changes in the ProfileBloc

import 'package:cwork_mobile/models/availability_status.dart';
import 'package:cwork_mobile/models/user_profile.dart';
import 'package:equatable/equatable.dart';

/// Base class for all profile-related events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the user's profile
class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded();
}

/// Event to update the user's availability status
class AvailabilityUpdated extends ProfileEvent {
  final Availability newAvailability;

  const AvailabilityUpdated(this.newAvailability);

  @override
  List<Object?> get props => [newAvailability];
}

/// Event to update the user's profile information
class ProfileUpdated extends ProfileEvent {
  final UserProfile updatedProfile;

  const ProfileUpdated(this.updatedProfile);

  @override
  List<Object?> get props => [updatedProfile];
}

/// Event to refresh the profile data from the server
class ProfileRefreshed extends ProfileEvent {
  const ProfileRefreshed();
}

/// Event to clear any profile errors
class ProfileErrorCleared extends ProfileEvent {
  const ProfileErrorCleared();
}