import os

base_dir = '/Users/gwang/Documents/workspace/GreenLink/front/lib'

files = {
    'services/api_client.dart': '''
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8080'; // Change to actual backend URL when ready

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: await _getHeaders());
    return _processResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded;
    }
    return null;
  }
}
''',
    'services/auth_service.dart': '''
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> login(String email, String password) async {
    // Mock login
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', 'mock_token');
    
    return ApiResponse(
      success: true,
      message: "로그인에 성공했습니다.",
      data: {
        "accessToken": "mock_token",
        "user": User(userId: 1, email: email, nickname: "그린링크유저", role: "USER").toJson(),
      }
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> signup(String email, String password, String nickname) async {
    // Mock signup
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "회원가입이 완료되었습니다.",
      data: {
        "userId": 1,
        "email": email,
        "nickname": nickname,
        "grantedItems": []
      }
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
  }
}

extension UserExt on User {
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'nickname': nickname,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
''',
    'services/home_service.dart': '''
import '../models/api_response.dart';
import '../models/plant.dart';
import 'api_client.dart';

class HomeService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> getHomeData() async {
    // Mock home data
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "홈 데이터 조회 성공",
      data: {
        "user": {
          "userId": 1,
          "nickname": "그린링크유저"
        },
        "mainUserPlant": {
          "userPlantId": 1,
          "plantName": "바질",
          "nickname": "나의 바질",
          "status": "GROWING", // GROWING, HARVESTABLE
          "imageUrl": null,
          "plantedAt": "2026-04-25T18:40:00",
          "daysAfterPlanting": 0,
          "remainingDays": 14
        }
      }
    );
  }
}
''',
    'services/plant_service.dart': '''
import '../models/api_response.dart';
import '../models/plant.dart';
import 'api_client.dart';

class PlantService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<UserPlant>>> getUserPlants({String? status}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "내 식물 목록 조회 성공",
      data: [
        UserPlant(
          userPlantId: 1, plantId: 1, plantName: "바질", nickname: "나의 바질", status: "GROWING", remainingDays: 14
        ),
      ]
    );
  }

  Future<ApiResponse<UserPlant>> getUserPlantDetail(int userPlantId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "내 식물 상세 조회 성공",
      data: UserPlant(
        userPlantId: 1, plantId: 1, plantName: "바질", nickname: "나의 바질", status: "GROWING", remainingDays: 14, daysAfterPlanting: 0
      )
    );
  }

  Future<ApiResponse<UserPlant>> plantSeed(int userItemId, String nickname) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "식물이 생성되었습니다.",
      data: UserPlant(
        userPlantId: 2, plantId: 1, plantName: "새싹", nickname: nickname, status: "GROWING", remainingDays: 14
      )
    );
  }
}
''',
    'services/item_service.dart': '''
import '../models/api_response.dart';
import '../models/item.dart';
import 'api_client.dart';

class ItemService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<InventoryItem>>> getUserItems({String? itemType}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "내 아이템 조회 성공",
      data: [
        InventoryItem(
          itemId: 1, name: "바질 씨앗", itemType: "SEED", ownedCount: 1, usableCount: 1, usedCount: 0, items: [
            UserItem(userItemId: 1, status: "OWNED")
          ]
        ),
        InventoryItem(
          itemId: 2, name: "기본 화분", itemType: "POT", ownedCount: 1, usableCount: 1, usedCount: 0, items: [
            UserItem(userItemId: 2, status: "OWNED")
          ]
        )
      ]
    );
  }
}
''',
    'widgets/custom_button.dart': '''
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isLoading;
  final bool isDisabled;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSecondary ? theme.colorScheme.secondary : theme.primaryColor;
    final textColor = isSecondary ? theme.textTheme.bodyLarge!.color : Colors.white;

    return ElevatedButton(
      onPressed: isDisabled || isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 50),
        shape: const StadiumBorder(),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
''',
    'widgets/custom_card.dart': '''
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      );
    }
    return card;
  }
}
'''
}

for file_path, content in files.items():
    full_path = os.path.join(base_dir, file_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)

print("Services generated successfully.")
