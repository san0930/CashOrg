import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/theme_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileService profileService;
  final AuthService authService;
  final ThemeService? themeService;

  const ProfileScreen({
    super.key,
    required this.profileService,
    required this.authService,
    this.themeService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.profileService.addListener(_onProfileUpdate);
  }

  void _onProfileUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.profileService.removeListener(_onProfileUpdate);
    super.dispose();
  }

  void _openEditProfile() async {
    final updated = await EditProfileDialog.show(context, widget.profileService);
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseRose,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await widget.authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      authService: widget.authService,
                      themeService: widget.themeService,
                    ),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.profileService.currentProfile;
    final user = widget.authService.currentUser;

    final name = profile?.name ?? user?.name ?? 'User';
    final email = profile?.email ?? user?.email ?? '';
    final avatarUrl = profile?.avatarUrl ?? user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.expenseRose),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Profile Picture Avatar
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    InkWell(
                      onTap: _openEditProfile,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.darkBackground : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Full Name
              Text(
                name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Edit Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _openEditProfile,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(height: 16),

              // Theme Mode Toggle
              Card(
                elevation: 0,
                color: isDark ? AppTheme.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDark ? const Color(0xFFFBBF24) : AppTheme.primary,
                  ),
                  title: Text(
                    'Dark Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isDark ? 'Dark mode enabled' : 'Light mode enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                  ),
                  value: isDark,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (_) {
                    ThemeService().toggleTheme();
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 16),

              // If Guest User, show Google Sign In Upgrade option
              if (widget.authService.isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_rounded, color: AppTheme.primary, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Upgrade to Google Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in with Google to securely back up and sync your CashOrg financial records.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final success = await widget.authService.signInWithGoogle();
                            if (success && mounted) {
                              navigator.pop();
                            }
                          },
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Sign in with Google'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.expenseRose,
                    side: BorderSide(color: AppTheme.expenseRose.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(widget.authService.isGuest ? 'Exit Guest Mode' : 'Log Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
