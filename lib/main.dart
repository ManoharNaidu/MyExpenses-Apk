import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/auth/auth_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'pages/router/root_router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env only in debug builds — release builds use --dart-define for API_URL.
  // This also prevents a crash when .env is not bundled in release APKs.
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env not found — fine in release / CI builds
    }
  }

  runApp(const MyExpensesApp());
  unawaited(NotificationService.initialize());
}

class MyExpensesApp extends StatelessWidget {
  const MyExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = context.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'My Expenses',
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.mode,
            home: const RootRouter(),
          );
        },
      ),
    );
  }
}
