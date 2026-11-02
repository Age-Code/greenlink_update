// 사용자 모델

// User — 사용자 모델
class User {
  final int userId;
  final String email;
  final String nickname;
  final String role;
  final String? createdAt;

  User({required this.userId, required this.email, required this.nickname, required this.role, this.createdAt});

  // JSON 응답을 모델로 변환
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? 0,
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      role: json['role'] ?? 'USER',
      createdAt: json['createdAt'],
    );
  }
}
