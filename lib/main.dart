import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Cloud Connection
  await SupabaseConfig.initialize();

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  late final AuthService _authService;
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _themeService = ThemeService();
  }

  @override
  void dispose() {
    _authService.dispose();
    _themeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'CashOrg',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeService.themeMode,
          home: AnimatedBuilder(
            animation: _authService,
            builder: (context, child) {
              if (_authService.isAuthenticated) {
                return DashboardScreen(
                  authService: _authService,
                  themeService: _themeService,
                );
              }
              return LoginScreen(
                authService: _authService,
                themeService: _themeService,
              );
            },
          ),
        );
      },
    );
  }
}
