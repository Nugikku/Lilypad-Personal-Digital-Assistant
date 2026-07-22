import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import '../widgets/pixel_button.dart';
import '../widgets/lily_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      LilySnackBar.show(context, message: 'Please fill all required fields', isSuccess: false);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      LilySnackBar.show(context, message: 'Passwords do not match', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'username': _usernameController.text.trim()},
      );
      if (mounted) {
        LilySnackBar.show(context, message: 'Registration successful!', isSuccess: true);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (error) {
      if (mounted) {
        LilySnackBar.show(context, message: error.message, isSuccess: false);
      }
    } catch (error) {
      if (mounted) {
        LilySnackBar.show(context, message: 'Unexpected error occurred', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Decorative leaves
                Positioned(
                  top: -24,
                  left: -24,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                  ),
                ),

                // Main card
                PixelContainer(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  shadowOffsetX: 6,
                  shadowOffsetY: 6,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.primary,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.eco,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LILYPAD',
                              style: GoogleFonts.silkscreen(
                                fontSize: 32,
                                color: AppColors.primary,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join the Pond',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Username field
                      _buildInputField(
                        label: 'Username',
                        hint: 'cool_frog',
                        icon: Icons.person_outline,
                        isPassword: false,
                        controller: _usernameController,
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      _buildInputField(
                        label: 'Email Aktif',
                        hint: 'you@pond.com',
                        icon: Icons.mail_outline,
                        isPassword: false,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      _buildInputField(
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password field
                      _buildInputField(
                        label: 'Confirm Password',
                        hint: '••••••••',
                        icon: Icons.verified_user_outlined,
                        isPassword: true,
                        controller: _confirmPasswordController,
                      ),
                      const SizedBox(height: 24),

                      // Register button
                      _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : PixelButton(
                              text: 'DAFTAR',
                              icon: Icons.arrow_forward,
                              backgroundColor: AppColors.primaryContainer,
                              textColor: AppColors.onPrimaryFixed,
                              onPressed: _signUp,
                            ),
                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Log In',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required bool isPassword,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppColors.outlineVariant,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }
}
