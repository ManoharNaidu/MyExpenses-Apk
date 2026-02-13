import 'package:flutter/material.dart';
import 'login_form.dart';
import 'register_form.dart';
import '../../app/theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Image.asset(
                      "assets/icon/icon_classy.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App Title
                const Text(
                  "My Expenses",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Track your spending, save more",
                  style: TextStyle(fontSize: 14, color: AppTheme.textSoft),
                ),
                const SizedBox(height: 40),

                // Tab Selector
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isLogin
                                  ? AppTheme.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Login",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isLogin
                                    ? Colors.white
                                    : AppTheme.textSoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !isLogin
                                  ? AppTheme.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Register",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: !isLogin
                                    ? Colors.white
                                    : AppTheme.textSoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form
                isLogin ? const LoginForm() : const RegisterForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
