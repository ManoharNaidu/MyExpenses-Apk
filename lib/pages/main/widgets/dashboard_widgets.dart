import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  const DashboardHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (isDark ? AppColors.sapphirePrimary : AppColors.auroraPrimary).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: (isDark ? AppColors.sapphirePrimary : AppColors.auroraPrimary).withOpacity(0.1),
              child: Icon(
                Icons.person_outline,
                color: isDark ? AppColors.sapphirePrimary : AppColors.auroraPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onManualAdd;
  final VoidCallback onUploadPdf;
  final VoidCallback onReviewStaged;
  final VoidCallback onSettings;

  const QuickActionsGrid({
    super.key,
    required this.onManualAdd,
    required this.onUploadPdf,
    required this.onReviewStaged,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionItem(
            icon: Icons.add_rounded,
            label: 'Manual',
            onTap: onManualAdd,
            color: AppColors.income,
          ),
          _QuickActionItem(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF Scan',
            onTap: onUploadPdf,
            color: AppColors.expense,
          ),
          _QuickActionItem(
            icon: Icons.assignment_rounded,
            label: 'Review',
            onTap: onReviewStaged,
            color: Colors.orangeAccent,
          ),
          _QuickActionItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: onSettings,
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetProgressCard extends StatelessWidget {
  final double budgetLimit;
  final double spentAmount;

  const BudgetProgressCard({
    super.key,
    required this.budgetLimit,
    required this.spentAmount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budgetLimit > 0 ? (spentAmount / budgetLimit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spentAmount > budgetLimit;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.sapphirePrimary : AppColors.auroraPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Health',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOverBudget ? AppColors.expense : primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOverBudget ? AppColors.expense : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? AppColors.expense : primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPENT',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    '\$${spentAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'REMAINING',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    '\$${(budgetLimit - spentAmount).clamp(0.0, double.infinity).toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.income : Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
