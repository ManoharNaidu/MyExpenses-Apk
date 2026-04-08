import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/onboarding_state.dart';
import '../../core/constants/currencies.dart';
import '../../widgets/app_feedback_dialog.dart';

// ─── Persona → default category mappings ──────────────────────────

const _personaExpenseDefaults = <String, List<String>>{
  'tracker': ['Food', 'Transport', 'Utilities', 'Shopping', 'Misc'],
  'saver': ['Food', 'Groceries', 'Transport', 'Entertainment', 'Misc'],
  'analyser': ['Food', 'Transport', 'Utilities', 'Medical', 'Shopping'],
  'organiser': ['Groceries', 'Petrol', 'Utilities', 'Transport', 'Misc'],
};

const _personaIncomeDefaults = <String, List<String>>{
  'tracker': ['Salary', 'Transfer'],
  'saver': ['Salary', 'Freelance'],
  'analyser': ['Salary', 'Investments'],
  'organiser': ['Salary', 'Transfer'],
};

// ─── Income chip data ─────────────────────────────────────────────

const _incomeChips = <({IconData icon, String label})>[
  (icon: Icons.work, label: 'Salary'),
  (icon: Icons.laptop, label: 'Freelance'),
  (icon: Icons.swap_horiz, label: 'Transfer'),
  (icon: Icons.trending_up, label: 'Investments'),
  (icon: Icons.savings, label: 'Deposit'),
  (icon: Icons.card_giftcard, label: 'Gifts'),
];

// ─── Expense chip data ────────────────────────────────────────────

const _expenseChips = <({IconData icon, String label})>[
  (icon: Icons.restaurant, label: 'Food'),
  (icon: Icons.local_grocery_store, label: 'Groceries'),
  (icon: Icons.directions_bus, label: 'Transport'),
  (icon: Icons.local_gas_station, label: 'Petrol'),
  (icon: Icons.bolt, label: 'Utilities'),
  (icon: Icons.local_hospital, label: 'Medical'),
  (icon: Icons.shopping_bag, label: 'Shopping'),
  (icon: Icons.movie, label: 'Entertainment'),
  (icon: Icons.school, label: 'Education'),
  (icon: Icons.sports_soccer, label: 'Sports'),
  (icon: Icons.home, label: 'Room Rent'),
  (icon: Icons.more_horiz, label: 'Misc'),
];

// ═══════════════════════════════════════════════════════════════════
// OnboardingWizard
// ═══════════════════════════════════════════════════════════════════

