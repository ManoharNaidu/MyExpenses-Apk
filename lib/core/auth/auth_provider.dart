import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../storage/secure_storage.dart';
import 'auth_state.dart';
import '../../data/transaction_repository.dart';
import '../../data/staged_draft_repository.dart';

class AuthProvider extends ChangeNotifier {
  static const _profileKey = 'auth_profile';

  AuthState _state = AuthState.initial();
  AuthState get state => _state;

  List<String> _toStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return <String>[];
  }

  ({List<String> income, List<String> expense}) _extractCategories(
    Map<String, dynamic> data,
  ) {
    final userCategoriesRaw = data['user_categories'];
    if (userCategoriesRaw is List) {
      final income = <String>[];
      final expense = <String>[];

      for (final item in userCategoriesRaw) {
        if (item is! Map) continue;
        final type = item['type']?.toString().toLowerCase().trim();
        final category = item['category']?.toString().trim();
        if (category == null || category.isEmpty) continue;

        if (type == 'income') {
          income.add(category);
        } else if (type == 'expense') {
          expense.add(category);
        }
      }

      return (income: income, expense: expense);
    }

    // Some backends return categories as an object:
    // { income_categories: [...], expense_categories: [...] }
    final categoriesRaw = data['categories'];
    if (categoriesRaw is Map) {
      final income = _toStringList(categoriesRaw['income_categories']);
      final expense = _toStringList(categoriesRaw['expense_categories']);
      if (income.isNotEmpty || expense.isNotEmpty) {
        return (income: income, expense: expense);
      }
    }

    // Some backends return categories as [{income_category, expense_category}].
    if (categoriesRaw is List) {
      final income = <String>[];
      final expense = <String>[];

      for (final item in categoriesRaw) {
        if (item is! Map) continue;
        final incomeCategory = item['income_category']?.toString().trim();
        final expenseCategory = item['expense_category']?.toString().trim();

        if (incomeCategory != null && incomeCategory.isNotEmpty) {
          income.add(incomeCategory);
        }
        if (expenseCategory != null && expenseCategory.isNotEmpty) {
          expense.add(expenseCategory);
        }
      }

      if (income.isNotEmpty || expense.isNotEmpty) {
        return (income: income, expense: expense);
      }
    }

    // Backward compatibility with older API response fields.
    final incomeCategories = _toStringList(
      data['income_category'] ?? data['income_categories'],
    );
    final expenseCategories = _toStringList(
      data['expense_cateogry'] ?? data['expense_categories'],
    );

    return (income: incomeCategories, expense: expenseCategories);
  }

  List<Map<String, String>> _buildUserCategoriesPayload({
    required List<String> incomeCategories,
    required List<String> expenseCategories,
  }) {
    final income = incomeCategories
        .where((c) => c.trim().isNotEmpty)
        .map((c) => {'type': 'income', 'category': c.trim()});
    final expense = expenseCategories
        .where((c) => c.trim().isNotEmpty)
        .map((c) => {'type': 'expense', 'category': c.trim()});

    return [...income, ...expense];
  }

  List<Map<String, String?>> _buildCategoryPairsPayload({
    required List<String> incomeCategories,
    required List<String> expenseCategories,
  }) {
    return List.generate(
      math.max(incomeCategories.length, expenseCategories.length),
      (index) => {
        'income_category': index < incomeCategories.length
            ? incomeCategories[index].trim()
            : null,
        'expense_category': index < expenseCategories.length
            ? expenseCategories[index].trim()
            : null,
      },
    );
  }

  AuthState _copyState({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isOnboarded,
    String? userId,
    String? userEmail,
    String? userName,
    List<String>? userCategories,
    List<String>? userIncomeCategories,
    List<String>? userExpenseCategories,
    String? userCurrency,
  }) {
    return AuthState(
      isLoading: isLoading ?? _state.isLoading,
      isLoggedIn: isLoggedIn ?? _state.isLoggedIn,
      isOnboarded: isOnboarded ?? _state.isOnboarded,
      userId: userId ?? _state.userId,
      userEmail: userEmail ?? _state.userEmail,
      userName: userName ?? _state.userName,
      userCategories: userCategories ?? _state.userCategories,
      userIncomeCategories: userIncomeCategories ?? _state.userIncomeCategories,
      userExpenseCategories:
          userExpenseCategories ?? _state.userExpenseCategories,
      userCurrency: userCurrency ?? _state.userCurrency,
    );
  }

  Future<void> _saveProfileCache() async {
    final userCategories = _buildUserCategoriesPayload(
      incomeCategories: _state.userIncomeCategories ?? <String>[],
      expenseCategories: _state.userExpenseCategories ?? <String>[],
    );

    final payload = {
      'is_onboarded': _state.isOnboarded,
      'id': _state.userId,
      'email': _state.userEmail,
      'name': _state.userName,
      'currency': _state.userCurrency,
      'user_categories': userCategories,
      'categories': _state.userCategories ?? <String>[],
      'income_category': _state.userIncomeCategories ?? <String>[],
      'expense_cateogry': _state.userExpenseCategories ?? <String>[],
    };
    await SecureStorage.writeString(_profileKey, jsonEncode(payload));
  }

  Future<bool> _restoreProfileCache() async {
    final raw = await SecureStorage.readString(_profileKey);
    if (raw == null || raw.isEmpty) return false;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final categoriesList = _toStringList(data['categories']);
      final parsedCategories = _extractCategories(data);
      final incomeCategories = parsedCategories.income;
      final expenseCategories = parsedCategories.expense;

      _state = AuthState(
        isLoading: false,
        isLoggedIn: true,
        isOnboarded: data['is_onboarded'] ?? false,
        userId: data['id']?.toString(),
        userEmail: data['email']?.toString(),
        userName: data['name']?.toString(),
        userCurrency: data['currency']?.toString(),
        userCategories: categoriesList,
        userIncomeCategories: incomeCategories,
        userExpenseCategories: expenseCategories,
      );
      TransactionRepository.setCurrentUserId(_state.userId);
      StagedDraftRepository.setCurrentUserId(_state.userId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadSession() async {
    _state = _copyState(isLoading: true);
    notifyListeners();

    try {
      debugPrint("🔄 Loading session...");
      final token = await SecureStorage.readToken();
      if (token == null) {
        debugPrint("⚠️ No token found, user not logged in");
        _state = AuthState.initial().copyWith(isLoading: false);
        notifyListeners();
        return;
      }

      debugPrint("✅ Token found, fetching user data");
      final res = await ApiClient.get("/auth/me");
      debugPrint("📥 /auth/me response: ${res.statusCode}");

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        debugPrint("👤 User data: $data");

        final parsedCategories = _extractCategories(data);
        final incomeCategories = parsedCategories.income;
        final expenseCategories = parsedCategories.expense;
        final categoriesList = {
          ...incomeCategories,
          ...expenseCategories,
        }.toList();

        _state = AuthState(
          isLoading: false,
          isLoggedIn: true,
          isOnboarded: data["is_onboarded"] ?? false,
          userId: data["id"]?.toString(),
          userEmail: data["email"],
          userName: data["name"],
          userCurrency: data["currency"]?.toString(),
          userCategories: categoriesList,
          userIncomeCategories: incomeCategories,
          userExpenseCategories: expenseCategories,
        );

        // Set user ID for transaction filtering
        TransactionRepository.setCurrentUserId(_state.userId);
        StagedDraftRepository.setCurrentUserId(_state.userId);

        debugPrint(
          "✅ Session loaded - userId: ${_state.userId}, name: ${_state.userName}, isOnboarded: ${_state.isOnboarded}",
        );
        await _saveProfileCache();
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load session: ${res.statusCode}");
        final restored = await _restoreProfileCache();
        if (!restored) {
          _state = AuthState.initial().copyWith(isLoading: false);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading session: $e");
      final restored = await _restoreProfileCache();
      if (!restored) {
        _state = AuthState.initial().copyWith(isLoading: false);
        notifyListeners();
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      debugPrint("🔐 Attempting login for: $email");
      final res = await ApiClient.post("/auth/login", {
        "email": email,
        "password": password,
      }, requiresAuth: false);

      ApiClient.ensureSuccess(res, fallbackMessage: 'Login failed');

      if (res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        if (data["access_token"] != null) {
          await SecureStorage.saveToken(data["access_token"]);
          await loadSession();
          return;
        }
      }

      throw ApiException(ApiClient.genericUnexpectedMessage);
    } catch (e) {
      debugPrint("❌ Login error: $e");
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? currency,
  }) async {
    try {
      final res = await ApiClient.post("/auth/register", {
        "name": name,
        "email": email,
        "password": password,
        if (currency != null && currency.trim().isNotEmpty)
          "currency": currency.trim().toUpperCase(),
      }, requiresAuth: false);

      ApiClient.ensureSuccess(res, fallbackMessage: 'Registration failed');

      if (res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        if (data["access_token"] != null) {
          await SecureStorage.saveToken(data["access_token"]);
          await loadSession();
          return;
        }
      }

      throw ApiException(ApiClient.genericUnexpectedMessage);
    } catch (e) {
      debugPrint("Registration error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clear();
    await SecureStorage.deleteKey(_profileKey);
    TransactionRepository.setCurrentUserId(null);
    StagedDraftRepository.setCurrentUserId(null);
    _state = AuthState.initial().copyWith(isLoading: false);
    notifyListeners();
  }

  Future<void> markOnboarded({
    List<String>? categories,
    List<String>? incomeCategories,
    List<String>? expenseCategories,
  }) async {
    final resolvedCategories = categories ?? <String>[];
    final resolvedIncomeCategories = incomeCategories ?? <String>[];
    final resolvedExpenseCategories = expenseCategories ?? <String>[];

    try {
      debugPrint(
        "📦 Onboarding with income: $resolvedIncomeCategories expense: $resolvedExpenseCategories categories: $resolvedCategories",
      );

      final cleanedIncome = resolvedIncomeCategories
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final cleanedExpense = resolvedExpenseCategories
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final categoryPairs = _buildCategoryPairsPayload(
        incomeCategories: cleanedIncome,
        expenseCategories: cleanedExpense,
      );

      final payload = {"categories": categoryPairs};

      debugPrint("📤 Sending payload: $payload");

      final res = await ApiClient.post("/auth/onboarding", payload);
      ApiClient.ensureSuccess(res, fallbackMessage: 'Onboarding failed');

      _state = AuthState(
        isLoading: false,
        isLoggedIn: true,
        isOnboarded: true,
        userId: _state.userId,
        userEmail: _state.userEmail,
        userName: _state.userName,
        userCurrency: _state.userCurrency,
        userCategories: resolvedCategories,
        userIncomeCategories: resolvedIncomeCategories,
        userExpenseCategories: resolvedExpenseCategories,
      );
      await _saveProfileCache();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Onboarding error: $e");
      rethrow;
    }
  }

  Future<void> updateName(String newName) async {
    try {
      debugPrint("📝 Updating name to: $newName");
      final res = await ApiClient.put("/settings/name", {"name": newName});

      ApiClient.ensureSuccess(res, fallbackMessage: 'Failed to update name');

      _state = AuthState(
        isLoading: false,
        isLoggedIn: true,
        isOnboarded: _state.isOnboarded,
        userId: _state.userId,
        userEmail: _state.userEmail,
        userName: newName,
        userCurrency: _state.userCurrency,
        userIncomeCategories: _state.userIncomeCategories,
        userExpenseCategories: _state.userExpenseCategories,
        userCategories: _state.userCategories,
      );
      await _saveProfileCache();
      notifyListeners();
      debugPrint("✅ Name updated successfully");
    } catch (e) {
      debugPrint("❌ Error updating name: $e");
      rethrow;
    }
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      debugPrint("🔒 Updating password");
      final res = await ApiClient.put("/settings/password", {
        "current_password": currentPassword,
        "new_password": newPassword,
      });

      ApiClient.ensureSuccess(
        res,
        fallbackMessage: 'Failed to update password',
      );
      debugPrint("✅ Password updated successfully");
    } catch (e) {
      debugPrint("❌ Error updating password: $e");
      rethrow;
    }
  }

  Future<void> updateCategories({
    required List<String> incomeCategories,
    required List<String> expenseCategories,
  }) async {
    try {
      final mergedCategories = {
        ...incomeCategories,
        ...expenseCategories,
      }.toList();
      final cleanedIncome = incomeCategories
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final cleanedExpense = expenseCategories
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final categoryPairs = _buildCategoryPairsPayload(
        incomeCategories: cleanedIncome,
        expenseCategories: cleanedExpense,
      );

      debugPrint(
        "📦 Updating categories income=$incomeCategories expense=$expenseCategories",
      );
      final res = await ApiClient.put("/settings/categories", {
        "categories": categoryPairs,
      });

      ApiClient.ensureSuccess(
        res,
        fallbackMessage: 'Failed to update categories',
      );

      _state = AuthState(
        isLoading: false,
        isLoggedIn: true,
        isOnboarded: _state.isOnboarded,
        userId: _state.userId,
        userEmail: _state.userEmail,
        userName: _state.userName,
        userCurrency: _state.userCurrency,
        userCategories: mergedCategories,
        userIncomeCategories: incomeCategories,
        userExpenseCategories: expenseCategories,
      );
      await _saveProfileCache();
      notifyListeners();
      debugPrint("✅ Categories updated successfully");
    } catch (e) {
      debugPrint("❌ Error updating categories: $e");
      rethrow;
    }
  }

  Future<void> updateCurrency(String currency) async {
    try {
      final normalized = currency.trim().toUpperCase();
      debugPrint("💱 Updating currency to: $normalized");
      final res = await ApiClient.put("/settings/currency", {
        "currency": normalized,
      });

      ApiClient.ensureSuccess(
        res,
        fallbackMessage: 'Failed to update currency',
      );

      _state = _copyState(userCurrency: normalized);
      await _saveProfileCache();
      notifyListeners();
      debugPrint("✅ Currency updated successfully");
    } catch (e) {
      debugPrint("❌ Error updating currency: $e");
      rethrow;
    }
  }

  Future<void> submitFeedback(String description) async {
    try {
      final trimmedDescription = description.trim();
      if (trimmedDescription.isEmpty) {
        throw ApiException('Feedback description cannot be empty');
      }

      final userId = _state.userId;
      if (userId == null || userId.trim().isEmpty) {
        throw ApiException('Unable to identify user. Please login again.');
      }

      final res = await ApiClient.post('/feedback', {
        'user_id': userId,
        'description': trimmedDescription,
      });

      ApiClient.ensureSuccess(
        res,
        fallbackMessage: 'Failed to submit feedback',
      );
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      rethrow;
    }
  }
}
