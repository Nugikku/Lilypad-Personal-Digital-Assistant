import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class LilyChatScreen extends StatelessWidget {
  const LilyChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Text('🐸', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'Lily.AI',
              style: GoogleFonts.silkscreen(
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: AppColors.primary),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon lock pixel style
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.primary,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'AKSES DIBATASI',
                style: GoogleFonts.silkscreen(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Message box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.primary,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'Fitur atau halaman ini dibatasi oleh developer untuk alasan keamanan API AI.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Sub message
              Text(
                '— Nugroho Saputra Jati 🐸',
                style: GoogleFonts.silkscreen(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
