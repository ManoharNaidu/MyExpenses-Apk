import 'package:flutter/material.dart';
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

      await CsvExport.exportTransactions(txs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Export started successfully")),
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
    const SettingsPage(),
  ];

  final titles = ["My Expenses", "History", "Analytics", "Settings"];

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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
