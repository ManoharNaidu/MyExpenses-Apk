import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/onboarding_state.dart';
import '../../core/constants/currencies.dart';

class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard>
    with SingleTickerProviderStateMixin {
  static const _personaExpenseDefaults = <String, List<String>>{
    'tracker': ['Food', 'Transport', 'Utilities', 'Shopping', 'Misc'],
    'saver': ['Food', 'Groceries', 'Transport', 'Entertainment', 'Misc'],
    'analyser': ['Food', 'Transport', 'Utilities', 'Medical', 'Shopping'],
    'organiser': ['Groceries', 'Petrol', 'Utilities', 'Transport', 'Misc'],
  };

  static const _personaIncomeDefaults = <String, List<String>>{
    'tracker': ['Salary', 'Transfer'],
    'saver': ['Salary', 'Freelance'],
    'analyser': ['Salary', 'Investments'],
    'organiser': ['Salary', 'Transfer'],
  };

  static const _incomeOptions = <String>[
    'Salary',
    'Freelance',
    'Business',
    'Investments',
    'Bonus',
    'Transfer',
    'Allowance',
    'Other',
  ];

  static const _expenseOptions = <String>[
    'Food',
    'Groceries',
    'Transport',
    'Utilities',
    'Medical',
    'Shopping',
    'Entertainment',
    'Rent',
    'Travel',
    'Misc',
  ];

  late final PageController _pageController;
  late final AnimationController _progressController;

  int _currentStep = 0;
  bool _isCompleting = false;

  String? _persona;
  String? _name;
  String? _currency;
  final Set<String> _incomeCategories = <String>{};
  final Set<String> _expenseCategories = <String>{};

  final TextEditingController _incomeCustomController = TextEditingController();
  final TextEditingController _expenseCustomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 0,
    );

    final auth = ref.read(authProvider).state;
    _name = auth.userName;
    _currency = auth.effectiveCurrency;

    unawaited(_restoreProgress());
  }

  @override
  void dispose() {
    _incomeCustomController.dispose();
    _expenseCustomController.dispose();
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    final saved = await OnboardingState.load();
    if (!mounted) return;

    setState(() {
      _currentStep = saved.currentStep.clamp(0, 4);
      _persona = saved.persona ?? _persona;
      _name = saved.collectedName ?? _name;
      _currency = saved.collectedCurrency ?? _currency;
      _incomeCategories
        ..clear()
        ..addAll(saved.incomeCategories);
      _expenseCategories
        ..clear()
        ..addAll(saved.expenseCategories);
    });

    _pageController.jumpToPage(_currentStep);
    _progressController.value = _currentStep / 4;

    if (_persona != null && _incomeCategories.isEmpty && _expenseCategories.isEmpty) {
      _applyPersonaDefaults();
    }
  }

  Future<void> _persistProgress() {
    return OnboardingState(
      currentStep: _currentStep,
      persona: _persona,
      collectedName: _name,
      collectedCurrency: _currency,
      incomeCategories: _incomeCategories.toList(),
      expenseCategories: _expenseCategories.toList(),
    ).save();
  }

  Future<void> _goToStep(int step) async {
    if (step < 0 || step > 4 || step == _currentStep) return;

    final previous = _currentStep;
    setState(() => _currentStep = step);

    _progressController.animateTo(
      _currentStep / 4,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );

    if (step > previous) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    await _persistProgress();
  }

  void _applyPersonaDefaults() {
    final persona = _persona;
    if (persona == null) return;
    _incomeCategories
      ..clear()
      ..addAll(_personaIncomeDefaults[persona] ?? const <String>[]);
    _expenseCategories
      ..clear()
      ..addAll(_personaExpenseDefaults[persona] ?? const <String>[]);
  }

  Future<void> _complete() async {
    if (_isCompleting) return;

    final auth = ref.read(authProvider);
    final incomes = _incomeCategories.isEmpty
        ? (_personaIncomeDefaults[_persona] ?? const <String>['Salary'])
        : _incomeCategories.toList();
    final expenses = _expenseCategories.isEmpty
        ? (_personaExpenseDefaults[_persona] ?? const <String>['Food', 'Misc'])
        : _expenseCategories.toList();

    setState(() => _isCompleting = true);

    try {
      final selectedCurrency = (_currency ?? auth.state.effectiveCurrency).trim().toUpperCase();
      if (selectedCurrency != auth.state.effectiveCurrency) {
        await auth.updateCurrency(selectedCurrency);
      }

      await auth.markOnboarded(
        categories: {...incomes, ...expenses}.toList(),
        incomeCategories: incomes,
        expenseCategories: expenses,
        persona: _persona,
      );

      await OnboardingState.clear();
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Widget _stepContainer(Widget child) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final textSecondary = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: _currentStep > 0
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                            onPressed: () => _goToStep(_currentStep - 1),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 4,
                          color: AppTheme.accent,
                          backgroundColor: isDark ? AppTheme.darkDivider : AppTheme.divider,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepContainer(_buildStep1(auth.userName, textPrimary, textSecondary)),
                  _stepContainer(_buildStep2(textPrimary, textSecondary, isDark)),
                  _stepContainer(_buildStep3(textPrimary, textSecondary)),
                  _stepContainer(_buildStep4(textPrimary, textSecondary, isDark)),
                  _stepContainer(_buildStep5(textPrimary, textSecondary, isDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(String? userName, Color textPrimary, Color textSecondary) {
    final shownName = (userName == null || userName.trim().isEmpty) ? 'there' : userName.trim();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome, $shownName',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            "Let's set up your financial dashboard in under 2 minutes.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _goToStep(1),
            child: const Text("Let's go"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(Color textPrimary, Color textSecondary, bool isDark) {
    final items = const [
      ('tracker', 'Track where my money goes', '🎯'),
      ('saver', 'Spend less, save more', '💰'),
      ('analyser', 'Understand my health', '📊'),
      ('organiser', 'Organise bank statements', '🧾'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What's your main goal right now?",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (_, index) {
            final (id, label, emoji) = items[index];
            final selected = _persona == id;
            return GestureDetector(
              onTap: () async {
                setState(() {
                  _persona = id;
                  _applyPersonaDefaults();
                });
                await _persistProgress();
                await Future<void>.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  _goToStep(2);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()..scale(selected ? 1.03 : 1.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accent
                      : (isDark ? AppTheme.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppTheme.accentDark
                        : (isDark ? AppTheme.darkDivider : AppTheme.divider),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppTheme.textDark : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep3(Color textPrimary, Color textSecondary) {
    final selectedCurrency = (_currency ?? ref.read(authProvider).state.effectiveCurrency)
        .trim()
        .toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where are you based?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose your default currency for all amounts.',
          style: TextStyle(color: textSecondary),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: supportedCurrencies.any((c) => c.code == selectedCurrency)
              ? selectedCurrency
              : supportedCurrencies.first.code,
          items: supportedCurrencies
              .map((c) => DropdownMenuItem(value: c.code, child: Text(c.label)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _currency = value);
            unawaited(_persistProgress());
          },
          decoration: const InputDecoration(labelText: 'Currency'),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => _goToStep(3),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildStep4(Color textPrimary, Color textSecondary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How do you earn?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'Select one or more income sources.',
          style: TextStyle(color: textSecondary),
        ),
        const SizedBox(height: 14),
        _chipGrid(
          options: _incomeOptions,
          selected: _incomeCategories,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _incomeCustomController,
                decoration: const InputDecoration(labelText: 'Add custom income source'),
              ),
            ),
            IconButton(
              onPressed: () {
                final value = _incomeCustomController.text.trim();
                if (value.isEmpty) return;
                setState(() => _incomeCategories.add(value));
                _incomeCustomController.clear();
                unawaited(_persistProgress());
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            if (_incomeCategories.isEmpty && _persona != null) {
              _incomeCategories.addAll(_personaIncomeDefaults[_persona] ?? const <String>[]);
            }
            unawaited(_goToStep(4));
          },
          child: const Text("I'll set this later"),
        ),
        FilledButton(
          onPressed: () => _goToStep(4),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildStep5(Color textPrimary, Color textSecondary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What do you regularly spend on?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          '4 of 5 - almost there!',
          style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _chipGrid(
          options: _expenseOptions,
          selected: _expenseCategories,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expenseCustomController,
                decoration: const InputDecoration(labelText: 'Add custom spending category'),
              ),
            ),
            IconButton(
              onPressed: () {
                final value = _expenseCustomController.text.trim();
                if (value.isEmpty) return;
                setState(() => _expenseCategories.add(value));
                _expenseCustomController.clear();
                unawaited(_persistProgress());
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            if (_expenseCategories.isEmpty && _persona != null) {
              _expenseCategories.addAll(_personaExpenseDefaults[_persona] ?? const <String>[]);
            }
            unawaited(_complete());
          },
          child: const Text("I'll set this later"),
        ),
        FilledButton(
          onPressed: _isCompleting ? null : _complete,
          child: _isCompleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start tracking'),
        ),
      ],
    );
  }

  Widget _chipGrid({
    required List<String> options,
    required Set<String> selected,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            setState(() {
              if (value) {
                selected.add(option);
              } else {
                selected.remove(option);
              }
            });
            unawaited(_persistProgress());
          },
          selectedColor: AppTheme.accent.withValues(alpha: 0.2),
          checkmarkColor: AppTheme.accentDark,
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        );
      }).toList(),
    );
  }
}
