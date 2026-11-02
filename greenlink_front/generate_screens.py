import os

base_dir = '/Users/gwang/Documents/workspace/GreenLink/front/lib'

files = {
    'screens/splash_screen.dart': '''
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text("GreenLink", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("나만의 작은 반려식물 돌봄", style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
''',
    'screens/login_screen.dart': '''
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final res = await _authService.login(_emailCtrl.text, _passwordCtrl.text);
    setState(() => _isLoading = false);
    
    if (res.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, size: 60, color: theme.primaryColor),
              const SizedBox(height: 16),
              Text("GreenLink", style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text("오늘도 식물 친구를 만나러 가볼까요?", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "이메일"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: "비밀번호"),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "로그인",
                isLoading: _isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen()));
                },
                child: const Text("회원가입하기"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
''',
    'screens/signup_screen.dart': '''
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _signup() async {
    setState(() => _isLoading = true);
    final res = await _authService.signup(_emailCtrl.text, _passwordCtrl.text, _nicknameCtrl.text);
    setState(() => _isLoading = false);
    
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(labelText: "닉네임"),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: "회원가입",
              isLoading: _isLoading,
              onPressed: _signup,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("로그인 화면으로 돌아가기"),
            )
          ],
        ),
      ),
    );
  }
}
''',
    'screens/main_screen.dart': '''
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_plants_screen.dart';
import 'collection_screen.dart';
import 'quest_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    MyPlantsScreen(),
    CollectionScreen(),
    QuestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.local_florist), label: "내 식물"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "도감"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: "퀘스트"),
        ],
      ),
    );
  }
}
''',
    'screens/home_screen.dart': '''
import 'package:flutter/material.dart';
import '../services/home_service.dart';
import '../widgets/custom_card.dart';
import 'inventory_screen.dart';
import 'attend_screen.dart';
import 'plant_seed_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService();
  Map<String, dynamic>? _homeData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final res = await _homeService.getHomeData();
    if (res.success && res.data != null) {
      setState(() => _homeData = res.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_homeData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _homeData!['user'];
    final mainPlant = _homeData!['mainUserPlant'];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text("안녕, ${user['nickname']}", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text("오늘도 식물 친구를 살펴볼까요?", style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          CustomCard(
            child: Column(
              children: [
                if (mainPlant == null) ...[
                  const Icon(Icons.eco_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("아직 함께하는 식물이 없어요"),
                  const Text("씨앗을 심고 첫 식물 친구를 만나보세요"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PlantSeedScreen()));
                    },
                    child: const Text("씨앗 심기"),
                  )
                ] else ...[
                  const Icon(Icons.eco, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(mainPlant['nickname'], style: theme.textTheme.titleMedium),
                  Text(mainPlant['plantName'], style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mainPlant['status'] == 'GROWING' ? "조금씩 자라고 있어요" : "수확할 준비가 되었어요",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("남은 성장 일수: ${mainPlant['remainingDays']}일"),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomCard(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen()));
                  },
                  child: Column(
                    children: const [
                      Icon(Icons.backpack),
                      SizedBox(height: 8),
                      Text("인벤토리"),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCard(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AttendScreen()));
                  },
                  child: Column(
                    children: const [
                      Icon(Icons.calendar_today),
                      SizedBox(height: 8),
                      Text("출석"),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
''',
    'screens/my_plants_screen.dart': '''
import 'package:flutter/material.dart';

class MyPlantsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내 식물")),
      body: Center(child: Text("내 식물 화면 (목록 조회)")),
    );
  }
}
''',
    'screens/collection_screen.dart': '''
import 'package:flutter/material.dart';

class CollectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("도감")),
      body: Center(child: Text("식물 도감 그리드")),
    );
  }
}
''',
    'screens/quest_screen.dart': '''
import 'package:flutter/material.dart';

class QuestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("퀘스트")),
      body: Center(child: Text("퀘스트 목록")),
    );
  }
}
''',
    'screens/inventory_screen.dart': '''
import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("인벤토리")),
      body: Center(child: Text("보유 아이템 목록")),
    );
  }
}
''',
    'screens/attend_screen.dart': '''
import 'package:flutter/material.dart';

class AttendScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("출석")),
      body: Center(child: Text("출석 달력")),
    );
  }
}
''',
    'screens/plant_seed_screen.dart': '''
import 'package:flutter/material.dart';

class PlantSeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("씨앗 심기")),
      body: Center(child: Text("씨앗 선택 및 심기")),
    );
  }
}
'''
}

for file_path, content in files.items():
    full_path = os.path.join(base_dir, file_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)

print("Screens generated successfully.")
