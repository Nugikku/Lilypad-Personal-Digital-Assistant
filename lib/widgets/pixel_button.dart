import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PixelButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color borderColor;
  final double borderWidth;
  final bool isFullWidth;

  const PixelButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor = AppColors.primary,
    this.borderWidth = 4,
    this.isFullWidth = true,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppColors.primaryContainer;
    final txtColor = widget.textColor ?? AppColors.onPrimaryFixed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.isFullWidth ? double.infinity : null,
        transform: _isPressed
            ? (Matrix4.identity()..translate(4.0, 4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: widget.borderColor, width: widget.borderWidth),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.borderColor,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: txtColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: txtColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
