import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import '../widgets/pixel_button.dart';
import '../widgets/lily_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  void _fetchUser() {
    setState(() {
      _user = _supabase.auth.currentUser;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn().signOut();
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        LilySnackBar.show(
          context,
          message: 'Error signing out: $e',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.primary, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'GANTI KATA SANDI',
          style: GoogleFonts.silkscreen(color: AppColors.primary),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: GoogleFonts.plusJakartaSans(),
          decoration: const InputDecoration(
            labelText: 'Kata Sandi Baru',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: GoogleFonts.silkscreen(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () async {
              final newPassword = passwordController.text;
              if (newPassword.length >= 6) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _supabase.auth.updateUser(
                    UserAttributes(password: newPassword),
                  );
                  if (mounted) {
                    LilySnackBar.show(
                      context,
                      message: 'Kata sandi berhasil diubah!',
                      isSuccess: true,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    LilySnackBar.show(
                      context,
                      message: 'Gagal mengubah kata sandi: $e',
                      isSuccess: false,
                    );
                  }
                } finally {
                  setState(() => _isLoading = false);
                }
              } else {
                LilySnackBar.show(
                  context,
                  message: 'Kata sandi minimal 6 karakter',
                  isSuccess: false,
                );
              }
            },
            child: Text(
              'SIMPAN',
              style: GoogleFonts.silkscreen(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isGoogleAuth = _user?.appMetadata['provider'] == 'google';
    final email = _user?.email ?? 'Unknown Email';

    // Attempt to extract username or full name from metadata
    final fullName =
        _user?.userMetadata?['username'] ??
        _user?.userMetadata?['full_name'] ??
        _user?.userMetadata?['name'] ??
        (isGoogleAuth ? 'Google User' : 'Lilypad User');

    final avatarUrl =
        _user?.userMetadata?['avatar_url'] ?? _user?.userMetadata?['picture'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.headerBorder),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.headerBorder,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: AppColors.headerBorder, height: 4),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info Card
            PixelContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      border: Border.all(color: AppColors.primary, width: 4),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primary,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(46),
                      child: avatarUrl != null
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.outlineVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isGoogleAuth
                          ? Colors.redAccent.withValues(alpha: 0.1)
                          : AppColors.secondaryContainer,
                      border: Border.all(
                        color: isGoogleAuth
                            ? Colors.redAccent
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGoogleAuth ? Icons.g_mobiledata : Icons.email,
                          color: isGoogleAuth
                              ? Colors.redAccent
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isGoogleAuth ? 'Google Account' : 'Lilypad Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: isGoogleAuth
                                ? Colors.redAccent
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings List
            if (!isGoogleAuth) ...[
              const Text(
                'ACCOUNT',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              PixelContainer(
                padding: const EdgeInsets.all(0),
                child: ListTile(
                  leading: const Icon(Icons.password, color: AppColors.primary),
                  title: Text(
                    'Ganti Kata Sandi',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                  ),
                  onTap: _changePassword,
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'APP SETTINGS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            PixelContainer(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_active,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Notifikasi Harian',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  Container(height: 2, color: AppColors.primary),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Tentang Lilypad',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    trailing: Text(
                      'v1.0.0',
                      style: GoogleFonts.silkscreen(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sign out button
            PixelButton(
              text: 'KELUAR',
              onPressed: _signOut,
              isFullWidth: true,
              backgroundColor: AppColors.error,
              textColor: AppColors.onError,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
