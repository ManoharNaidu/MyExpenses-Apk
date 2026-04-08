import 'dart:convert';
import '../storage/secure_storage.dart';

/// Persisted wizard state for resumable onboarding.
/// Stored in SecureStorage under key `onboarding_progress`.
class OnboardingState {
  static const _storageKey = 'onboarding_progress';

  final int currentStep; // 0–4
  final String? persona; // 'tracker'|'saver'|'analyser'|'organiser'
  final String? collectedName;
  final String? collectedCurrency;
  final List<String> incomeCategories;
  final List<String> expenseCategories;

  const OnboardingState({
    this.currentStep = 0,
    this.persona,
    this.collectedName,
    this.collectedCurrency,
    this.incomeCategories = const [],
    this.expenseCategories = const [],
  });

  OnboardingState copyWith({
    int? currentStep,
    String? persona,
    String? collectedName,
    String? collectedCurrency,
    List<String>? incomeCategories,
    List<String>? expenseCategories,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      persona: persona ?? this.persona,
      collectedName: collectedName ?? this.collectedName,
      collectedCurrency: collectedCurrency ?? this.collectedCurrency,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStep': currentStep,
        'persona': persona,
        'collectedName': collectedName,
        'collectedCurrency': collectedCurrency,
        'incomeCategories': incomeCategories,
        'expenseCategories': expenseCategories,
      };

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      currentStep: (json['currentStep'] as int?) ?? 0,
      persona: json['persona'] as String?,
      collectedName: json['collectedName'] as String?,
      collectedCurrency: json['collectedCurrency'] as String?,
      incomeCategories: (json['incomeCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      expenseCategories: (json['expenseCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  // ─── Persistence helpers ─────────────────────────────────────────

  Future<void> save() async {
    await SecureStorage.writeString(_storageKey, jsonEncode(toJson()));
  }

  static Future<OnboardingState> load() async {
    final raw = await SecureStorage.readString(_storageKey);
    if (raw == null || raw.isEmpty) return const OnboardingState();
    try {
      return OnboardingState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const OnboardingState();
    }
  }

  static Future<void> clear() async {
    await SecureStorage.deleteKey(_storageKey);
  }
}
