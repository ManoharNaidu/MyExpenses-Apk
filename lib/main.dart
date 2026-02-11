import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/auth/auth_provider.dart';
import 'pages/router/root_router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const MyExpensesApp());
}

class MyExpensesApp extends StatelessWidget {
  const MyExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadSession(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Expenses',
        theme: AppTheme.theme,
        home: const RootRouter(),
      ),
    );
  }
}
