import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({
    super.key,
    required this.authService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _handleGoogleLogin() async {
    final success = await widget.authService.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(authService: widget.authService),
        ),
      );
    }
  }

  void _handleGuestLogin() {
    widget.authService.signInAsGuest();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(authService: widget.authService),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final isLoading = widget.authService.isLoading;
    final error = widget.authService.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // 1. CASHORG LOGO
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkDividerColor
                            : AppTheme.primary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/cashorg_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.balanceGradient,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. TAGLINE
                Text(
                  'Every Account. Every Rupee. One View.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 44),

                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.expenseRose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.expenseRose.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.expenseRose, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(color: AppTheme.expenseRose, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 4. GOOGLE LOGIN BUTTON (PRIMARY)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                    foregroundColor: primaryTextColor,
                    side: BorderSide(
                      color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : _handleGoogleLogin,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.primary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: CustomPaint(
                                size: const Size(22, 22),
                                painter: GoogleLogoPainter(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),

                // Divider ("or")
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. GUEST LOGIN BUTTON (SECONDARY)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : _handleGuestLogin,
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  label: const Text(
                    'Sign in as Guest',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint redPaint = Paint()..color = const Color(0xFFEA4335);
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4);
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853);
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05);

    final Rect rect = Rect.fromLTWH(0, 0, width, height);

    canvas.drawArc(rect, -0.6, 2.1, true, redPaint);
    canvas.drawArc(rect, 1.5, 1.4, true, yellowPaint);
    canvas.drawArc(rect, 2.9, 1.4, true, greenPaint);
    canvas.drawArc(rect, 4.3, 1.4, true, bluePaint);

    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(width / 2, height / 2), width * 0.32, whitePaint);

    final Path path = Path()
      ..moveTo(width * 0.48, height * 0.38)
      ..lineTo(width * 0.95, height * 0.38)
      ..lineTo(width * 0.95, height * 0.62)
      ..lineTo(width * 0.48, height * 0.62)
      ..close();
    canvas.drawPath(path, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
