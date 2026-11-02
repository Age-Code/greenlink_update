// 사용자 식물 목록 화면 — 상태 필터와 식물 카드

import 'package:flutter/material.dart';
import '../../models/user_plant_models.dart';
import '../../services/user_plant_service.dart';
import '../../core/widgets/greenlink_card.dart';
import '../../theme/app_theme.dart';
import 'user_plant_detail_page.dart';
import 'seed_planting_page.dart';

// UserPlantListPage — 화면 위젯
class UserPlantListPage extends StatefulWidget {
  // State 객체 생성
  @override
  _UserPlantListPageState createState() => _UserPlantListPageState();
}

// _UserPlantListPageState — 화면 상태와 이벤트 처리
class _UserPlantListPageState extends State<UserPlantListPage> {
  final UserPlantService _plantService = UserPlantService();

  List<UserPlantSummary>? _plants;
  bool _isLoading = true;
  String _selectedStatus = 'ALL';

  final Map<String, String> _statusFilters = {
    'ALL': '전체',
    'GROWING': '성장 중',
    'HARVESTABLE': '수확 가능',
    'HARVESTED': '수확 완료',
  };

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadPlants() async {
    setState(() => _isLoading = true);
    final statusParam = _selectedStatus == 'ALL' ? null : _selectedStatus;
    final res = await _plantService.getUserPlants(status: statusParam);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() { _plants = res.data; _isLoading = false; });
    } else {
      setState(() { _plants = []; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 식물 상태 필터 변경 — 선택 상태로 목록 재조회
  void _onStatusChanged(String status) {
    setState(() => _selectedStatus = status);
    _loadPlants();
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('내 식물')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SeedPlantingPage()));
          if (!mounted) return;
          if (result == true) _loadPlants();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('씨앗 심기', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        shape: const StadiumBorder(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              '함께 자라는 식물 친구들이에요',
              style: TextStyle(fontSize: 15, color: AppColors.bodyMuted),
            ),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong)))
                : _plants == null || _plants!.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
                        itemCount: _plants!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildPlantCard(_plants![index]),
                      ),
          ),
        ],
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _statusFilters.entries.map((e) {
          final isSelected = _selectedStatus == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSelected,
              onSelected: (_) => _onStatusChanged(e.key),
              selectedColor: AppColors.primarySoft,
              backgroundColor: AppColors.canvas,
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.hairline),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? AppColors.primaryStrong : AppColors.bodyMuted,
              ),
              shape: const StadiumBorder(),
              checkmarkColor: AppColors.primaryStrong,
            ),
          );
        }).toList(),
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildPlantCard(UserPlantSummary plant) {
    String statusText;
    Color statusBg;
    Color statusFg;

    switch (plant.status) {
      case 'GROWING':
        statusText = '성장 중';
        statusBg = AppColors.primarySoft;
        statusFg = AppColors.primaryStrong;
        break;
      case 'HARVESTABLE':
        statusText = '수확 가능';
        statusBg = const Color(0xFFFFF4D8);
        statusFg = const Color(0xFF8A6500);
        break;
      case 'HARVESTED':
        statusText = '수확 완료';
        statusBg = const Color(0xFFF0F0EE);
        statusFg = AppColors.bodyMuted;
        break;
      default:
        statusText = plant.status;
        statusBg = const Color(0xFFF0F0EE);
        statusFg = AppColors.bodyMuted;
    }

    String remainingText = '';
    if (plant.status == 'HARVESTED') {
      remainingText = '수확 완료';
    } else if (plant.remainingDays != null) {
      if (plant.remainingDays! > 0) {
        remainingText = '${plant.remainingDays}일 후 수확';
      } else if (plant.status == 'HARVESTABLE') {
        remainingText = '오늘 수확 가능';
      }
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => UserPlantDetailPage(userPlantId: plant.userPlantId)));
        if (!mounted) return;
        if (result == true) _loadPlants();
      },
      child: Opacity(
        opacity: plant.status == 'HARVESTED' ? 0.6 : 1.0,
        child: GreenlinkCard(
          child: Row(
            children: [
              // Image
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.canvasSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: plant.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(plant.imageUrl!, fit: BoxFit.contain),
                      )
                    : const Icon(Icons.eco_rounded, size: 36, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusFg)),
                    ),
                    const SizedBox(height: 8),
                    Text(plant.nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(plant.plantName, style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
                  ],
                ),
              ),

              // Remaining
              if (remainingText.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      remainingText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: plant.status == 'HARVESTABLE' ? const Color(0xFF8A6500) : AppColors.bodyMuted,
                      ),
                    ),
                    if (plant.daysAfterPlanting != null) ...[
                      const SizedBox(height: 4),
                      Text('${plant.daysAfterPlanting}일째', style: const TextStyle(fontSize: 12, color: AppColors.bodyMuted)),
                    ],
                  ],
                ),

              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.bodyMuted),
            ],
          ),
        ),
      ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.yard_outlined, size: 40, color: AppColors.bodyMuted),
            ),
            const SizedBox(height: 24),
            const Text('아직 키우는 식물이 없어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('씨앗을 심고 첫 식물 친구를 만나보세요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
