import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/categories.dart';
import '../../core/notifications/notification_service.dart';
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
    final userName = authProvider.state.userName ?? "User";
    final userEmail = authProvider.state.userEmail ?? "";
    final userIncomeCategories = authProvider.state.effectiveIncomeCategories;
    final userExpenseCategories = authProvider.state.effectiveExpenseCategories;
    final userCurrency = authProvider.state.effectiveCurrency;
    final userCategories = {...userIncomeCategories, ...userExpenseCategories}.toList();

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
                ListTile(
                  leading: const Icon(Icons.currency_exchange_outlined),
                  title: const Text("Change Currency"),
                  subtitle: Text(userCurrency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangeCurrencyDialog(context, userCurrency),
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
    final currencyController = TextEditingController(text: currentCurrency);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Currency"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: currencyController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            decoration: const InputDecoration(
              labelText: "Currency Code",
              hintText: "e.g. AUD, USD, INR",
              border: OutlineInputBorder(),
              counterText: "",
            ),
            validator: (value) {
              final code = (value ?? '').trim().toUpperCase();
              if (code.isEmpty) {
                return "Currency is required";
              }
              if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
                return "Use a valid 3-letter currency code";
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
              if (!formKey.currentState!.validate()) return;
              final code = currencyController.text.trim().toUpperCase();

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
    ).whenComplete(currencyController.dispose);
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
                  if (value == null || value.isEmpty) return "Enter current password";
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
                  if (value == null || value.isEmpty) return "Enter new password";
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
                  if (value != newPasswordController.text) return "Passwords do not match";
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
}