// lib/services/profile_service.dart
//
// Reads and writes user_profiles.
// Also used by InviteService to look up a user by phone number.

import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.preferredSports = const [],
    this.phone,
  });

  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final List<String> preferredSports;
  final String? phone;
}

class ProfileService {
  ProfileService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns the profile for the current user, or null if not found.
  Future<UserProfile?> getMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return getProfile(userId);
  }

  /// Returns any user's public profile by ID.
  Future<UserProfile?> getProfile(String userId) async {
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return row == null ? null : _rowToProfile(row);
  }

  /// Looks up a user by phone number (E.164 format).
  /// Used by InviteService to check if an invitee already has an account.
  Future<UserProfile?> findByPhone(String phone) async {
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('phone', phone)
        .maybeSingle();

    return row == null ? null : _rowToProfile(row);
  }

  /// Updates mutable fields on the current user's profile.
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    List<String>? preferredSports,
    String? phone,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // ignore: prefer_null_aware_elements — 'key'?: syntax not supported in this SDK
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (username != null)        'username':         username,
      if (fullName != null)        'full_name':        fullName,
      if (bio != null)             'bio':              bio,
      if (avatarUrl != null)       'avatar_url':       avatarUrl,
      if (preferredSports != null) 'preferred_sports': preferredSports,
      if (phone != null)           'phone':            phone,
    };

    await _client
        .from('user_profiles')
        .update(updates)
        .eq('id', userId);
  }

  // ── Converter ─────────────────────────────────────────────────

  UserProfile _rowToProfile(Map<String, dynamic> row) => UserProfile(
        id:              row['id'] as String,
        username:        (row['username'] as String?) ?? '',
        fullName:        (row['full_name'] as String?) ?? '',
        avatarUrl:       row['avatar_url'] as String?,
        bio:             row['bio'] as String?,
        preferredSports: List<String>.from((row['preferred_sports'] as List?) ?? []),
        phone:           row['phone'] as String?,
      );
}
