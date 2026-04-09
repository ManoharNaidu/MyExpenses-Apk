import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/health_score.dart';
import '../core/constants/app_colors.dart';

class HealthScoreGauge extends StatefulWidget {
  final HealthScore score;
  final bool animate;

  const HealthScoreGauge({
    super.key,
    required this.score,
    this.animate = true,
  });

  @override
  State<HealthScoreGauge> createState() => _HealthScoreGaugeState();
}

class _HealthScoreGaugeState extends State<HealthScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ScoreBreakdownSheet(score: widget.score),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 120,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      score: widget.score.totalScore,
                      progress: _animation.value,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Column(
                    children: [
                      Text(
                        (widget.score.totalScore * _animation.value).round().toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: widget.score.band.color,
                        ),
                      ),
                      Text(
                        widget.score.band.label,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.score.band.color.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.score.coachingMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showBreakdown(context),
              icon: Icon(Icons.info_outline, size: 16, color: widget.score.band.color),
              label: Text(
                "How is this calculated?",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.score.band.color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final double progress;

  _GaugePainter({required this.score, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final strokeWidth = 12.0;

    // Background Arc
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Progress Arc
    final sweepAngle = (score / 100) * math.pi * progress;
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.red,
          Colors.orange,
          Colors.blue,
          Colors.green,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.progress != progress;
}

class _ScoreBreakdownSheet extends StatelessWidget {
  final HealthScore score;

  const _ScoreBreakdownSheet({required this.score});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.sapphireSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Financial Health Score Breakdown",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Based on your activity in ${score.monthKey}",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          _BreakdownItem(
            label: "Savings Rate",
            points: score.savingsPoints,
            maxPoints: 30,
            description: "How much of your income you've kept. Recommended: 20%+",
            subLabel: "${(score.savingsRate * 100).toStringAsFixed(1)}%",
          ),
          _BreakdownItem(
            label: "Budget Adherence",
            points: score.budgetPoints,
            maxPoints: 25,
            description: "Staying within your category limits.",
            subLabel: "${(score.budgetAdherence * 100).round()}% categories on track",
          ),
          _BreakdownItem(
            label: "Spending Trends",
            points: score.trendPoints,
            maxPoints: 20,
            description: "Spending patterns compared to previous months.",
            subLabel: score.spendVsAverage <= 1.0 ? "Below average spending" : "Above average spending",
          ),
          _BreakdownItem(
            label: "Consistency",
            points: score.consistencyPoints,
            maxPoints: 15,
            description: "Frequency of transaction tracking.",
            subLabel: "${score.activeDays} days active this month",
          ),
          _BreakdownItem(
            label: "Income Growth",
            points: score.growthPoints,
            maxPoints: 10,
            description: "Improvement in earning power.",
            subLabel: score.growthPoints > 0 ? "Income is healthy" : "Seeking growth",
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: score.band.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Got it!"),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final int points;
  final int maxPoints;
  final String description;
  final String subLabel;

  const _BreakdownItem({
    required this.label,
    required this.points,
    required this.maxPoints,
    required this.description,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "$points / $maxPoints pts",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: points > (maxPoints * 0.7) ? Colors.green : (points > (maxPoints * 0.4) ? Colors.orange : Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: points / maxPoints,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                points > (maxPoints * 0.7) ? Colors.green : (points > (maxPoints * 0.4) ? Colors.orange : Colors.red),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