class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _progressCtrl;

  int _currentStep = 0;
  static const _totalSteps = 5;
  static const _animDuration = Duration(milliseconds: 280);
  static const _animCurve = Curves.easeOutCubic;

  // Wizard data
  String? _persona;
  late String _currency;
  final Set<String> _incomes = {};
  final Set<String> _expenses = {};
  final _customIncomeCtrl = TextEditingController();
  final _customExpenseCtrl = TextEditingController();
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: _animDuration,
    );

    final auth = ref.read(authProvider).state;
    final rawCurrency = auth.effectiveCurrency;
    _currency = supportedCurrencies.any((c) => c.code == rawCurrency)
        ? rawCurrency
        : supportedCurrencies.first.code;

    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    final saved = await OnboardingState.load();
    if (saved.currentStep > 0) {
      setState(() {
        _currentStep = saved.currentStep;
        _persona = saved.persona;
        if (saved.collectedCurrency != null) _currency = saved.collectedCurrency!;
        _incomes.addAll(saved.incomeCategories);
        _expenses.addAll(saved.expenseCategories);
      });
      // Jump without animation on resume
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(_currentStep);
        }
        _progressCtrl.value = _currentStep / (_totalSteps - 1);
      });
    }
  }

  Future<void> _saveProgress() async {
    final state = OnboardingState(
      currentStep: _currentStep,
      persona: _persona,
      collectedCurrency: _currency,
      incomeCategories: _incomes.toList(),
      expenseCategories: _expenses.toList(),
    );
    await state.save();
  }

  void _goForward() {
    if (_currentStep >= _totalSteps - 1) return;
    setState(() => _currentStep++);
    _pageCtrl.nextPage(duration: _animDuration, curve: _animCurve);
    _progressCtrl.animateTo(
      _currentStep / (_totalSteps - 1),
      duration: _animDuration,
      curve: _animCurve,
    );
    _saveProgress();
  }

  void _goBack() {
    if (_currentStep <= 0) return;
    setState(() => _currentStep--);
    _pageCtrl.previousPage(duration: _animDuration, curve: _animCurve);
    _progressCtrl.animateTo(
      _currentStep / (_totalSteps - 1),
      duration: _animDuration,
      curve: _animCurve,
    );
    _saveProgress();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    _customIncomeCtrl.dispose();
    _customExpenseCtrl.dispose();
    super.dispose();
  }

  // ─── Build root ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.cream;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar + back button row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? AppTheme.darkTextPri : AppTheme.textDark,
                        size: 20,
                      ),
                      onPressed: _goBack,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (context, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progressCtrl.value,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? AppTheme.darkDivider
                              : AppTheme.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page view ──
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0Welcome(),
                  _buildStep1Persona(),
                  _buildStep2Currency(),
                  _buildStep3Income(),
                  _buildStep4Expenses(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Step 0 — Welcome
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStep0Welcome() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.read(authProvider).state;
    final name = auth.userName ?? 'there';
    final textPrimary = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome, $name 👋',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Let's set up your financial dashboard\nin under 2 minutes.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _goForward,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Let's go →",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Step 1 — Persona
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStep1Persona() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    const personas = <({String emoji, String label, String key})>[
      (emoji: '🎯', label: 'Track where my money goes', key: 'tracker'),
      (emoji: '💰', label: 'Spend less, save more', key: 'saver'),
      (emoji: '📊', label: 'Understand my health', key: 'analyser'),
      (emoji: '🧾', label: 'Organise bank statements', key: 'organiser'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your main goal\nright now?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us tailor your experience.',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: personas.map((p) {
              final isSelected = _persona == p.key;
              return _PersonaChip(
                emoji: p.emoji,
                label: p.label,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _persona = p.key;
                    // Pre-fill category defaults for this persona
                    _incomes
                      ..clear()
                      ..addAll(_personaIncomeDefaults[p.key] ?? []);
                    _expenses
                      ..clear()
                      ..addAll(_personaExpenseDefaults[p.key] ?? []);
                  });
                  // Auto-advance after a brief confirmation delay
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _goForward();
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Step 2 — Currency
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStep2Currency() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        28,
        32,
        28,
        28 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where are you based?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to format your numbers.",
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 28),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: InputDecoration(
              labelText: 'Preferred Currency',
              prefixIcon: const Icon(Icons.currency_exchange_outlined),
              filled: true,
              fillColor: isDark ? AppTheme.darkField : AppTheme.fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                ),
              ),
            ),
            dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
            items: supportedCurrencies
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.code,
                    child: Text(
                      c.label,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextPri : AppTheme.textDark,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _currency = v);
            },
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _goForward,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue →',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Step 3 — Income Sources
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStep3Income() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        28,
        32,
        28,
        28 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you earn?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply. You can always change later.',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 24),
          _ChipGrid(
            chips: _incomeChips,
            selected: _incomes,
            isDark: isDark,
            onToggle: (label) {
              setState(() {
                _incomes.contains(label)
                    ? _incomes.remove(label)
                    : _incomes.add(label);
              });
            },
          ),
          const SizedBox(height: 16),
          // Custom entry
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customIncomeCtrl,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextPri : AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add your own…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSec.withValues(alpha: 0.6)
                          : AppTheme.textSoft.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkField : AppTheme.fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _addCustomIncome(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addCustomIncome,
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: AppTheme.accent,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _goForward,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue →',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                // Keep persona defaults, advance
                _goForward();
              },
              child: Text(
                "I'll set this later",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomIncome() {
    final v = _customIncomeCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _incomes.add(v);
      _customIncomeCtrl.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // Step 4 — Spending Categories
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStep4Expenses() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        28,
        32,
        28,
        28 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you regularly\nspend on?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '4 of 5 — almost there!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _ChipGrid(
            chips: _expenseChips,
            selected: _expenses,
            isDark: isDark,
            onToggle: (label) {
              setState(() {
                _expenses.contains(label)
                    ? _expenses.remove(label)
                    : _expenses.add(label);
              });
            },
          ),
          const SizedBox(height: 16),
          // Custom entry
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customExpenseCtrl,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextPri : AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add your own…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSec.withValues(alpha: 0.6)
                          : AppTheme.textSoft.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkField : AppTheme.fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _addCustomExpense(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addCustomExpense,
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: AppTheme.accent,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isCompleting ? null : _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
              ),
              child: _isCompleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.textDark,
                      ),
                    )
                  : const Text(
                      'Start tracking →',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isCompleting ? null : _complete,
              child: Text(
                "I'll set this later",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomExpense() {
    final v = _customExpenseCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _expenses.add(v);
      _customExpenseCtrl.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // Complete onboarding
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _complete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final auth = ref.read(authProvider);

      // 1. Update currency if changed
      if (_currency != auth.state.effectiveCurrency) {
        await auth.updateCurrency(_currency);
      }

      // 2. Resolve final lists — fall back to persona defaults if empty
      final incomes = _incomes.isNotEmpty
          ? _incomes.toList()
          : (_personaIncomeDefaults[_persona] ?? ['Salary']);
      final expenses = _expenses.isNotEmpty
          ? _expenses.toList()
          : (_personaExpenseDefaults[_persona] ??
              ['Food', 'Transport', 'Utilities', 'Misc']);

      // 3. Mark onboarded
      await auth.markOnboarded(
        categories: [...incomes, ...expenses],
        incomeCategories: incomes,
        expenseCategories: expenses,
        persona: _persona,
      );

      // 4. Clear persisted wizard progress
      await OnboardingState.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      await showAppFeedbackDialog(
        context,
        title: 'Onboarding Failed',
        message: '$e',
        type: AppFeedbackType.error,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// _PersonaChip — 2×2 grid cell for persona selection
// ═══════════════════════════════════════════════════════════════════

class _PersonaChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PersonaChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgUnselected = isDark ? AppTheme.darkCard : Colors.white;
    final bgSelected = AppTheme.accent;
    final borderUnselected = isDark ? AppTheme.darkDivider : AppTheme.divider;
    final textColor = isSelected
        ? AppTheme.textDark
        : (isDark ? AppTheme.darkTextPri : AppTheme.textDark);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: isSelected
            ? (Matrix4.identity()..scale(1.03, 1.03, 1.0))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? bgSelected : bgUnselected,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: borderUnselected, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _ChipGrid — multi-select Wrap of icon+label chips
// ═══════════════════════════════════════════════════════════════════

class _ChipGrid extends StatelessWidget {
  final List<({IconData icon, String label})> chips;
  final Set<String> selected;
  final bool isDark;
  final void Function(String label) onToggle;

  const _ChipGrid({
    required this.chips,
    required this.selected,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...chips.map((c) {
          final isSel = selected.contains(c.label);
          return _CategoryChip(
            icon: c.icon,
            label: c.label,
            isSelected: isSel,
            isDark: isDark,
            onTap: () => onToggle(c.label),
          );
        }),
        // Show any custom entries not in the predefined list
        ...selected
            .where((s) => !chips.any((c) => c.label == s))
            .map(
              (custom) => _CategoryChip(
                icon: Icons.label_outline,
                label: custom,
                isSelected: true,
                isDark: isDark,
                onTap: () => onToggle(custom),
              ),
            ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// _CategoryChip — individual selectable chip
// ═══════════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgUnselected = isDark ? AppTheme.darkCard : Colors.white;
    final bgSelected = AppTheme.accent.withValues(alpha: 0.18);
    final borderUnselected = isDark ? AppTheme.darkDivider : AppTheme.divider;
    final borderSelected = AppTheme.accent.withValues(alpha: 0.5);
    final textUnselected = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final iconColor = isSelected ? AppTheme.accent : textUnselected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgSelected : bgUnselected,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? borderSelected : borderUnselected,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.accent : textUnselected,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 16, color: AppTheme.accent),
            ],
          ],
        ),
      ),
    );
  }
}
