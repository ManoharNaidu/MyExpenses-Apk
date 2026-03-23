import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/currencies.dart';
import '../../core/storage/secure_storage.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'settings_page.dart';
import '../../data/transaction_repository.dart';
import '../../models/transaction_model.dart';
import '../../utils/csv_export.dart';
import '../../widgets/app_feedback_dialog.dart';
import '../../widgets/add_transaction_modal.dart';
import '../../core/api/pdf_upload_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int index = 0;
  bool _hasCheckedFirstRunGuide = false;

  static const _guideSeenPrefix = 'guide_seen_';

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFirstRunGuide();
    });
  }

  Future<void> _maybeShowFirstRunGuide() async {
    if (!mounted || _hasCheckedFirstRunGuide) return;
    _hasCheckedFirstRunGuide = true;

    final authState = ref.read(authProvider).state;
    if (!authState.isLoggedIn || !authState.isOnboarded) return;

    final userKey = (authState.userId ?? authState.userEmail ?? 'user').trim();
    final storageKey = '$_guideSeenPrefix$userKey';
    final hasSeen = await SecureStorage.readString(storageKey);

    if (!mounted || hasSeen == 'true') return;

    await _showFirstRunGuide();
    await SecureStorage.writeString(storageKey, 'true');
  }

  Future<void> _showFirstRunGuide() async {
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
            'See weekly/monthly summaries, add transactions, upload bank PDF, and review staged rows before final confirmation.',
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
            'View weekly and monthly trends for income vs expense. This helps identify spending patterns quickly.',
        cta: 'Next',
      ),
      (
        icon: Icons.settings_rounded,
        title: 'Settings page',
        message:
            'Manage profile, categories, currency, newcomer guide, budget goals, recurring transactions, and app lock preferences.',
        cta: 'Next',
      ),
      (
        icon: Icons.flag_rounded,
        title: 'Recommended first steps',
        message:
            '1) Set your currency.\n'
            '2) Add or edit income/expense categories.\n'
            '3) Add your first transaction from the Add button.',
        cta: 'Next',
      ),
      (
        icon: Icons.picture_as_pdf_rounded,
        title: 'PDF upload + staged review',
        message:
            'Upload your bank PDF from Dashboard, then review staged rows carefully.\n\n'
            'Important rule: only selected rows with BOTH Type and Category are queued for confirmation.',
        cta: 'Next',
      ),
      (
        icon: Icons.cloud_sync_rounded,
        title: 'You are ready',
        message:
            'Add/edit/delete updates appear instantly in the app.\n'
            'Changes are synced in background, or manually via cloud icon.\n'
            'If pending count is above 0, tap Sync now.',
        cta: 'OK',
      ),
    ];

    var currentStep = 0;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Guide',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final step = steps[currentStep];
            final isFirst = currentStep == 0;
            final isLast = currentStep == steps.length - 1;

            return SafeArea(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Getting Started • Step ${currentStep + 1}/${steps.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: (currentStep + 1) / steps.length,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(dialogContext).colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(step.icon, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      step.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      step.message,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Row(
                          children: [
                            if (!isFirst)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                  ),
                                  child: const Text('Back'),
                                ),
                              ),
                            if (!isFirst) const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  if (isLast) {
                                    Navigator.pop(dialogContext);
                                    return;
                                  }
                                  setState(() => currentStep++);
                                },
                                child: Text(step.cta),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 8,
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
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
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
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

  Future<void> _exportTransactions() async {
    try {
      final txs = await TransactionRepository.fetchAll();
      if (!mounted) return;

      if (txs.isEmpty) {
        await showAppFeedbackDialog(
          context,
          title: 'No Data',
          message: 'No transactions to export.',
          type: AppFeedbackType.error,
        );
        return;
      }

      final DateTime? rangeStart;
      final DateTime? rangeEnd;
      final useRange = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export transactions'),
          content: const Text(
            'Export all transactions, or choose a date range to export only a subset.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Export all'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Choose date range'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (useRange == true) {
        final now = DateTime.now();
        final start = await showDatePicker(
          context: context,
          initialDate: now.subtract(const Duration(days: 30)),
          firstDate: DateTime(2020),
          lastDate: now,
        );
        if (!mounted || start == null) return;
        final end = await showDatePicker(
          context: context,
          initialDate: now.isAfter(start) ? now : start,
          firstDate: start,
          lastDate: DateTime(2030),
        );
        if (!mounted || end == null) return;
        rangeStart = start;
        rangeEnd = end;
      } else {
        rangeStart = null;
        rangeEnd = null;
      }

      List<TransactionModel> toExport = txs;
      if (rangeStart != null && rangeEnd != null) {
        final startDay = DateTime(
          rangeStart.year,
          rangeStart.month,
          rangeStart.day,
        );
        final endDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
        toExport = txs.where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          return !d.isBefore(startDay) && !d.isAfter(endDay);
        }).toList();
        if (toExport.isEmpty) {
          await showAppFeedbackDialog(
            context,
            title: 'No data in range',
            message: 'No transactions fall within the selected date range.',
            type: AppFeedbackType.error,
          );
          return;
        }
      }

      final result = await CsvExport.exportTransactions(toExport);
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Export Ready',
        message: result.openedShareSheet
            ? 'Choose where to save/share the CSV file.'
            : 'Export started successfully.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      await showAppFeedbackDialog(
        context,
        title: 'Export Failed',
        message: '$e',
        type: AppFeedbackType.error,
      );
    }
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

  final pages = [
    const DashboardScreen(),
    const HistoryScreen(),
    const AnalyticsScreen(),
    const SettingsPage(),
  ];

  final titles = ["My Expenses", "History", "Analytics", "Settings"];

  @override
  Widget build(BuildContext context) {
    _listenToPdfUploads();
    final currency = ref.watch(authProvider).state.effectiveCurrency;
    final currencyOption = currencyFromCode(currency);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${currencyOption.symbol} ${currencyOption.name}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        title: Text(titles[index]),
        actions: index != 4
            ? [
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
                IconButton(
                  tooltip: "Export CSV",
                  onPressed: _exportTransactions,
                  icon: const Icon(Icons.download_rounded),
                ),
              ]
            : null,
      ),
      body: pages[index],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_rounded, "Home"),
            _buildNavItem(1, Icons.history_rounded, "History"),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(2, Icons.bar_chart_rounded, "Analytics"),
            _buildNavItem(3, Icons.settings_rounded, "Settings"),
          ],
        ),
      ),
    );
  }

  void _listenToPdfUploads() {
    ref.listen(pdfUploadProvider, (previous, next) {
      if (next.isUploading) return;
      if (next.error != null) {
        showAppFeedbackDialog(
          context,
          title: "Upload Error",
          message: next.error!,
          type: AppFeedbackType.error,
        );
      } else if (next.lastExtracted != null) {
        showAppFeedbackDialog(
          context,
          title: "Upload Successful",
          message: next.lastExtracted!.isEmpty
              ? "No transactions were found in that PDF."
              : "Extracted ${next.lastExtracted!.length} transactions. Review them in the staging area.",
          type: next.lastExtracted!.isEmpty ? AppFeedbackType.error : AppFeedbackType.success,
        );
      }
    });
  }

  Widget _buildNavItem(int itemIndex, IconData icon, String label) {
    final isSelected = index == itemIndex;
    final theme = Theme.of(context);
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => index = itemIndex),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Add Transaction",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMenuAction(
                    context,
                    icon: Icons.edit_note_rounded,
                    label: "Manual Entry",
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
                    label: "Upload PDF",
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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAppFeedbackDialog(
    BuildContext context, {
    required String title,
    required String message,
    required AppFeedbackType type,
  }) {
    return showAppFeedbackDialog(context, title: title, message: message, type: type);
  }
}
