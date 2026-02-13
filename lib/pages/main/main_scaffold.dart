import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/analytics_screen.dart';
import 'settings_page.dart';
import '../../data/transaction_repository.dart';
import '../../utils/csv_export.dart';

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

  Future<void> _openProfileMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Settings'),
                subtitle: const Text('Open profile and account settings'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx, 'settings'),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6_rounded),
                title: const Text('Toggle Dark / Light mode'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx, 'theme'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    if (selected == 'settings') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );
      return;
    }

    if (selected == 'theme') {
      await context.read<ThemeProvider>().toggleTheme();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme updated')),
      );
    }
  }

  Future<void> _exportTransactions() async {
    try {
      final txs = await TransactionRepository.fetchAll();
      if (!mounted) return;

      if (txs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No transactions to export")),
        );
        return;
      }

      final result = await CsvExport.exportTransactions(txs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.openedShareSheet
                ? "Export ready. Choose where to save/share the CSV."
                : "Export started successfully",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: index == 0
            ? [
                // Export CSV button only on Dashboard
                IconButton(
                  tooltip: "Export CSV",
                  onPressed: _exportTransactions,
                  icon: const Icon(Icons.download_rounded),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: _openProfileMenu,
                  icon: const Icon(Icons.account_circle_rounded),
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
