import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../data/models/listing_model.dart';
import '../models/user_model.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  ProfileStatus _status = ProfileStatus.initial;
  UserModel? _profile;
  UserModel? _viewedProfile;
  List<ListingModel> _userListings = [];
  bool _isLoadingPosts = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  ProfileStatus get status => _status;
  UserModel? get profile => _profile;
  UserModel? get viewedProfile => _viewedProfile;
  List<ListingModel> get userListings => _userListings;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  bool get isLoadingPosts => _isLoadingPosts;

  /// Returns the profile for [userId], using own or viewed profile as appropriate.
  UserModel? profileFor(String? userId, String? currentUserId) {
    if (userId == null || userId == currentUserId) return _profile;
    return _viewedProfile;
  }

  // ── Fetch own profile ─────────────────────────────────────────────────────
  Future<void> fetchProfile(String userId) async {
    _setLoading();
    try {
      final data = await SupabaseService.table('profiles')
          .select()
          .eq('id', userId)
          .single();
      _profile = UserModel.fromJson(data);
      _status = ProfileStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Fetch another user's profile ──────────────────────────────────────────
  Future<void> fetchOtherProfile(String userId) async {
    _setLoading();
    try {
      final data = await SupabaseService.table('profiles')
          .select()
          .eq('id', userId)
          .single();
      _viewedProfile = UserModel.fromJson(data);
      _status = ProfileStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Fetch user listings for profile grid ─────────────────────────────────
  Future<void> fetchUserListings(String userId) async {
    _isLoadingPosts = true;
    notifyListeners();
    try {
      final data = await SupabaseService.table('listings')
          .select('*, profiles!inner(full_name, avatar_url), categories!left(name, icon), listing_images!left(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _userListings = (data as List).map((e) => ListingModel.fromJson(e)).toList();
    } catch (e) {
      _userListings = [];
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  // ── Load full profile view (profile + posts) ────────────────────────────────
  Future<void> loadProfileView({
    required String targetUserId,
    required bool isOwnProfile,
  }) async {
    if (isOwnProfile) {
      await fetchProfile(targetUserId);
    } else {
      await fetchOtherProfile(targetUserId);
    }
    await fetchUserListings(targetUserId);
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<bool> updateProfile(UserModel updatedUser) async {
    _setLoading();
    try {
      await SupabaseService.table('profiles').update({
        'full_name': updatedUser.fullName,
        'avatar_url': updatedUser.avatarUrl,
        'bio': updatedUser.bio,
        'location': updatedUser.location,
      }).eq('id', updatedUser.id);
      _profile = updatedUser;
      _status = ProfileStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Upload avatar to Supabase Storage ─────────────────────────────────────
  Future<String?> uploadAvatar({
    required String userId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final path = '$userId/$fileName';
      await SupabaseService.storage.from('avatars').uploadBinary(
            path,
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return SupabaseService.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading() {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ProfileStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearViewedProfile() {
    _viewedProfile = null;
  }

  void reset() {
    _profile = null;
    _viewedProfile = null;
    _userListings = [];
    _status = ProfileStatus.initial;
    _errorMessage = null;
    _isLoadingPosts = false;
    notifyListeners();
  }
}
