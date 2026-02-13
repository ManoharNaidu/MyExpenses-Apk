class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool isOnboarded;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final List<String>? userCategories;

  AuthState({
    required this.isLoading,
    required this.isLoggedIn,
    required this.isOnboarded,
    this.userId,
    this.userEmail,
    this.userName,
    this.userCategories,
  });

  factory AuthState.initial() => AuthState(
    isLoading: true,
    isLoggedIn: false,
    isOnboarded: false,
    userId: null,
    userEmail: null,
    userName: null,
    userCategories: null,
  );

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isOnboarded,
    String? userId,
    String? userEmail,
    String? userName,
    List<String>? userCategories,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userCategories: userCategories ?? this.userCategories,
    );
  }
}
