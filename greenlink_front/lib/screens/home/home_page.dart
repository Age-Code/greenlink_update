// 홈 화면 — 사용자 식물 상태와 수확 진입

import 'package:flutter/material.dart';
import '../../models/home_models.dart';
import '../../models/iot_models.dart';
import '../../services/home_service.dart';
import '../../services/user_plant_service.dart';
import '../../services/iot_service.dart';
import '../../models/user_plant_models.dart';
import '../../core/utils/plant_image_utils.dart';
import '../../core/widgets/greenlink_card.dart';
import '../../core/widgets/greenlink_button.dart';
import '../../theme/app_theme.dart';
import '../user_plant/user_plant_list_page.dart';
import '../user_plant/seed_planting_page.dart';
import '../user_plant/user_plant_detail_page.dart';
import '../settings_page.dart';

// HomePage — 화면 위젯
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  // State 객체 생성
  @override
  HomePageState createState() => HomePageState();
}

// HomePageState — 홈 화면 — 사용자 식물 상태와 수확 진입
class HomePageState extends State<HomePage> {
  final HomeService _homeService = HomeService();
  final UserPlantService _plantService = UserPlantService();
  final IotService _iotService = IotService();

  HomeResponse? _homeData;
  List<UserPlantSummary> _userPlants = [];
  final Map<int, PlantImageData?> _latestImageData = {};
  bool _isLoading = true;
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  // 수확 요청 중인 식물 ID — 중복 요청 방지
  int? _harvestingPlantId;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 리소스 정리
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 화면 데이터 새로고침
  void refresh() {
    debugPrint('[HomePage] 🔄 refresh home');
    _loadData();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final homeRes = await _homeService.getHomeData();
    if (!mounted) return;

    if (homeRes.success && homeRes.data != null) {
      _homeData = homeRes.data;

      final plantsRes = await _plantService.getUserPlants();
      if (!mounted) return;
      if (plantsRes.success && plantsRes.data != null) {
        _userPlants = plantsRes.data!
            .where((p) => p.status == 'GROWING' || p.status == 'HARVESTABLE')
            .toList();
      }

      if (_userPlants.isEmpty && _homeData!.mainUserPlant != null) {
        final plant = _homeData!.mainUserPlant!;
        if (plant.status == 'GROWING' || plant.status == 'HARVESTABLE') {
          _userPlants.add(
            UserPlantSummary(
              userPlantId: plant.userPlantId,
              plantId: plant.plantId,
              plantName: plant.plantName,
              nickname: plant.nickname,
              status: plant.status,
              imageUrl: plant.imageUrl,
              daysAfterPlanting: plant.daysAfterPlanting,
              remainingDays: plant.remainingDays,
            ),
          );
        }
      }

      if (_userPlants.isNotEmpty) {
        final futures = _userPlants.map(
          (p) => _iotService
              .getLatestImageData(p.userPlantId)
              .then((data) => MapEntry(p.userPlantId, data)),
        );
        final results = await Future.wait(futures);
        if (!mounted) return;
        for (final entry in results) {
          _latestImageData[entry.key] = entry.value;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      // 수확 등으로 목록이 줄어든 경우 현재 페이지 인덱스 보정
      if (_currentPage >= _userPlants.length) {
        _currentPage = _userPlants.isEmpty ? 0 : _userPlants.length - 1;
      }
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      if ((_pageController.page?.round() ?? 0) != _currentPage) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  // 수확 처리 — 성공 시 상태 갱신
  void _harvestPlant(UserPlantSummary plant) async {
    if (_harvestingPlantId != null) return;
    setState(() => _harvestingPlantId = plant.userPlantId);
    final res = await _plantService.harvestUserPlant(plant.userPlantId);
    if (!mounted) return;
    setState(() => _harvestingPlantId = null);

    if (res.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수확이 완료되었습니다!')));
      _loadData();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryStrong,
            ),
          ),
        ),
      );
    }

    if (_homeData == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.bodyMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                '데이터를 불러오지 못했습니다',
                style: TextStyle(color: AppColors.bodyMuted),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: _loadData, child: const Text('다시 시도')),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                    icon: const Icon(Icons.person_outline_rounded, size: 18),
                    label: const Text('계정 설정'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final user = _homeData!.user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(user),
            Expanded(
              child: _userPlants.isEmpty
                  ? _buildEmptyPlantState()
                  : _buildPlantCarousel(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildTopBar(dynamic user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕, ${user.nickname} 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '오늘도 식물 친구를 살펴볼까요?',
                  style: TextStyle(fontSize: 14, color: AppColors.bodyMuted),
                ),
              ],
            ),
          ),
          // Plant list button
          _IconBtn(
            icon: Icons.format_list_bulleted_rounded,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserPlantListPage()),
              );
              if (!mounted) return;
              if (result == true) _loadData();
            },
          ),
          const SizedBox(width: 8),
          // Avatar / settings
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            child: user.profileImageUrl != null
                ? CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(user.profileImageUrl!),
                    backgroundColor: AppColors.canvasSoft,
                  )
                : _IconBtn(
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildEmptyPlantState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.canvasSoft,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.local_florist_outlined,
                size: 56,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '아직 함께하는 식물이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '씨앗을 심고 첫 식물 친구를 만나보세요',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.bodyMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            GreenlinkButton(
              text: '씨앗 심기',
              width: 160,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SeedPlantingPage()),
                );
                if (!mounted) return;
                if (result == true) _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildPlantCarousel() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _userPlants.length,
            itemBuilder: (context, index) {
              final plant = _userPlants[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height:
                          Curves.easeOut.transform(value) *
                          MediaQuery.of(context).size.height *
                          0.65,
                      width:
                          Curves.easeOut.transform(value) *
                          MediaQuery.of(context).size.width,
                      child: child,
                    ),
                  );
                },
                child: _buildPlantCard(plant),
              );
            },
          ),
        ),
        // Page Indicator
        if (_userPlants.length > 1) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_userPlants.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? AppColors.primaryStrong
                      : AppColors.primarySoft,
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // 화면 섹션 렌더링
  Widget _buildPlantCard(UserPlantSummary plant) {
    String statusText = '';
    String remainingText = '';
    bool canHarvest = false;

    if (plant.status == 'GROWING') {
      statusText = '조금씩 자라고 있어요';
      remainingText = '수확까지 ${plant.remainingDays ?? 0}일 남았어요';
    } else if (plant.status == 'HARVESTABLE') {
      statusText = '수확할 준비가 됐어요 🌿';
      if ((plant.remainingDays ?? 0) == 0) {
        remainingText = '오늘 수확할 수 있어요';
        canHarvest = true;
      } else {
        remainingText = '수확까지 ${plant.remainingDays ?? 0}일 남았어요';
      }
    } else if (plant.status == 'HARVESTED') {
      statusText = '도감에 기록됐어요';
      remainingText = '수확을 마친 식물이에요';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GreenlinkCard(
        borderRadius: 24,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UserPlantDetailPage(userPlantId: plant.userPlantId),
            ),
          );
          if (!mounted) return;
          if (result == true) _loadData();
        },
        padding: EdgeInsets.zero,
        color: AppColors.surfaceCard,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.canvasSoft,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                ),
                child: Stack(
                  children: [
                    // Plant image
                    Center(
                      child: Builder(
                        builder: (context) {
                          final imgData = _latestImageData[plant.userPlantId];
                          final displayUrl = getPlantThumbnailUrl(
                            capturedImageUrl: imgData?.imageUrl,
                            fallbackImageUrl: plant.imageUrl,
                          );
                          if (displayUrl != null) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Image.network(
                                displayUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.eco_rounded,
                                  size: 100,
                                  color: AppColors.primaryStrong,
                                ),
                              ),
                            );
                          }
                          return const Icon(
                            Icons.eco_rounded,
                            size: 100,
                            color: AppColors.primaryStrong,
                          );
                        },
                      ),
                    ),
                    // Image label
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.canvas.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: const Text(
                          'AI Growth Image',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.bodyMuted,
                          ),
                        ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: plant.status == 'HARVESTABLE'
                              ? AppColors.primarySoft
                              : AppColors.canvas.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: plant.status == 'HARVESTABLE'
                                ? AppColors.primary
                                : AppColors.hairline,
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: plant.status == 'HARVESTABLE'
                                ? AppColors.primaryStrong
                                : AppColors.bodyMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.nickname,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plant.plantName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.bodyMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${plant.daysAfterPlanting ?? 0}일째',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryStrong,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    remainingText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.bodyMuted,
                    ),
                  ),
                  if (canHarvest) ...[
                    const SizedBox(height: 16),
                    GreenlinkButton(
                      text: '수확하기',
                      isLoading: _harvestingPlantId == plant.userPlantId,
                      onPressed: _harvestingPlantId != null
                          ? null
                          : () => _harvestPlant(plant),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    GreenlinkButton(
                      text: '식물 상세 보기',
                      type: ButtonType.secondary,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserPlantDetailPage(
                              userPlantId: plant.userPlantId,
                            ),
                          ),
                        );
                        if (!mounted) return;
                        if (result == true) _loadData();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _IconBtn — 내부 위젯
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.canvasGreenTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}
