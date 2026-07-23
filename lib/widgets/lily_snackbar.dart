import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'pixel_container.dart';

class LilySnackBar {
  // Digunakan dari luar dialog (context biasa)
  static void show(BuildContext context, {required String message, bool isSuccess = false}) {
    final messenger = ScaffoldMessenger.of(context);
    _display(messenger, message: message, isSuccess: isSuccess);
  }

  // Digunakan dari dalam dialog (pakai messenger yang sudah disimpan sebelum dialog terbuka)
  static void showWithMessenger(ScaffoldMessengerState messenger, {required String message, bool isSuccess = false}) {
    _display(messenger, message: message, isSuccess: isSuccess);
  }

  static void _display(ScaffoldMessengerState messenger, {required String message, bool isSuccess = false}) {
    messenger.hideCurrentSnackBar();

    final Color bgColor     = isSuccess ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    final Color borderColor = isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
    final Color textColor   = Colors.white;
    final IconData icon     = isSuccess ? Icons.check_circle : Icons.warning_rounded;

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: const Duration(seconds: 4),
        content: PixelContainer(
          borderColor: borderColor,
          backgroundColor: bgColor,
          borderWidth: 3,
          shadowOffsetX: 4,
          shadowOffsetY: 4,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: borderColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
