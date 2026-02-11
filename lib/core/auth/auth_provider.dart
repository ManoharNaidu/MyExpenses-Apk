import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../storage/secure_storage.dart';
import 'auth_state.dart';
import '../../data/transaction_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial();
  AuthState get state => _state;

  Future<void> loadSession() async {
    try {
      debugPrint("🔄 Loading session...");
      final token = await SecureStorage.readToken();
      if (token == null) {
        debugPrint("⚠️ No token found, user not logged in");
        return;
      }

      debugPrint("✅ Token found, fetching user data");
      final res = await ApiClient.get("/auth/me");
      debugPrint("📥 /auth/me response: ${res.statusCode}");

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        debugPrint("👤 User data: $data");

        final categories = data["categories"];
        final categoriesList = categories is List
            ? categories.map((e) => e.toString()).toList()
            : <String>[];

        _state = AuthState(
          isLoggedIn: true,
          isOnboarded: data["is_onboarded"] ?? false,
          userId: data["id"]?.toString(),
          userEmail: data["email"],
          userName: data["name"],
          userCategories: categoriesList,
        );

        // Set user ID for transaction filtering
        TransactionRepository.setCurrentUserId(_state.userId);

        debugPrint(
          "✅ Session loaded - userId: ${_state.userId}, name: ${_state.userName}, isOnboarded: ${_state.isOnboarded}",
        );
        notifyListeners();
      } else {
        debugPrint("❌ Failed to load session: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error loading session: $e");
      // If session load fails, user stays logged out
    }
  }

  Future<void> login(String email, String password) async {
    try {
      debugPrint("🔐 Attempting login for: $email");
      final res = await ApiClient.post("/auth/login", {
        "email": email,
        "password": password,
      });

      debugPrint("📥 Login response: ${res.statusCode}");

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        debugPrint("📦 Login response data keys: ${data.keys}");

        if (data["access_token"] != null) {
          debugPrint("✅ Access token found in response");
          await SecureStorage.saveToken(data["access_token"]);
          await loadSession();
        } else {
          throw Exception("No access_token in response: ${data.keys}");
        }
      } else {
        throw Exception("Login failed: ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      debugPrint("❌ Login error: $e");
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final res = await ApiClient.post("/auth/register", {
        "name": name,
        "email": email,
        "password": password,
      });

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        await SecureStorage.saveToken(data["access_token"]);
        await loadSession();
      } else {
        throw Exception("Registration failed: ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clear();
    TransactionRepository.setCurrentUserId(null);
    _state = AuthState.initial();
    notifyListeners();
  }

  Future<void> markOnboarded({List<String>? categories}) async {
    try {
      debugPrint("📦 Onboarding with categories: $categories");

      final payload = {
        if (categories != null && categories.isNotEmpty)
          "categories": categories,
      };

      debugPrint("📤 Sending payload: $payload");

      final res = await ApiClient.post("/auth/onboarding", payload);

      debugPrint("📥 Response status: ${res.statusCode}");
      debugPrint("📥 Response body: ${res.body}");

      if (res.statusCode == 200) {
        _state = AuthState(
          isLoggedIn: true,
          isOnboarded: true,
          userId: _state.userId,
          userEmail: _state.userEmail,
          userName: _state.userName,
          userCategories: categories,
        );
        notifyListeners();
      } else {
        throw Exception("Onboarding failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Onboarding error: $e");
      // Fallback: mark as onboarded locally even if API fails
      _state = AuthState(
        isLoggedIn: true,
        isOnboarded: true,
        userId: _state.userId,
        userEmail: _state.userEmail,
        userName: _state.userName,
        userCategories: categories,
      );
      notifyListeners();
    }
  }

  Future<void> updateName(String newName) async {
    try {
      debugPrint("📝 Updating name to: $newName");
      final res = await ApiClient.put("/settings/name", {"name": newName});

      if (res.statusCode == 200) {
        _state = AuthState(
          isLoggedIn: true,
          isOnboarded: _state.isOnboarded,
          userId: _state.userId,
          userEmail: _state.userEmail,
          userName: newName,
          userCategories: _state.userCategories,
        );
        notifyListeners();
        debugPrint("✅ Name updated successfully");
      } else {
        throw Exception("Failed to update name: ${res.statusCode}");
      }
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

      if (res.statusCode == 200) {
        debugPrint("✅ Password updated successfully");
      } else {
        final errorData = jsonDecode(res.body);
        throw Exception(errorData["detail"] ?? "Failed to update password");
      }
    } catch (e) {
      debugPrint("❌ Error updating password: $e");
      rethrow;
    }
  }

  Future<void> updateCategories(List<String> categories) async {
    try {
      debugPrint("📦 Updating categories: $categories");
      final res = await ApiClient.put("/settings/categories", {
        "categories": categories,
      });

      if (res.statusCode == 200) {
        _state = AuthState(
          isLoggedIn: true,
          isOnboarded: _state.isOnboarded,
          userId: _state.userId,
          userEmail: _state.userEmail,
          userName: _state.userName,
          userCategories: categories,
        );
        notifyListeners();
        debugPrint("✅ Categories updated successfully");
      } else {
        throw Exception("Failed to update categories: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error updating categories: $e");
      rethrow;
    }
  }
}
