import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/currencies.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/analytics_screen.dart';
import 'settings_page.dart';
import '../../data/transaction_repository.dart';
import '../../utils/csv_export.dart';
import '../../widgets/app_feedback_dialog.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    TransactionRepository.ensureInitialized();
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  Future<void> _showCurrencyPicker() async {
    final currentCode = context.read<AuthProvider>().state.effectiveCurrency;
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
                final authProvider = context.read<AuthProvider>();
                try {
                  await authProvider.updateCurrency(selectedCurrency);
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

      final result = await CsvExport.exportTransactions(txs);
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
  ];

  final titles = ["My Expenses", "History", "Analytics"];

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AuthProvider>().state.effectiveCurrency;
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
        actions: index == 0
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
                IconButton(
                  tooltip: 'Settings',
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_rounded),
                ),
              ]
            : null,
      ),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Analytics",
          ),
        ],
      ),
    );
  }
}
