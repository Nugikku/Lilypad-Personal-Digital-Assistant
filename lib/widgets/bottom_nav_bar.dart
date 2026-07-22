import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class LilypadBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LilypadBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.headerBg,
        border: Border(
          top: BorderSide(color: AppColors.headerBorder, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBorder,
            offset: Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildNavItem(0, Icons.cloud_outlined, 'WEATHER'),
          _buildNavItem(1, Icons.calendar_today_outlined, 'CALENDAR'),
          _buildNavItem(2, Icons.home_outlined, 'HOME', isCenter: true),
          _buildNavItem(3, Icons.smart_toy_outlined, 'LILY.AI'),
          _buildNavItem(4, Icons.payments_outlined, 'FINANCE'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isCenter = false}) {
    final isActive = currentIndex == index;
    final activeIcon = _getFilledIcon(icon);

    if (isActive) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Transform.translate(
          offset: const Offset(0, -8),
          child: Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              border: Border.all(color: AppColors.headerBorder, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.headerBorder,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(activeIcon, color: AppColors.headerBorder, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headerBorder,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 64,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Opacity(
            opacity: 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, color: AppColors.headerBorder, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headerBorder,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFilledIcon(IconData icon) {
    if (icon == Icons.cloud_outlined) return Icons.cloud;
    if (icon == Icons.calendar_today_outlined) return Icons.calendar_today;
    if (icon == Icons.home_outlined) return Icons.home;
    if (icon == Icons.smart_toy_outlined) return Icons.smart_toy;
    if (icon == Icons.payments_outlined) return Icons.payments;
    return icon;
  }
}
