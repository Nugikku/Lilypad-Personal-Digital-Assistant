import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import '../widgets/pixel_button.dart';
import '../widgets/lily_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      LilySnackBar.show(context, message: 'Please fill all fields', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Web Client ID dari Google Cloud Console
      const webClientId = '662530981437-0ab2636bgltjd1rguoeb399v628kpggu.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Login dibatalkan oleh pengguna.';
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'ID Token tidak ditemukan.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (error) {
      if (mounted) {
        LilySnackBar.show(context, message: 'Error Google Sign-In: $error', isSuccess: false);
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Frog mascot image
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primary,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAmO4mOiwsJgQ2-1OAfOA9pSOtcCKpcVlgVBl0w4JbQne-4MHg-KA9DvVorT06aCTo7yknwGZDNptZQpdIQpSndKYgZDXF39LMvoEdIFBVub19FSmxchHRbmNGAiETSoO1lbR10JUYDL2rv0dsvV9e2NN2_pk0aU_PhZy0vS5EVhTTOp1F83C3hBBbtsm22Lv0SYA9jdZIIuPDL2K6vW6NRPUaTUJ2ORD9v7Da9PparHu8cJuxWEmUK4bIis4miEtfSG_9-yFxi-A',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.eco,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main login card
                PixelContainer(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  shadowOffsetX: 8,
                  shadowOffsetY: 8,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'LILYPAD',
                        style: GoogleFonts.silkscreen(
                          fontSize: 32,
                          color: AppColors.primary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back to the pond.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email field
                      _buildInputField(
                        label: 'EMAIL ADDRESS',
                        hint: 'lily@pond.com',
                        icon: Icons.mail,
                        isPassword: false,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      _buildInputField(
                        label: 'PASSWORD',
                        hint: '••••••••',
                        icon: Icons.lock,
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 4),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                              decoration: TextDecoration.underline,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Login button
                      _isLoading
                          ? const CircularProgressIndicator(color: AppColors.primary)
                          : PixelButton(
                              text: 'START PLAYING',
                              icon: Icons.login,
                              onPressed: _signIn,
                            ),
                      const SizedBox(height: 20),

                      // Divider
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.outlineVariant,
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: List.generate(
                                (constraints.maxWidth / 12).floor(),
                                (index) => Container(
                                  width: 6,
                                  height: 3,
                                  margin: const EdgeInsets.only(right: 6),
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Sign in with Google (Placeholder for future)
                      PixelButton(
                        text: 'SIGN IN WITH GOOGLE',
                        icon: Icons.g_mobiledata,
                        backgroundColor: AppColors.surfaceBright,
                        textColor: AppColors.primary,
                        onPressed: _signInWithGoogle,
                      ),
                      const SizedBox(height: 20),

                      // Sign up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New to the pond? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              'SIGN UP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationThickness: 2,
                                letterSpacing: 0.6,
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
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBright,
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
                color: AppColors.outline,
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
