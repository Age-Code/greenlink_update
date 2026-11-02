// 메인 화면 — 홈/인벤토리/도감/퀘스트 탭 네비게이션

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'home/home_page.dart';
import 'inventory/inventory_page.dart';
import 'collection/collection_page.dart';
import 'quest/quest_page.dart';

// MainPage — 하단 네비게이션 구조
// 탭 구성 (변경 금지):
//   0: 홈
//   1: 인벤토리
//   2: 도감
//   3: 퀘스트
// 탭 전환 시 해당 탭 GlobalKey를 통해 refresh() 호출

// 탭 새로고침 인터페이스
abstract class RefreshablePage {
  // 화면 데이터 새로고침
  void refresh();
}

final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();
final GlobalKey<InventoryPageState> inventoryPageKey =
    GlobalKey<InventoryPageState>();
final GlobalKey<CollectionPageState> collectionPageKey =
    GlobalKey<CollectionPageState>();
final GlobalKey<QuestPageState> questPageKey = GlobalKey<QuestPageState>();

// 메인 화면 — 탭 네비게이션 관리
class MainPage extends StatefulWidget {
  final int initialIndex;
  const MainPage({Key? key, this.initialIndex = 0}) : super(key: key);

  // 현재 화면에 떠 있는 MainPage 상태 — 다이얼로그/바텀시트 등에서 탭 전환용
  static _MainPageState? _activeState;

  // 기존 MainPage의 탭 전환 — 새 MainPage를 push하지 않음 (GlobalKey 중복 방지)
  // 전환된 탭은 refresh() 호출로 데이터 갱신
  static void switchTab(int index) {
    _activeState?._switchTab(index);
  }

  // State 객체 생성
  @override
  _MainPageState createState() => _MainPageState();
}

// _MainPageState — 화면 상태와 이벤트 처리
class _MainPageState extends State<MainPage> {
  late int _currentIndex;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    MainPage._activeState = this;
  }

  // 리소스 정리
  @override
  void dispose() {
    if (identical(MainPage._activeState, this)) {
      MainPage._activeState = null;
    }
    super.dispose();
  }

  late final List<Widget> _pages = [
    HomePage(key: homePageKey),
    InventoryPage(key: inventoryPageKey),
    CollectionPage(key: collectionPageKey),
    QuestPage(key: questPageKey),
  ];

  // 탭 선택 처리 — 같은 탭이면 새로고침
  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    _switchTab(index);
  }

  // 탭 전환 — 같은 탭이면 새로고침, 다른 탭이면 전환 후 새로고침
  void _switchTab(int index) {
    if (!mounted) return;
    if (index == _currentIndex) {
      _refreshTab(index);
    } else {
      setState(() => _currentIndex = index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshTab(index);
      });
    }
  }

  // 현재 탭 새로고침 — RefreshablePage이면 refresh 호출
  void _refreshTab(int index) {
    switch (index) {
      case 0:
        homePageKey.currentState?.refresh();
        break;
      case 1:
        inventoryPageKey.currentState?.refresh();
        break;
      case 2:
        collectionPageKey.currentState?.refresh();
        break;
      case 3:
        questPageKey.currentState?.refresh();
        break;
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.hairline, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                iconOutlined: Icons.home_outlined,
                label: '홈',
                selected: _currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),
              _NavItem(
                icon: Icons.backpack_rounded,
                iconOutlined: Icons.backpack_outlined,
                label: '인벤토리',
                selected: _currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                iconOutlined: Icons.menu_book_outlined,
                label: '도감',
                selected: _currentIndex == 2,
                onTap: () => _onTabTapped(2),
              ),
              _NavItem(
                icon: Icons.check_circle_rounded,
                iconOutlined: Icons.check_circle_outline_rounded,
                label: '퀘스트',
                selected: _currentIndex == 3,
                onTap: () => _onTabTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// _NavItem — 내부 위젯
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconOutlined;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                selected ? icon : iconOutlined,
                size: 22,
                color: selected ? AppColors.primaryStrong : AppColors.bodyMuted,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primaryStrong : AppColors.bodyMuted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
