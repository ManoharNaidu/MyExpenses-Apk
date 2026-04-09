import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/currencies.dart';
import '../../core/auth/auth_provider.dart';
import '../../app/theme.dart';
import '../../widgets/app_feedback_dialog.dart';

class Persona {
  final String title;
  final String description;
  final IconData icon;
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final Color color;

  const Persona({
    required this.title,
    required this.description,
    required this.icon,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.color,
  });
}

final List<Persona> personas = [
  Persona(
    title: 'Professional',
    description: 'Focused on salary, investments, and home expenses.',
    icon: Icons.work_outline_rounded,
    incomeCategories: ['Salary', 'Bonus', 'Investment'],
    expenseCategories: ['Rent/Mortgage', 'Groceries', 'Transport', 'Insurance', 'Dining Out'],
    color: const Color(0xFF6366F1),
  ),
  Persona(
    title: 'Student',
    description: 'Tracking pocket money, grants, and education costs.',
    icon: Icons.school_outlined,
    incomeCategories: ['Allowance', 'Part-time Job', 'Scholarship'],
    expenseCategories: ['Education', 'Dining Out', 'Social', 'Subscriptions', 'Phone/Internet'],
    color: const Color(0xFF10B981),
  ),
  Persona(
    title: 'Freelancer',
    description: 'Managing project income and business expenses.',
    icon: Icons.laptop_mac_rounded,
    incomeCategories: ['Freelance', 'Bonus', 'Investment'],
    expenseCategories: ['Rent/Mortgage', 'Groceries', 'Transport', 'Phone/Internet', 'Subscriptions'],
    color: const Color(0xFFF59E0B),
  ),
  Persona(
    title: 'Home Maker',
    description: 'Managing household budget and daily groceries.',
    icon: Icons.home_work_outlined,
    incomeCategories: ['Allowance', 'Gifts', 'Transfer'],
    expenseCategories: ['Groceries', 'Utilities', 'Health/Medical', 'Kids/Education', 'Misc'],
    color: const Color(0xFFEC4899),
  ),
];


class SimplifiedOnboarding extends ConsumerStatefulWidget {
  const SimplifiedOnboarding({super.key});

  @override
  ConsumerState<SimplifiedOnboarding> createState() => _SimplifiedOnboardingState();
}

class _SimplifiedOnboardingState extends ConsumerState<SimplifiedOnboarding> {
  String? _selectedPersona;
  final Set<String> _selectedIncome = {};
  final Set<String> _selectedExpense = {};
  late String _selectedCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialCurrency = ref.read(authProvider).state.effectiveCurrency;
    _selectedCurrency = supportedCurrencies.any((c) => c.code == initialCurrency.trim().toUpperCase())
        ? initialCurrency.trim().toUpperCase()
        : supportedCurrencies.first.code;
  }

  void _selectPersona(Persona persona) {
    setState(() {
      _selectedPersona = persona.title;
      _selectedIncome.clear();
      _selectedIncome.addAll(persona.incomeCategories);
      _selectedExpense.clear();
      _selectedExpense.addAll(persona.expenseCategories);
    });
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authProvider);
      
      // Update currency if changed
      if (_selectedCurrency != auth.state.effectiveCurrency) {
        await auth.updateCurrency(_selectedCurrency);
      }

      // Mark as onboarded with choices
      await auth.markOnboarded(
        categories: {..._selectedIncome, ..._selectedExpense}.toList(),
        incomeCategories: _selectedIncome.toList(),
        expenseCategories: _selectedExpense.toList(),
      );
    } catch (e) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Onboarding Failed',
        message: e.toString(),
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildSectionHeader("Who are you?", "We'll tailor your experience."),
                  const SizedBox(height: 16),
                  _buildPersonaGrid(),
                  const SizedBox(height: 40),
                  if (_selectedPersona != null) ...[
                    _buildSectionHeader(
                      "Your Categories", 
                      "Smarter defaults based on your profile.",
                    ).animate().fadeIn().slideY(begin: 0.2),
                    const SizedBox(height: 16),
                    _buildCategorySection(
                      "Income", 
                      _selectedIncome, 
                      predefinedIncomeCategories,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _buildCategorySection(
                      "Expenses", 
                      _selectedExpense, 
                      predefinedExpenseCategories,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedPersona != null
          ? _buildGetStartedButton()
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.accent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.all(24),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accent,
                    AppTheme.accent.withValues(alpha: 0.8),
                    const Color(0xFF6366F1),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 48,
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                  const SizedBox(height: 12),
                  Text(
                    "Welcome!",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildCurrencyPicker(),
      ],
    );
  }

  Widget _buildCurrencyPicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCurrencySelector(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                _selectedCurrency,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 400,
          child: Column(
            children: [
              Text("Select Currency", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: supportedCurrencies.length,
                  itemBuilder: (context, index) {
                    final curr = supportedCurrencies[index];
                    return ListTile(
                      title: Text(curr.label),
                      trailing: _selectedCurrency == curr.code 
                          ? const Icon(Icons.check_circle, color: AppTheme.accent)
                          : null,
                      onTap: () {
                        setState(() => _selectedCurrency = curr.code);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSoft, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPersonaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: personas.length,
      itemBuilder: (context, index) {
        final persona = personas[index];
        final isSelected = _selectedPersona == persona.title;
        return InkWell(
          onTap: () => _selectPersona(persona),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: 300.ms,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? persona.color : AppTheme.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: persona.color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                else
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  persona.icon,
                  size: 40,
                  color: isSelected ? Colors.white : AppTheme.textSoft,
                ),
                const SizedBox(height: 12),
                Text(
                  persona.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  persona.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : AppTheme.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ).animate(target: isSelected ? 1 : 0).scale(end: const Offset(1.05, 1.05));
      },
    );
  }

  Widget _buildCategorySection(String label, Set<String> selection, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((cat) {
            final isSelected = selection.contains(cat);
            return FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  val ? selection.add(cat) : selection.remove(cat);
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppTheme.card,
              selectedColor: AppTheme.accent.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.accent : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _completeOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.textDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppTheme.textDark.withValues(alpha: 0.4),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Let's Go",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
        ),
      ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutBack),
    );
  }
}
