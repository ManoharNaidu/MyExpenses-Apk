import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Layer: Obsidian Abyss
        Positioned.fill(
          child: Container(
            color: AppColors.obsidianAbyss,
          ),
        ),
        
        // Prism Mesh Layer: Top Left Mint Glow
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.pureMint.withOpacity(0.12),
                  AppColors.pureMint.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        
        // Prism Mesh Layer: Bottom Right Coral Glow
        Positioned(
          bottom: -150,
          right: -50,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.coralPop.withOpacity(0.08),
                  AppColors.coralPop.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        
        // Subtle Central Gold Dust
        Positioned(
          top: 200,
          right: 20,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.electricGold.withOpacity(0.05),
                  AppColors.electricGold.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        
        // Content Area
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
