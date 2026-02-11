import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/auth/auth_provider.dart';
import '../../app/theme.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Categories",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Choose your expense categories",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select at least one category to continue",
              style: TextStyle(fontSize: 14, color: AppTheme.textSoft),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: predefinedCategories.map((cat) {
                    final isSelected = selected.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          val ? selected.add(cat) : selected.remove(cat);
                        });
                      },
                      backgroundColor: AppTheme.card,
                      selectedColor: AppTheme.accent.withOpacity(0.2),
                      checkmarkColor: AppTheme.accentDark,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.accentDark
                            : AppTheme.textDark,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.accent
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selected count
            if (selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  "${selected.length} ${selected.length == 1 ? 'category' : 'categories'} selected",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        final categoriesList = selected.toList();
                        debugPrint("🎯 Selected categories: $categoriesList");
                        context.read<AuthProvider>().markOnboarded(
                          categories: categoriesList,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () {
                  context.read<AuthProvider>().markOnboarded();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Skip for now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
