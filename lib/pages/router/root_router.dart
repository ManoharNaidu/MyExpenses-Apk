import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../auth/auth_page.dart';
import '../onboarding/category_selection_page.dart';
import '../main/main_scaffold.dart';

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>().state;
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) return const AuthPage();
    if (!auth.isOnboarded) return const CategorySelectionPage();
    return const MainScaffold();
  }
}
