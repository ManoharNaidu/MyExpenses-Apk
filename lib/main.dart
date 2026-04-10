import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/notifications/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'pages/router/root_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  debugPrint('ENV LOADED: ${dotenv.env}');
  // debugPrint('RESOLVED BASE URL: ${ApiClient.baseUrl}');

  runApp(const ProviderScope(child: MyExpensesApp()));
  unawaited(NotificationService.initialize());
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
