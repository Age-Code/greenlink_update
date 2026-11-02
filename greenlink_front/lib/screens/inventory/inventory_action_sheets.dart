// 인벤토리 액션 시트 — 화분 장착과 영양제 사용

import 'package:flutter/material.dart';
import '../../models/user_plant_models.dart';
import '../../services/user_plant_service.dart';
import '../../services/user_item_service.dart';
import '../../core/widgets/greenlink_button.dart';
import '../../widgets/selectable_user_plant_card.dart';
import '../user_plant/seed_planting_page.dart';
import '../../theme/app_theme.dart';

// PotEquipBottomSheet — 인벤토리 액션 시트 — 화분 장착과 영양제 사용
class PotEquipBottomSheet extends StatefulWidget {
  final int userItemId;
  final VoidCallback onSuccess;

  const PotEquipBottomSheet({Key? key, required this.userItemId, required this.onSuccess}) : super(key: key);

  // State 객체 생성
  @override
  _PotEquipBottomSheetState createState() => _PotEquipBottomSheetState();
}

// _PotEquipBottomSheetState — 화면 상태와 이벤트 처리
class _PotEquipBottomSheetState extends State<PotEquipBottomSheet> {
  final UserPlantService _plantService = UserPlantService();
  final UserItemService _itemService = UserItemService();

  List<UserPlantSummary>? _plants;
  bool _isLoading = true;
  int? _selectedPlantId;
  bool _isEquipping = false;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  void _loadPlants() async {
    final res = await _plantService.getUserPlants();
    if (!mounted) return;
    setState(() { _plants = res.data ?? []; _isLoading = false; });
  }

  // 화분 장착 처리
  void _equip() async {
    if (_selectedPlantId == null) return;
    setState(() => _isEquipping = true);
    final res = await _itemService.equipPot(widget.userItemId, _selectedPlantId!);
    if (!mounted) return;
    setState(() => _isEquipping = false);
    if (res.success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  const Text('어떤 식물에게 장착할까요?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  const Text('화분을 선물할 식물 친구를 골라주세요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.bodyMuted),
                      const SizedBox(width: 6),
                      Text('수확 완료 식물은 선택할 수 없어요', style: TextStyle(fontSize: 13, color: AppColors.bodySoft)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.hairline),
            Expanded(
              child: _isLoading
                  ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong)))
                  : (_plants == null || _plants!.isEmpty)
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plants!.length,
                          itemBuilder: (context, index) {
                            final plant = _plants![index];
                            final bool isDisabled = plant.status == 'HARVESTED';
                            return Opacity(
                              opacity: isDisabled ? 0.38 : 1.0,
                              child: SelectableUserPlantSummaryCard(
                                plant: plant,
                                isSelected: _selectedPlantId == plant.userPlantId,
                                onTap: isDisabled ? () {} : () => setState(() => _selectedPlantId = plant.userPlantId),
                              ),
                            );
                          },
                        ),
            ),
            if (_plants != null && _plants!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: GreenlinkButton(text: '장착하기', isLoading: _isEquipping, onPressed: _selectedPlantId != null ? _equip : null),
              ),
          ],
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
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.nature_people_outlined, size: 36, color: AppColors.bodyMuted),
            ),
            const SizedBox(height: 20),
            const Text('아직 돌볼 식물이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('씨앗을 심고 첫 식물 친구를 만나보세요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
            const SizedBox(height: 28),
            GreenlinkButton(
              text: '씨앗 심기',
              width: 160,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SeedPlantingPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// NutrientUseBottomSheet — 인벤토리 액션 시트 — 화분 장착과 영양제 사용
class NutrientUseBottomSheet extends StatefulWidget {
  final int userItemId;
  final VoidCallback onSuccess;

  const NutrientUseBottomSheet({Key? key, required this.userItemId, required this.onSuccess}) : super(key: key);

  // State 객체 생성
  @override
  _NutrientUseBottomSheetState createState() => _NutrientUseBottomSheetState();
}

// _NutrientUseBottomSheetState — 화면 상태와 이벤트 처리
class _NutrientUseBottomSheetState extends State<NutrientUseBottomSheet> {
  final UserPlantService _plantService = UserPlantService();
  final UserItemService _itemService = UserItemService();

  List<UserPlantSummary>? _plants;
  bool _isLoading = true;
  int? _selectedPlantId;
  bool _isUsing = false;

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  void _loadPlants() async {
    final res = await _plantService.getUserPlants();
    if (!mounted) return;
    setState(() { _plants = res.data ?? []; _isLoading = false; });
  }

  // 아이템 사용 처리
  void _useNutrient() async {
    if (_selectedPlantId == null) return;
    setState(() => _isUsing = true);
    final res = await _itemService.useNutrient(widget.userItemId, _selectedPlantId!);
    if (!mounted) return;
    setState(() => _isUsing = false);
    if (res.success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('영양제를 사용했어요\n식물 친구가 좋아할 거예요')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  const Text('어떤 식물에게 줄까요?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  const Text('영양제를 줄 식물 친구를 골라주세요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.bodyMuted),
                      const SizedBox(width: 6),
                      Text('수확 완료 식물은 선택할 수 없어요', style: TextStyle(fontSize: 13, color: AppColors.bodySoft)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.hairline),
            Expanded(
              child: _isLoading
                  ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong)))
                  : (_plants == null || _plants!.isEmpty)
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plants!.length,
                          itemBuilder: (context, index) {
                            final plant = _plants![index];
                            final bool isDisabled = plant.status == 'HARVESTED';
                            return Opacity(
                              opacity: isDisabled ? 0.38 : 1.0,
                              child: SelectableUserPlantSummaryCard(
                                plant: plant,
                                isSelected: _selectedPlantId == plant.userPlantId,
                                onTap: isDisabled ? () {} : () => setState(() => _selectedPlantId = plant.userPlantId),
                              ),
                            );
                          },
                        ),
            ),
            if (_plants != null && _plants!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: GreenlinkButton(text: '영양제 주기', isLoading: _isUsing, onPressed: _selectedPlantId != null ? _useNutrient : null),
              ),
          ],
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
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.canvasGreenTint, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.nature_people_outlined, size: 36, color: AppColors.bodyMuted),
            ),
            const SizedBox(height: 20),
            const Text('아직 돌볼 식물이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('씨앗을 심고 첫 식물 친구를 만나보세요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted)),
            const SizedBox(height: 28),
            GreenlinkButton(
              text: '씨앗 심기',
              width: 160,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SeedPlantingPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
