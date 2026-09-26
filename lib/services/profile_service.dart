import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile_model.dart';

class ProfileService extends ChangeNotifier {
  ProfileModel? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load profile from Supabase or initialize default for device user ID
  Future<void> fetchProfile({
    required String userId,
    String defaultName = 'My Profile',
    String? defaultAvatarUrl,
    String email = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        dynamic data;
        try {
          data = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
        } catch (_) {
          try {
            data = await Supabase.instance.client
                .from('profiles')
                .select()
                .eq('user_id', userId)
                .maybeSingle();
          } catch (_) {}
        }

        if (data != null) {
          final fetched = ProfileModel.fromMap(data);
          final validName = (fetched.name.isNotEmpty && fetched.name != 'User' && fetched.name != 'My Profile')
              ? fetched.name
              : defaultName;
          final validAvatar = (fetched.avatarUrl != null && fetched.avatarUrl!.isNotEmpty)
              ? fetched.avatarUrl
              : defaultAvatarUrl;

          _currentProfile = fetched.copyWith(
            name: validName,
            avatarUrl: validAvatar,
          );
        } else {
          final now = DateTime.now();
          final newProfile = ProfileModel(
            id: userId,
            userId: userId,
            name: defaultName,
            email: email,
            avatarUrl: defaultAvatarUrl,
            createdAt: now,
            updatedAt: now,
          );

          try {
            await Supabase.instance.client.from('profiles').upsert(
              newProfile.toMap(),
            );
          } catch (_) {}
          _currentProfile = newProfile;
        }
      } else {
        _currentProfile ??= ProfileModel(
          id: 'prof-local',
          userId: userId,
          name: defaultName,
          email: email,
          avatarUrl: defaultAvatarUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload selected gallery image file to Supabase Storage bucket 'profile-images'
  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '$userId/$fileName';

      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client.storage
            .from('profile-images')
            .uploadBinary(storagePath, bytes, fileOptions: const FileOptions(upsert: true));

        final publicUrl = Supabase.instance.client.storage
            .from('profile-images')
            .getPublicUrl(storagePath);

        _isLoading = false;
        notifyListeners();
        return publicUrl;
      } else {
        final base64String = base64Encode(bytes);
        final dataUri = 'data:image/jpeg;base64,$base64String';

        _isLoading = false;
        notifyListeners();
        return dataUri;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      try {
        final bytes = await imageFile.readAsBytes();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (_) {
        return null;
      }
    }
  }

  /// Update Profile Information (Name and optional Avatar URL)
  Future<bool> updateProfile({
    required String name,
    String? avatarUrl,
  }) async {
    if (_currentProfile == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = _currentProfile!.copyWith(
        name: name,
        avatarUrl: avatarUrl ?? _currentProfile!.avatarUrl,
        updatedAt: DateTime.now(),
      );

      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client
            .from('profiles')
            .upsert(updated.toMap(), onConflict: 'user_id');
      }

      _currentProfile = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
