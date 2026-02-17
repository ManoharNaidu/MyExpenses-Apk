import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/currencies.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../widgets/app_feedback_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationService.isEnabled();
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final userName = authProvider.state.userName ?? "User";
    final userEmail = authProvider.state.userEmail ?? "";
    final userIncomeCategories = authProvider.state.effectiveIncomeCategories;
    final userExpenseCategories = authProvider.state.effectiveExpenseCategories;
    final userCurrency = authProvider.state.effectiveCurrency;
    final userCurrencyOption = currencyFromCode(userCurrency);
    final userCategories = {
      ...userIncomeCategories,
      ...userExpenseCategories,
    }.toList();
    final isDarkMode = themeProvider.mode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (userCategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      "Your Categories (${userCategories.length})",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: userCategories
                          .map(
                            (cat) => Chip(
                              label: Text(cat),
                              backgroundColor: Colors.blue[50],
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text(
                    "Profile",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text("Change Name"),
                  subtitle: Text(userName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangeNameDialog(context, userName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text("Change Password"),
                  subtitle: const Text("••••••••"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.tune_rounded),
                  title: Text(
                    "Preferences",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.currency_exchange_outlined),
                  title: const Text("Change Currency"),
                  subtitle: Text(userCurrencyOption.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangeCurrencyDialog(
                    context,
                    userCurrencyOption.code,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text("Edit Categories"),
                  subtitle: Text(
                    "Income: ${userIncomeCategories.length} • Expense: ${userExpenseCategories.length}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEditCategoriesDialog(
                    context,
                    userIncomeCategories,
                    userExpenseCategories,
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Use dark appearance across the app"),
                  value: isDarkMode,
                  onChanged: (_) async {
                    await context.read<ThemeProvider>().toggleTheme();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text("Notifications"),
                  subtitle: const Text("Enable transaction notifications"),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    await NotificationService.setEnabled(value);
                    if (!mounted) return;
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.help_outline_rounded),
                  title: Text(
                    "Help & Feedback",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text("Send Feedback"),
                  subtitle: const Text("Tell us what can be improved"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSendFeedbackDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text("Getting Started"),
                  subtitle: const Text("Newcomer guide for first-time usage"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGettingStartedGuide(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text("Privacy"),
                  subtitle: const Text("How My Expenses handles your data"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrivacyInfo(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("About My Expenses"),
                  subtitle: const Text(
                    "App structure, architecture, and how it works",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutInfo(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.red[50],
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeCurrencyDialog(BuildContext context, String currentCurrency) {
    final normalized = currentCurrency.trim().toUpperCase();
    var selectedCurrency = supportedCurrencies.any((c) => c.code == normalized)
        ? normalized
        : supportedCurrencies.first.code;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Change Currency"),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCurrency,
            decoration: const InputDecoration(
              labelText: "Currency",
              border: OutlineInputBorder(),
            ),
            items: supportedCurrencies
                .map(
                  (currency) => DropdownMenuItem<String>(
                    value: currency.code,
                    child: Text(currency.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedCurrency = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final code = selectedCurrency;

                try {
                  await context.read<AuthProvider>().updateCurrency(code);
                  if (context.mounted) {
                    Navigator.pop(context);
                    await showAppFeedbackDialog(
                      context,
                      title: 'Success',
                      message: 'Currency updated to $code.',
                      type: AppFeedbackType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    await showAppFeedbackDialog(
                      context,
                      title: 'Update Failed',
                      message: '$e',
                      type: AppFeedbackType.error,
                    );
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeNameDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Name"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "New Name",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Name cannot be empty";
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await context.read<AuthProvider>().updateName(
                    nameController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    await showAppFeedbackDialog(
                      context,
                      title: 'Success',
                      message: 'Name updated successfully.',
                      type: AppFeedbackType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    await showAppFeedbackDialog(
                      context,
                      title: 'Update Failed',
                      message: '$e',
                      type: AppFeedbackType.error,
                    );
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: "Current Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter current password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter new password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm New Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await context.read<AuthProvider>().updatePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    await showAppFeedbackDialog(
                      context,
                      title: 'Success',
                      message: 'Password updated successfully.',
                      type: AppFeedbackType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    await showAppFeedbackDialog(
                      context,
                      title: 'Update Failed',
                      message: '$e',
                      type: AppFeedbackType.error,
                    );
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditCategoriesDialog(
    BuildContext context,
    List<String> currentIncomeCategories,
    List<String> currentExpenseCategories,
  ) {
    final incomeCtrl = TextEditingController();
    final expenseCtrl = TextEditingController();
    final selectedIncome = Set<String>.from(currentIncomeCategories);
    final selectedExpense = Set<String>.from(currentExpenseCategories);
    final incomeOptions = {
      ...predefinedIncomeCategories,
      ...currentIncomeCategories,
    }.toList();
    final expenseOptions = {
      ...predefinedExpenseCategories,
      ...currentExpenseCategories,
    }.toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Categories"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  "Income Categories",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...incomeOptions.map((category) {
                  final isSelected = selectedIncome.contains(category);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(category),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedIncome.add(category);
                        } else {
                          selectedIncome.remove(category);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: incomeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Add custom income category",
                        ),
                        onSubmitted: (_) {
                          final value = incomeCtrl.text.trim();
                          if (value.isEmpty) return;
                          setState(() {
                            if (!incomeOptions.contains(value)) {
                              incomeOptions.add(value);
                            }
                            selectedIncome.add(value);
                            incomeCtrl.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        final value = incomeCtrl.text.trim();
                        if (value.isEmpty) return;
                        setState(() {
                          if (!incomeOptions.contains(value)) {
                            incomeOptions.add(value);
                          }
                          selectedIncome.add(value);
                          incomeCtrl.clear();
                        });
                      },
                      icon: const Icon(Icons.add_circle_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Expense Categories",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...expenseOptions.map((category) {
                  final isSelected = selectedExpense.contains(category);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(category),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedExpense.add(category);
                        } else {
                          selectedExpense.remove(category);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expenseCtrl,
                        decoration: const InputDecoration(
                          labelText: "Add custom expense category",
                        ),
                        onSubmitted: (_) {
                          final value = expenseCtrl.text.trim();
                          if (value.isEmpty) return;
                          setState(() {
                            if (!expenseOptions.contains(value)) {
                              expenseOptions.add(value);
                            }
                            selectedExpense.add(value);
                            expenseCtrl.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        final value = expenseCtrl.text.trim();
                        if (value.isEmpty) return;
                        setState(() {
                          if (!expenseOptions.contains(value)) {
                            expenseOptions.add(value);
                          }
                          selectedExpense.add(value);
                          expenseCtrl.clear();
                        });
                      },
                      icon: const Icon(Icons.add_circle_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: (selectedIncome.isEmpty && selectedExpense.isEmpty)
                  ? null
                  : () async {
                      try {
                        await context.read<AuthProvider>().updateCategories(
                          incomeCategories: selectedIncome.toList(),
                          expenseCategories: selectedExpense.toList(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          await showAppFeedbackDialog(
                            context,
                            title: 'Success',
                            message:
                                'Income & expense categories updated successfully.',
                            type: AppFeedbackType.success,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          await showAppFeedbackDialog(
                            context,
                            title: 'Update Failed',
                            message: '$e',
                            type: AppFeedbackType.error,
                          );
                        }
                      }
                    },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      incomeCtrl.dispose();
      expenseCtrl.dispose();
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _showSendFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Send Feedback"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: feedbackController,
              maxLines: 4,
              enabled: !isSubmitting,
              decoration: const InputDecoration(
                hintText: "Share your feedback or report an issue...",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter feedback";
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isSubmitting = true);
                      try {
                        await context.read<AuthProvider>().submitFeedback(
                          feedbackController.text,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await showAppFeedbackDialog(
                          dialogContext,
                          title: 'Thanks for your feedback',
                          message: 'Your feedback was submitted successfully.',
                          type: AppFeedbackType.success,
                        );
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        await showAppFeedbackDialog(
                          dialogContext,
                          title: 'Submission Failed',
                          message: '$e',
                          type: AppFeedbackType.error,
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: Text(isSubmitting ? "Submitting..." : "Submit"),
            ),
          ],
        ),
      ),
    ).whenComplete(() => feedbackController.dispose());
  }

  void _showGettingStartedGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Getting Started",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "New to My Expenses? Follow this quick guide to set things up right and avoid common confusion.",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 14),
                  Text(
                    "What each tab does",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Dashboard: weekly/monthly summaries, add transaction, upload bank PDF, review staged transactions, and top-bar tools (currency/sync/export/settings).\n"
                    "• History: full transaction list with filters (type, month, category), edit, delete, and load-more scrolling.\n"
                    "• Analytics: weekly/monthly bars comparing Income vs Expense trends.\n"
                    "• Settings: profile, password, categories, currency, notifications, and app info.",
                  ),
                  SizedBox(height: 14),
                  Text(
                    "First 5 actions for a new user",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "1) Set your currency from Dashboard header or Settings.\n"
                    "2) Add/adjust income and expense categories in Settings.\n"
                    "3) Add your first transaction with the Add button.\n"
                    "4) Upload a bank PDF, then review staged rows carefully.\n"
                    "5) If pending count is shown on cloud icon, tap Sync now.",
                  ),
                  SizedBox(height: 14),
                  Text(
                    "Staged review rules (important)",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Staged rows should be reviewed row-by-row before confirm.\n"
                    "• A row is only valid when both Type and Category are set.\n"
                    "• Confirm sends only complete selected rows.\n"
                    "• Confirmed rows are queued first, then synced when possible.",
                  ),
                  SizedBox(height: 14),
                  Text(
                    "Local-first behavior",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Add/Edit/Delete actions update local app state instantly for responsive UX.\n"
                    "• Sync runs in background and can also be triggered manually via cloud icon.\n"
                    "• If network/API is unavailable, pending operations stay queued and retry later.",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Privacy in My Expenses",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "We aim to keep privacy simple and transparent.",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "1) What we store\n"
                    "• Account details: your name, email, and preferences (like currency and categories).\n"
                    "• Financial records: your transactions and categories you create.\n"
                    "• Optional upload data: PDF statements you choose to upload for transaction extraction.",
                  ),
                  SizedBox(height: 12),
                  Text(
                    "2) Why we store it\n"
                    "• To show your dashboard/history accurately.\n"
                    "• To provide features like filtering, analytics, export, and statement processing.\n"
                    "• To personalize the app with your selected categories and settings.",
                  ),
                  SizedBox(height: 12),
                  Text(
                    "3) Your control\n"
                    "• You can edit profile details, categories, and currency from Settings.\n"
                    "• You can add, edit, or delete transactions.\n"
                    "• You can log out anytime.",
                  ),
                  SizedBox(height: 12),
                  Text(
                    "4) Notifications\n"
                    "• Notifications are optional and can be turned on/off from Settings.",
                  ),
                  SizedBox(height: 12),
                  Text(
                    "5) Data sharing\n"
                    "• Exporting data (CSV) only happens when you explicitly choose Export.\n"
                    "• Uploaded files are sent only when you tap upload.",
                  ),
                  SizedBox(height: 16),
                  Text(
                    "If you want stricter controls (like delete account/data request), we can add dedicated actions in Settings.",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About My Expenses",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "My Expenses is a personal finance app built to make money tracking clear and practical.",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Core features\n"
                    "• Add, edit, delete single transactions\n"
                    "• Filter and review transaction history\n"
                    "• Upload bank PDF and review extracted staged transactions\n"
                    "• Export transactions to Excel/CSV\n"
                    "• Manage account settings, categories, currency, and notifications",
                  ),
                  SizedBox(height: 12),
                  Text(
                    "How the app is structured (simple view)\n"
                    "• Auth: login/register and onboarding\n"
                    "• Dashboard: current summaries + PDF upload flow\n"
                    "• History: past transactions with filtering\n"
                    "• Analytics: trend and summary charts\n"
                    "• Settings: profile, password, categories, currency, notifications",
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Technical architecture (transparent)\n"
                    "• UI layer: Flutter pages/widgets\n"
                    "• State layer: provider-based app/auth/theme state\n"
                    "• Data layer: repository + API client + secure/local storage\n"
                    "• This separation keeps the app easier to maintain and safer to evolve.",
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Design goal\n"
                    "• Keep things understandable for everyday users: clear actions, plain language, and predictable behavior.",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
