import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/security/app_lock_service.dart';
import 'main_scaffold.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _unlocking = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final auth = ref.read(authProvider).state;
    if (!auth.appLockEnabled || !auth.appLockUseBiometric) return;

    final ok = await AppLockService.authenticateWithBiometric();
    if (!mounted) return;
    if (ok) setState(() => _unlocked = true);
  }

  Future<void> _unlockWithPin() async {
    final auth = ref.read(authProvider).state;
    final entered = _pinController.text.trim();
    if (entered.length < 4) {
      setState(() => _error = 'Enter a valid PIN');
      return;
    }

    setState(() {
      _unlocking = true;
      _error = null;
    });

    final ok = AppLockService.verifyPin(
      enteredPin: entered,
      storedHash: auth.appLockPinHash,
    );

    if (!mounted) return;
    setState(() {
      _unlocking = false;
      if (ok) {
        _unlocked = true;
      } else {
        _error = 'Incorrect PIN';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const MainScaffold();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 36),
                    const SizedBox(height: 10),
                    const Text(
                      'App Locked',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Enter your PIN or use biometric to continue.'),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        errorText: _error,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _unlockWithPin(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _tryBiometric,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Biometric'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _unlocking ? null : _unlockWithPin,
                            child: Text(_unlocking ? 'Unlocking...' : 'Unlock'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
