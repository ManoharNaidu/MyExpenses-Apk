class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool isOnboarded;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final List<String>? userCategories;
  final List<String>? userIncomeCategories;
  final List<String>? userExpenseCategories;
  final String? userCurrency;

  List<String> get effectiveIncomeCategories =>
      userIncomeCategories ?? const [];

  List<String> get effectiveExpenseCategories {
    if (userExpenseCategories != null) return userExpenseCategories!;
    return userCategories ?? const [];
  }

  String get effectiveCurrency {
    final raw = userCurrency?.trim();
    if (raw == null || raw.isEmpty) return 'AUD';
    return raw.toUpperCase();
  }

  AuthState({
    required this.isLoading,
    required this.isLoggedIn,
    required this.isOnboarded,
    this.userId,
    this.userEmail,
    this.userName,
    this.userCategories,
    this.userIncomeCategories,
    this.userExpenseCategories,
    this.userCurrency,
  });

  factory AuthState.initial() => AuthState(
    isLoading: true,
    isLoggedIn: false,
    isOnboarded: false,
    userId: null,
    userEmail: null,
    userName: null,
    userCategories: null,
    userIncomeCategories: null,
    userExpenseCategories: null,
    userCurrency: null,
  );

  AuthState copyWith({
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
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userCategories: userCategories ?? this.userCategories,
      userIncomeCategories:
          userIncomeCategories ?? this.userIncomeCategories,
      userExpenseCategories:
          userExpenseCategories ?? this.userExpenseCategories,
      userCurrency: userCurrency ?? this.userCurrency,
    );
  }
}
