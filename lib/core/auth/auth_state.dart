class AuthState {
  final bool isLoggedIn;
  final bool isOnboarded;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final List<String>? userCategories;

  AuthState({
    required this.isLoggedIn,
    required this.isOnboarded,
    this.userId,
    this.userEmail,
    this.userName,
    this.userCategories,
  });

  factory AuthState.initial() => AuthState(
    isLoggedIn: false,
    isOnboarded: false,
    userId: null,
    userEmail: null,
    userName: null,
    userCategories: null,
  );
}
