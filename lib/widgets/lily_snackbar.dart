import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'pixel_container.dart';

class LilySnackBar {
  static void show(BuildContext context, {required String message, bool isSuccess = false}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    final Color bgColor = isSuccess ? AppColors.primaryContainer : AppColors.errorContainer;
    final Color borderColor = isSuccess ? AppColors.primary : AppColors.error;
    final Color textColor = isSuccess ? AppColors.onPrimaryContainer : AppColors.onErrorContainer;
    final IconData icon = isSuccess ? Icons.check_circle_outline : Icons.warning_amber_rounded;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.all(16),
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
