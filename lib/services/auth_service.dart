import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final bool isGuest;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.isGuest = false,
  });
}

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _checkInitialUser();
    _listenToAuthChanges();
  }

  /// Sign In as Guest User
  void signInAsGuest() {
    _currentUser = AppUser(
      id: 'guest-user-local-id',
      email: 'guest@cashorg.app',
      name: 'Guest User',
      avatarUrl: null,
      isGuest: true,
    );
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _checkInitialUser() {
    if (SupabaseConfig.isConfigured && Supabase.instance.client.auth.currentSession != null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _updateUserFromSupabase(user);
      }
    } else {
      _currentUser = null;
    }
  }

  void _listenToAuthChanges() {
    if (!SupabaseConfig.isConfigured) return;

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;
      if (user != null) {
        _updateUserFromSupabase(user);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  void _updateUserFromSupabase(User user) {
    final meta = user.userMetadata ?? {};
    final rawName = meta['full_name'] ??
        meta['name'] ??
        meta['preferred_username'] ??
        meta['custom_name'] ??
        user.userMetadata?['name'] ??
        user.userMetadata?['full_name'];
    final rawAvatar = meta['avatar_url'] ?? meta['picture'] ?? meta['avatar'];

    String nameStr = rawName?.toString().trim() ?? '';
    if ((nameStr.isEmpty || nameStr == 'User') && user.email != null && user.email!.contains('@')) {
      final part = user.email!.split('@').first;
      if (part.isNotEmpty) {
        nameStr = part[0].toUpperCase() + part.substring(1);
      }
    }
    if (nameStr.isEmpty) {
      nameStr = 'User';
    }

    _currentUser = AppUser(
      id: user.id,
      email: user.email ?? '',
      name: nameStr,
      avatarUrl: rawAvatar?.toString(),
    );
  }

  /// Trigger Google OAuth Sign In via Supabase Auth
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        final success = await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.origin : 'expensetracker://login-callback',
        );

        if (!success) {
          throw Exception('Google Sign-In was cancelled or failed.');
        }

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          _updateUserFromSupabase(user);
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').replaceAll('AuthException:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Email & Password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email.trim(),
          password: password.trim(),
        );

        final user = response.user;
        if (user != null) {
          _updateUserFromSupabase(user);
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('AuthException:', '').replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Sign Up / Register with Email & Password
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email.trim(),
          password: password.trim(),
          data: {'full_name': name.trim()},
        );

        final user = response.user;
        if (user != null) {
          _updateUserFromSupabase(user);
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('AuthException:', '').replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Alias for signUp with named parameters
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return signUpWithEmail(email, password, name);
  }

  /// Logout method
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {}

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
