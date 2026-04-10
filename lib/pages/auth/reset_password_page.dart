import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../app/theme.dart';
import '../../widgets/app_feedback_dialog.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider)
          .resetPassword(
            email: widget.email,
            otp: _codeController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (mounted) {
        await showAppFeedbackDialog(
          context,
          title: 'Password Reset',
          message:
              'Your password has been reset successfully. You can now login with your new password.',
          type: AppFeedbackType.success,
        );
        if (mounted) {
          // Pop all the way back to auth page
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        await showAppFeedbackDialog(
          context,
          title: 'Reset Failed',
          message: '$e',
          type: AppFeedbackType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.cream;
    final fieldFill = isDark ? AppTheme.darkField : AppTheme.card;
    final titleColor = isDark ? AppTheme.darkTextPri : AppTheme.textDark;
    final subtitleColor = isDark ? AppTheme.darkTextSec : AppTheme.textSoft;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.accent;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Enter the 6-digit code sent to\n${widget.email}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSoft,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Code field
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: titleColor,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: subtitleColor.withValues(alpha: 0.4),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: fieldFill,
                    ),
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return 'Enter the 6-digit code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      hintText: "Enter new password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: fieldFill,
                      prefixIconColor: subtitleColor,
                      suffixIconColor: subtitleColor,
                      labelStyle: TextStyle(color: subtitleColor),
                      hintStyle: TextStyle(
                        color: subtitleColor.withValues(alpha: 0.7),
                      ),
                    ),
                    style: TextStyle(color: titleColor),
                    cursorColor: accentColor,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      hintText: "Re-enter new password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: fieldFill,
                      prefixIconColor: subtitleColor,
                      suffixIconColor: subtitleColor,
                      labelStyle: TextStyle(color: subtitleColor),
                      hintStyle: TextStyle(
                        color: subtitleColor.withValues(alpha: 0.7),
                      ),
                    ),
                    style: TextStyle(color: titleColor),
                    cursorColor: accentColor,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Reset button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: titleColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.textDark,
                                ),
                              ),
                            )
                          : const Text(
                              "Reset Password",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
