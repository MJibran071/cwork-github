// Profile States - Represents different states of the profile management

import 'package:cwork_mobile/models/user_profile.dart';
import 'package:equatable/equatable.dart';

/// Base class for all profile-related states
abstract class ProfileState extends Equatable {
  final UserProfile? userProfile;

  const ProfileState({this.userProfile});

  @override
  List<Object?> get props => [userProfile];
}

/// Initial state when the profile is first loaded
class ProfileInitial extends ProfileState {
  const ProfileInitial() : super(userProfile: null);
}

/// State when profile data is being loaded
class ProfileLoadInProgress extends ProfileState {
  const ProfileLoadInProgress(UserProfile? previousProfile) 
      : super(userProfile: previousProfile);
}

/// State when profile has been successfully loaded
class ProfileLoadSuccess extends ProfileState {
  const ProfileLoadSuccess(UserProfile userProfile) 
      : super(userProfile: userProfile);
}

/// State when profile loading has failed
class ProfileLoadFailure extends ProfileState {
  final String error;

  const ProfileLoadFailure(UserProfile? previousProfile, this.error) 
      : super(userProfile: previousProfile);

  @override
  List<Object?> get props => [userProfile, error];
}

/// State when availability update is in progress
class ProfileAvailabilityUpdateInProgress extends ProfileState {
  const ProfileAvailabilityUpdateInProgress(UserProfile userProfile) 
      : super(userProfile: userProfile);
}

/// State when availability update is successful
class ProfileAvailabilityUpdateSuccess extends ProfileState {
  const ProfileAvailabilityUpdateSuccess(UserProfile userProfile) 
      : super(userProfile: userProfile);
}

/// State when availability update has failed
class ProfileAvailabilityUpdateFailure extends ProfileState {
  final String error;

  const ProfileAvailabilityUpdateFailure(UserProfile userProfile, this.error) 
      : super(userProfile: userProfile);

  @override
  List<Object?> get props => [userProfile, error];
}

/// State when profile update is in progress
class ProfileUpdateInProgress extends ProfileState {
  const ProfileUpdateInProgress(UserProfile userProfile) 
      : super(userProfile: userProfile);
}

/// State when profile update is successful
class ProfileUpdateSuccess extends ProfileState {
  const ProfileUpdateSuccess(UserProfile userProfile) 
      : super(userProfile: userProfile);
}

/// State when profile update has failed
class ProfileUpdateFailure extends ProfileState {
  final String error;

  const ProfileUpdateFailure(UserProfile userProfile, this.error) 
      : super(userProfile: userProfile);

  @override
  List<Object?> get props => [userProfile, error];
}