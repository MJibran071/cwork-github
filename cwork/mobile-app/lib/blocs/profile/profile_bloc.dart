// Profile Bloc - Business Logic Component for profile management
// Handles loading, updating, and availability status changes

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cwork_mobile/blocs/profile/profile_event.dart';
import 'package:cwork_mobile/blocs/profile/profile_state.dart';
import 'package:cwork_mobile/repositories/profile_repository.dart';
import 'package:cwork_mobile/models/user_profile.dart';
import 'package:cwork_mobile/models/availability_status.dart';

/// Business Logic Component for managing user profile operations
/// Handles loading profile data, updating availability, and error states
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository}) : super(const ProfileInitial()) {
    on<ProfileLoaded>(_onProfileLoaded);
    on<AvailabilityUpdated>(_onAvailabilityUpdated);
    on<ProfileUpdated>(_onProfileUpdated);
    on<ProfileRefreshed>(_onProfileRefreshed);
    on<ProfileErrorCleared>(_onProfileErrorCleared);
  }

  /// Handles loading the user's profile
  Future<void> _onProfileLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoadInProgress(state.userProfile));
      
      // In a real implementation, this would fetch the full profile
      // For now, we'll create a demo profile with default availability
      final demoProfile = UserProfile(
        id: '1',
        name: 'Demo User',
        email: 'demo@example.com',
        role: 'freelancer',
        walletAddress: '0x1234567890abcdef',
        availability: const Availability(
          status: AvailabilityType.available,
          customMessage: 'Available for new projects!',
          updatedAt: null,
        ),
        activeProjectCount: 2,
      );

      emit(ProfileLoadSuccess(demoProfile));
    } catch (e) {
      emit(ProfileLoadFailure(state.userProfile, 'Failed to load profile: ${e.toString()}'));
    }
  }

  /// Handles updating availability status with optimistic UI updates
  Future<void> _onAvailabilityUpdated(
    AvailabilityUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.userProfile == null) {
      return;
    }

    // Show optimistic update immediately
    final updatedProfile = state.userProfile!.copyWith(
      availability: event.newAvailability,
    );
    emit(ProfileAvailabilityUpdateInProgress(updatedProfile));

    try {
      // Send update to server
      final updatedAvailability = await profileRepository.updateAvailability(event.newAvailability);
      
      // Update the full profile with the confirmed server response
      final confirmedProfile = state.userProfile!.copyWith(
        availability: updatedAvailability,
      );

      emit(ProfileAvailabilityUpdateSuccess(confirmedProfile));
    } catch (e) {
      // Revert to previous state on failure
      emit(ProfileAvailabilityUpdateFailure(
        state.userProfile!,
        'Failed to update availability: ${e.toString()}',
      ));
    }
  }

  /// Handles general profile updates
  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdateInProgress(event.updatedProfile));

    try {
      // In a real implementation, this would update the profile via API
      // For now, we'll simulate a successful update
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(ProfileUpdateSuccess(event.updatedProfile));
    } catch (e) {
      emit(ProfileUpdateFailure(
        state.userProfile!,
        'Failed to update profile: ${e.toString()}',
      ));
    }
  }

  /// Handles refreshing profile data from the server
  Future<void> _onProfileRefreshed(
    ProfileRefreshed event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.userProfile == null) {
      add(const ProfileLoaded());
      return;
    }

    try {
      emit(ProfileLoadInProgress(state.userProfile));
      
      // Simulate fetching fresh data from server
      await Future.delayed(const Duration(milliseconds: 300));
      
      // In a real app, this would fetch the actual updated profile
      final refreshedProfile = state.userProfile!.copyWith(
        availability: state.userProfile!.availability.copyWith(
          updatedAt: DateTime.now(),
        ),
      );

      emit(ProfileLoadSuccess(refreshedProfile));
    } catch (e) {
      emit(ProfileLoadFailure(state.userProfile, 'Failed to refresh profile: ${e.toString()}'));
    }
  }

  /// Handles clearing error states
  void _onProfileErrorCleared(
    ProfileErrorCleared event,
    Emitter<ProfileState> emit,
  ) {
    if (state.userProfile != null) {
      emit(ProfileLoadSuccess(state.userProfile!));
    } else {
      emit(const ProfileInitial());
    }
  }
}