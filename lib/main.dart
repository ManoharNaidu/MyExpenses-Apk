import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/notifications/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'pages/router/root_router.dart';
import 'services/weekly_digest_service.dart';

const _appFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  tz.initializeTimeZones();

  runApp(const ProviderScope(child: MyExpensesApp()));
  unawaited(NotificationService.initialize());
  unawaited(WeeklyDigestService.initialize());
}

Future<void> _loadEnv() async {
  final candidates = <String>[
    '.env.$_appFlavor',
    '.env',
    '.env.example',
  ];

  for (final fileName in candidates) {
    try {
      await dotenv.load(fileName: fileName);
      return;
    } catch (_) {
      // Keep trying fallback env files.
    }
  }
}

class MyExpensesApp extends ConsumerWidget {
  const MyExpensesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProv = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Expenses',
      theme: themeProv.lightTheme,
      darkTheme: themeProv.darkTheme,
      themeMode: themeProv.mode,
      home: const RootRouter(),
    );
  }
}
