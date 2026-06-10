class User {
  final String username;
  final String passwordHash;
  final String role;

  User({
    required this.username,
    required this.passwordHash,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'passwordHash': passwordHash,
        'role': role,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        username: map['username'] as String,
        passwordHash: map['passwordHash'] as String,
        role: map['role'] as String,
      );
}
