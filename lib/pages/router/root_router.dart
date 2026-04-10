import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../auth/auth_page.dart';
import '../onboarding/onboarding_wizard.dart';
import '../main/main_scaffold.dart';
import '../main/app_lock_gate.dart';

class RootRouter extends ConsumerWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).state;
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) return const AuthPage();
    if (!auth.isOnboarded) return const OnboardingWizard();
    if (auth.appLockEnabled) return const AppLockGate();
    return const MainScaffold();
  }
}
