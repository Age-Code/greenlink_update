// 인증 API 모델

// SignupRequest — API 요청 모델
class SignupRequest {
  final String email;
  final String password;
  final String nickname;
  SignupRequest({required this.email, required this.password, required this.nickname});
  // 요청 모델을 JSON으로 변환
  Map<String, dynamic> toJson() => {'email': email, 'password': password, 'nickname': nickname};
}

// SignupResponse — API 응답 모델
class SignupResponse {
  final int userId;
  final String nickname;
  final List<GrantedItem> grantedItems;
  SignupResponse({required this.userId, required this.nickname, required this.grantedItems});
  // JSON 응답을 모델로 변환
  factory SignupResponse.fromJson(Map<String, dynamic> json) => SignupResponse(
    userId: json['userId'] ?? 0,
    nickname: json['nickname'] ?? '',
    grantedItems: (json['grantedItems'] as List?)?.map((i) => GrantedItem.fromJson(i)).toList() ?? [],
  );
}

// GrantedItem — 인증 API 모델
class GrantedItem {
  final int userItemId;
  final String name;
  final String itemType;
  final String? imageUrl;
  GrantedItem({required this.userItemId, required this.name, required this.itemType, this.imageUrl});
  // JSON 응답을 모델로 변환
  factory GrantedItem.fromJson(Map<String, dynamic> json) => GrantedItem(
    userItemId: json['userItemId'] ?? json['itemId'] ?? 0,
    name: json['name'] ?? '',
    itemType: json['itemType'] ?? '',
    imageUrl: json['imageUrl'],
  );
}

// LoginRequest — API 요청 모델
class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  // 요청 모델을 JSON으로 변환
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// LoginResponse — API 응답 모델
class LoginResponse {
  final String accessToken;
  final String tokenType;
  final LoginUser user;
  LoginResponse({required this.accessToken, required this.tokenType, required this.user});
  // JSON 응답을 모델로 변환
  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['accessToken'] ?? '',
    tokenType: json['tokenType'] ?? 'Bearer',
    user: LoginUser.fromJson(json['user']),
  );
}

// LoginUser — 인증 API 모델
class LoginUser {
  final int userId;
  final String email;
  final String nickname;
  LoginUser({required this.userId, required this.email, required this.nickname});
  // JSON 응답을 모델로 변환
  factory LoginUser.fromJson(Map<String, dynamic> json) => LoginUser(
    userId: json['userId'] ?? 0,
    email: json['email'] ?? '',
    nickname: json['nickname'] ?? '',
  );
}
