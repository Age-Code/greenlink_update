// 씨앗 심기 화면 — 보유 씨앗 선택 후 식재

import 'package:flutter/material.dart';
import '../../models/user_item_models.dart';
import '../../services/user_item_service.dart';
import '../../services/user_plant_service.dart';
import '../../core/widgets/greenlink_card.dart';
import '../../theme/app_theme.dart';

// SeedPlantingPage — 화면 위젯
class SeedPlantingPage extends StatefulWidget {
  // State 객체 생성
  @override
  _SeedPlantingPageState createState() => _SeedPlantingPageState();
}

// _SeedPlantingPageState — 화면 상태와 이벤트 처리
class _SeedPlantingPageState extends State<SeedPlantingPage> {
  final UserItemService _itemService = UserItemService();
  final UserPlantService _plantService = UserPlantService();

  List<UserItemGroup>? _seeds;
  bool _isLoading = true;
  bool _isPlanting = false;

  int? _selectedUserItemId;
  final TextEditingController _nicknameController = TextEditingController();

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadSeeds();
  }

  // 리소스 정리
  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadSeeds() async {
    setState(() => _isLoading = true);
    final res = await _itemService.getUserItems(itemType: 'SEED', status: 'OWNED');
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _seeds = res.data!.where((s) => s.usableCount > 0 && s.items.isNotEmpty).toList();
        _isLoading = false;
      });
    } else {
      setState(() { _seeds = []; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 식재 처리 — 선택 씨앗으로 식물 생성
  Future<void> _plantSeed() async {
    if (_selectedUserItemId == null) return;
    setState(() => _isPlanting = true);
    final nickname = _nicknameController.text.trim();
    final res = await _plantService.plantSeed(_selectedUserItemId!, nickname);
    if (!mounted) return;
    setState(() => _isPlanting = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('식물이 생성되었습니다.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('씨앗 심기'), centerTitle: false),
      body: _isLoading
          ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong)))
          : _seeds == null || _seeds!.isEmpty
              ? _buildEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '새로운 식물 친구를 만나볼까요?',
                              style: TextStyle(fontSize: 15, color: AppColors.bodyMuted),
                            ),
                            const SizedBox(height: 24),
                            const Text('보유 중인 씨앗', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            const SizedBox(height: 12),
                            ..._seeds!.map((seed) => _buildSeedCard(seed)),
                            const SizedBox(height: 28),
                            const Text('식물 이름 짓기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            const SizedBox(height: 6),
                            const Text('이름을 지어주지 않으면 기본 이름으로 시작해요', style: TextStyle(fontSize: 13, color: AppColors.bodyMuted)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nicknameController,
                              style: const TextStyle(fontSize: 16, color: AppColors.ink),
                              decoration: const InputDecoration(
                                hintText: '식물 친구 이름을 지어주세요 (선택)',
                                prefixIcon: Icon(Icons.eco_outlined, size: 20, color: AppColors.bodyMuted),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    // Bottom CTA
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      decoration: const BoxDecoration(
                        color: AppColors.canvas,
                        border: Border(top: BorderSide(color: AppColors.hairline)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_selectedUserItemId == null || _isPlanting) ? null : _plantSeed,
                          child: _isPlanting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                              : const Text('심기 완료', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // 화면 섹션 렌더링
  Widget _buildSeedCard(UserItemGroup seed) {
    final ownedItems = seed.items.where((i) => i.status == 'OWNED').toList();
    if (ownedItems.isEmpty) return const SizedBox();

    final userItemId = ownedItems.first.userItemId;
    final isSelected = _selectedUserItemId == userItemId;

    return GestureDetector(
      onTap: () => setState(() => _selectedUserItemId = userItemId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryFocus : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: GreenlinkCard(
          borderRadius: 18,
          color: isSelected ? AppColors.canvasGreenTint : AppColors.surfaceCard,
          child: Row(
            children: [
              // Image
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primarySoft : AppColors.canvasSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: seed.imageUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.network(seed.imageUrl!, fit: BoxFit.contain),
                      )
                    : const Icon(Icons.grass_rounded, size: 28, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seed.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    if (seed.description != null) ...[
                      const SizedBox(height: 3),
                      Text(seed.description!, style: const TextStyle(fontSize: 13, color: AppColors.bodyMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primarySoft : AppColors.canvasSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${seed.usableCount}개',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primaryStrong : AppColors.bodyMuted,
                  ),
                ),
              ),
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
              child: const Icon(Icons.grass_rounded, size: 40, color: AppColors.bodyMuted),
            ),
            const SizedBox(height: 24),
            const Text('지금 심을 수 있는 씨앗이 없어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('퀘스트 보상으로 씨앗을 얻어보세요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
