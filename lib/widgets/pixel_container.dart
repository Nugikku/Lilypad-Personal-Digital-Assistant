import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PixelContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const PixelContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor = AppColors.primary,
    this.borderWidth = 4,
    this.shadowOffsetX = 4,
    this.shadowOffsetY = 4,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLowest,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: Offset(shadowOffsetX, shadowOffsetY),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
