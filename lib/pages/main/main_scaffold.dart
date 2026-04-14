import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';
import '../../core/constants/currencies.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/theme_provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'settings_page.dart';
import 'staged_review_screen.dart';
import '../../data/staged_draft_repository.dart';
import '../../data/transaction_repository.dart';
import '../../widgets/app_feedback_dialog.dart';
import '../../widgets/add_transaction_modal.dart';
import '../../core/api/pdf_upload_provider.dart';
import '../../app/theme.dart';

enum _GuideNextStepAction {
  dashboard,
  settings,
  stagedReview,
  addTransaction,
  uploadPdf,
}

typedef _GuideNextStep = ({
  IconData icon,
  String title,
  String message,
  _GuideNextStepAction action,
});

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with TickerProviderStateMixin {
  int index = 0;
  bool _hasCheckedFirstRunGuide = false;

  static const _guideSeenPrefix = 'guide_full_seen_';
  static const _guideSeenGlobalKey = 'guide_full_seen_global';
  static const _legacyGuideSeenPrefix = 'guide_seen_';
  static const _legacyGuideSeenGlobalKey = 'guide_seen_global';
  static const _guideNextTipsDatePrefix = 'guide_next_tips_date_';
  static const _guideNextTipsDateGlobalKey = 'guide_next_tips_date_global';

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFirstRunGuide();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowFirstRunGuide() async {
    if (!mounted || _hasCheckedFirstRunGuide) return;

    final authState = ref.read(authProvider).state;
    if (!authState.isLoggedIn || !authState.isOnboarded) return;

    final userKey = _normalizedGuideUserKey(
      authState.userId,
      authState.userEmail,
    );
    final storageKey = userKey == null
        ? _guideSeenGlobalKey
        : '$_guideSeenPrefix$userKey';

    // Now mark as checked so we don't double-trigger if we wait
    _hasCheckedFirstRunGuide = true;

    final hasSeen = await SecureStorage.readString(storageKey);
    final hasSeenGlobal = await SecureStorage.readString(_guideSeenGlobalKey);
    final hasSeenLegacy = await SecureStorage.readString(
      userKey == null
          ? _legacyGuideSeenGlobalKey
          : '$_legacyGuideSeenPrefix$userKey',
    );
    final hasSeenLegacyGlobal = await SecureStorage.readString(
      _legacyGuideSeenGlobalKey,
    );

    final fullGuideSeen =
        hasSeen == 'true' ||
        hasSeenGlobal == 'true' ||
        hasSeenLegacy == 'true' ||
        hasSeenLegacyGlobal == 'true';

    if (!mounted) return;
    if (fullGuideSeen) {
      await _maybeShowNextStepGuide(authState, userKey);
      return;
    }

    await _showFirstRunGuide();
    await SecureStorage.writeString(storageKey, 'true');
    await SecureStorage.writeString(_guideSeenGlobalKey, 'true');
  }

  Future<void> _maybeShowNextStepGuide(
    AuthState authState,
    String? userKey,
  ) async {
    final tipsDateKey = userKey == null
        ? _guideNextTipsDateGlobalKey
        : '$_guideNextTipsDatePrefix$userKey';
    final today = DateTime.now().toIso8601String().split('T').first;
    final lastShown = await SecureStorage.readString(tipsDateKey);
    if (lastShown == today) return;

    final recommendations = _buildNextStepRecommendations(authState);
    if (recommendations.isEmpty) return;

    await _showNextStepGuide(recommendations.take(2).toList());
    await SecureStorage.writeString(tipsDateKey, today);
  }

  List<_GuideNextStep> _buildNextStepRecommendations(AuthState authState) {
    final tips = <_GuideNextStep>[];

    final incomeCategories = authState.effectiveIncomeCategories;
    final expenseCategories = authState.effectiveExpenseCategories;
    if (incomeCategories.isEmpty || expenseCategories.isEmpty) {
      tips.add((
        icon: Icons.category_rounded,
        title: 'Complete your categories',
        message:
            'Set both income and expense categories so transactions are classified cleanly.',
        action: _GuideNextStepAction.settings,
      ));
    }

    if (TransactionRepository.currentTransactions.isEmpty) {
      tips.add((
        icon: Icons.add_chart_rounded,
        title: 'Add your first transaction',
        message: 'Start with one manual entry from the + button on Dashboard.',
        action: _GuideNextStepAction.addTransaction,
      ));
    }

    if (StagedDraftRepository.currentDrafts.isNotEmpty) {
      tips.add((
        icon: Icons.fact_check_rounded,
        title: 'Review staged rows',
        message:
            '${StagedDraftRepository.currentDrafts.length} staged transaction(s) are waiting for confirmation.',
        action: _GuideNextStepAction.stagedReview,
      ));
    } else {
      tips.add((
        icon: Icons.picture_as_pdf_rounded,
        title: 'Try PDF upload',
        message:
            'Upload a bank statement PDF and review extracted rows before confirming.',
        action: _GuideNextStepAction.uploadPdf,
      ));
    }

    return tips;
  }

  Future<void> _showNextStepGuide(List<_GuideNextStep> tips) async {
    if (!mounted || tips.isEmpty) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('What to do next'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tips
                .map(
                  (tip) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            tip.icon,
                            color: colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tip.message,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _openNextStep(tip.action);
                                  },
                                  child: const Text('Open'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNextStep(_GuideNextStepAction action) async {
    if (!mounted) return;
    switch (action) {
      case _GuideNextStepAction.dashboard:
        setState(() => index = 0);
        return;
      case _GuideNextStepAction.settings:
        setState(() => index = 3);
        return;
      case _GuideNextStepAction.stagedReview:
        setState(() => index = 0);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StagedReviewScreen()),
        );
        return;
      case _GuideNextStepAction.addTransaction:
        setState(() => index = 0);
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => AddTransactionModal(onSaved: () {}),
        );
        return;
      case _GuideNextStepAction.uploadPdf:
        setState(() => index = 0);
        ref.read(pdfUploadProvider.notifier).pickAndUpload();
        return;
    }
  }

  String? _normalizedGuideUserKey(String? userId, String? userEmail) {
    final id = userId?.trim();
    if (id != null && id.isNotEmpty) return id.toLowerCase();

    final email = userEmail?.trim();
    if (email != null && email.isNotEmpty) return email.toLowerCase();

    return null;
  }

  Future<void> _showFirstRunGuide() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final steps = <({IconData icon, String title, String message, String cta})>[
      (
        icon: Icons.waving_hand_rounded,
        title: 'Welcome to My Expenses',
        message:
            'This walkthrough will guide you page-by-page so you can confidently use every core feature.',
        cta: 'Next',
      ),
      (
        icon: Icons.dashboard_rounded,
        title: 'Dashboard page',
        message:
            'See monthly summaries, add transactions, upload bank PDF, and review staged rows before final confirmation.',
        cta: 'Next',
      ),
      (
        icon: Icons.history_rounded,
        title: 'History page',
        message:
            'Filter by type/month/category, search by notes, edit existing records, and delete unwanted items with swipe.',
        cta: 'Next',
      ),
      (
        icon: Icons.bar_chart_rounded,
        title: 'Analytics page',
        message:
            'View balance overview, category drill-down, and 6-month trend analysis.',
        cta: 'Next',
      ),
      (
        icon: Icons.settings_rounded,
        title: 'Settings page',
        message:
            'Manage profile, categories, currency, budget goals, recurring transactions, export data, and app lock.',
        cta: 'Next',
      ),
      (
        icon: Icons.flag_rounded,
        title: 'Recommended first steps',
        message:
            '1) Set your currency.\n'
            '2) Add or edit income/expense categories.\n'
            '3) Add your first transaction from the + button.',
        cta: 'Next',
      ),
      (
        icon: Icons.picture_as_pdf_rounded,
        title: 'PDF upload + staged review',
        message:
            'Upload your bank PDF from Dashboard, then review staged rows carefully.\n\n'
            'Only rows with BOTH Type and Category set are confirmed.',
        cta: 'Next',
      ),
      (
        icon: Icons.cloud_sync_rounded,
        title: 'You are ready',
        message:
            'Changes appear instantly and sync in the background.\n'
            'If the sync badge shows pending items, tap the cloud icon.',
        cta: 'OK',
      ),
    ];

    var currentStep = 0;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Guide',
      barrierColor: colorScheme.scrim.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final step = steps[currentStep];
            final isFirst = currentStep == 0;
            final isLast = currentStep == steps.length - 1;
            final dialogTheme = Theme.of(dialogContext);
            final dialogColorScheme = dialogTheme.colorScheme;

            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Material(
                      color: dialogColorScheme.surface,
                      elevation: 18,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: dialogColorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Getting Started • Step ${currentStep + 1}/${steps.length}',
                                    style: dialogTheme.textTheme.titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: dialogColorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Skip'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (currentStep + 1) / steps.length,
                                minHeight: 6,
                                backgroundColor:
                                    dialogColorScheme.surfaceContainerHighest,
                                color: dialogColorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: const Offset(0.05, 0),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOut,
                                            ),
                                          ),
                                      child: child,
                                    ),
                                  ),
                              child: Container(
                                key: ValueKey(currentStep),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: dialogColorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            dialogColorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        step.icon,
                                        color: dialogColorScheme
                                            .onPrimaryContainer,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            step.title,
                                            style: dialogTheme
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: dialogColorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            step.message,
                                            style: dialogTheme
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  height: 1.45,
                                                  color: dialogColorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (!isFirst)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => currentStep--),
                                      child: const Text('Back'),
                                    ),
                                  ),
                                if (!isFirst) const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton(
                                    onPressed: () {
                                      if (isLast) {
                                        Navigator.pop(dialogContext);
                                        return;
                                      }
                                      setState(() => currentStep++);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      foregroundColor: AppTheme.textDark,
                                    ),
                                    child: Text(
                                      step.cta,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  Future<void> _showCurrencyPicker() async {
    final currentCode = ref.read(authProvider).state.effectiveCurrency;
    final normalized = currentCode.trim().toUpperCase();
    var selectedCurrency = supportedCurrencies.any((c) => c.code == normalized)
        ? normalized
        : supportedCurrencies.first.code;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Change Currency'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCurrency,
            decoration: const InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(),
            ),
            items: supportedCurrencies
                .map(
                  (currency) => DropdownMenuItem<String>(
                    value: currency.code,
                    child: Text(currency.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedCurrency = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final authProv = ref.read(authProvider);
                try {
                  await authProv.updateCurrency(selectedCurrency);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  await showAppFeedbackDialog(
                    dialogContext,
                    title: 'Update Failed',
                    message: '$e',
                    type: AppFeedbackType.error,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    try {
      await TransactionRepository.syncPendingOperations();
      if (!mounted) return;
      final pending = TransactionRepository.pendingOutboxCount;
      await showAppFeedbackDialog(
        context,
        title: pending == 0 ? 'Synced' : 'Sync Pending',
        message: pending == 0
            ? 'All pending changes are synced.'
            : '$pending change(s) are still pending and will retry automatically.',
        type: pending == 0 ? AppFeedbackType.success : AppFeedbackType.error,
      );
    } catch (e) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Sync Failed',
        message: '$e',
        type: AppFeedbackType.error,
      );
    }
  }

  final _pages = const [
    DashboardScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
    SettingsPage(),
  ];

  final _titles = ['', 'History', 'Analytics', 'Settings'];

  @override
  Widget build(BuildContext context) {
    _listenToPdfUploads();
    final isDark = ref.watch(themeProvider).mode == ThemeMode.dark;
    final currency = ref.watch(authProvider).state.effectiveCurrency;
    final currencyOption = currencyFromCode(currency);
    final theme = Theme.of(context);

    final bottomBarColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFDFCF2);
    final bottomBarIconSelected = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.textDark;
    final bottomBarIconUnselected = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.textSoft;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.cream,
        leadingWidth: index == 0 ? 200 : null,
        leading: index == 0
            ? InkWell(
                onTap: _showCurrencyPicker,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_exchange_rounded,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textDark,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${currencyOption.symbol} ${currencyOption.name}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        title: _titles[index].isEmpty
            ? null
            : Text(
                _titles[index],
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          // Sync button only
          StreamBuilder<int>(
            stream: TransactionRepository.getOutboxCountStream(),
            initialData: TransactionRepository.pendingOutboxCount,
            builder: (context, pendingSnap) {
              final pending = pendingSnap.data ?? 0;
              return StreamBuilder<bool>(
                stream: TransactionRepository.getSyncingStream(),
                initialData: TransactionRepository.isSyncing,
                builder: (context, syncingSnap) {
                  final syncing = syncingSnap.data ?? false;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        tooltip: syncing
                            ? 'Syncing...'
                            : 'Sync now ($pending pending)',
                        onPressed: syncing ? null : _syncNow,
                        icon: Icon(
                          syncing
                              ? Icons.sync_rounded
                              : Icons.cloud_upload_outlined,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textDark,
                        ),
                      ),
                      if (!syncing && pending > 0)
                        Positioned(
                          right: 6,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              pending > 99 ? '99+' : '$pending',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(index), child: _pages[index]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () => _showAddMenu(context),
          backgroundColor: AppTheme.accent,
          foregroundColor: AppTheme.textDark,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: bottomBarColor,
        elevation: 8,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.08),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              0,
              Icons.dashboard_rounded,
              'Home',
              selected: bottomBarIconSelected,
              unselected: bottomBarIconUnselected,
            ),
            _buildNavItem(
              1,
              Icons.history_rounded,
              'History',
              selected: bottomBarIconSelected,
              unselected: bottomBarIconUnselected,
            ),
            const SizedBox(width: 40),
            _buildNavItem(
              2,
              Icons.bar_chart_rounded,
              'Analytics',
              selected: bottomBarIconSelected,
              unselected: bottomBarIconUnselected,
            ),
            _buildNavItem(
              3,
              Icons.settings_rounded,
              'Settings',
              selected: bottomBarIconSelected,
              unselected: bottomBarIconUnselected,
            ),
          ],
        ),
      ),
    );
  }

  void _listenToPdfUploads() {
    ref.listen(pdfUploadProvider, (previous, next) async {
      if (next.isUploading) return;
      if (next.error != null) {
        await showAppFeedbackDialog(
          context,
          title: 'Upload Error',
          message: next.error!,
          type: AppFeedbackType.error,
        );
      } else if (next.lastExtracted != null) {
        await showAppFeedbackDialog(
          context,
          title: 'Upload Successful',
          message: next.lastExtracted!.isEmpty
              ? 'No transactions were found in that PDF.'
              : 'Extracted ${next.lastExtracted!.length} transactions. Review them in the staging area.',
          type: next.lastExtracted!.isEmpty
              ? AppFeedbackType.error
              : AppFeedbackType.success,
        );

        if (!mounted) return;
        if (next.lastExtracted!.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StagedReviewScreen()),
          );
        }
      }
    });
  }

  Widget _buildNavItem(
    int itemIndex,
    IconData icon,
    String label, {
    required Color selected,
    required Color unselected,
  }) {
    final isSelected = index == itemIndex;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index != itemIndex) {
            setState(() => index = itemIndex);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: isSelected
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? selected : unselected,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? selected : unselected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMenuAction(
                    context,
                    icon: Icons.edit_note_rounded,
                    label: 'Manual Entry',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => AddTransactionModal(onSaved: () {}),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMenuAction(
                    context,
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Upload PDF',
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(pdfUploadProvider.notifier).pickAndUpload();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
