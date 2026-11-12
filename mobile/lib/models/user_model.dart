class UserModel {
  final String username;
  final String defaultRegion;
  final String preferredLanguage;
  final String accountType; // "User" or "Purohit"

  UserModel({
    required this.username,
    required this.defaultRegion,
    required this.preferredLanguage,
    required this.accountType,
  });

  bool get isPurohit => accountType.toLowerCase() == 'purohit';
  bool get isAdmin => username == 'BVarad0876';

  UserModel copyWith({
    String? username,
    String? defaultRegion,
    String? preferredLanguage,
    String? accountType,
  }) {
    return UserModel(
      username: username ?? this.username,
      defaultRegion: defaultRegion ?? this.defaultRegion,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      accountType: accountType ?? this.accountType,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      defaultRegion: json['default_region'] ?? 'General/Standard',
      preferredLanguage: json['preferred_language'] ?? 'English',
      accountType: json['account_type'] ?? 'User',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'default_region': defaultRegion,
      'preferred_language': preferredLanguage,
      'account_type': accountType,
    };
  }
}
