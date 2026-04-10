import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LucidButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isGradient;
  final double width;
  final double height;
  final Color? color;

  const LucidButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isGradient = true,
    this.width = double.infinity,
    this.height = 56,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isGradient ? AppColors.lucidGradient : null,
        color: !isGradient ? (color ?? Theme.of(context).primaryColor) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isGradient ? [
          BoxShadow(
            color: AppColors.pureMint.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          child: child,
        ),
      ),
    );
  }
}
