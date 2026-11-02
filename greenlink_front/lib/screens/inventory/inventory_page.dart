// 인벤토리 화면 — 보유 아이템 조회와 사용 진입

import 'package:flutter/material.dart';
import '../../models/user_item_models.dart';
import '../../services/user_item_service.dart';
import '../../core/widgets/greenlink_card.dart';
import '../../theme/app_theme.dart';
import 'inventory_action_sheets.dart';

// InventoryPage — 화면 위젯
class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  // State 객체 생성
  @override
  InventoryPageState createState() => InventoryPageState();
}

// InventoryPageState — 인벤토리 화면 — 보유 아이템 조회와 사용 진입
class InventoryPageState extends State<InventoryPage> {
  final UserItemService _itemService = UserItemService();

  List<UserItemGroup>? _items;
  bool _isLoading = true;
  String _selectedType = 'ALL';

  final Map<String, String> _typeFilters = {
    'ALL': '전체',
    'SEED': '씨앗',
    'POT': '화분',
    'NUTRIENT': '영양제',
  };

  // 초기 상태 설정
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // 화면 데이터 새로고침
  void refresh() {
    debugPrint('[InventoryPage] 🔄 refresh inventory');
    _loadItems();
  }

  // 데이터 로드 — API 호출 후 상태 반영
  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final typeParam = _selectedType == 'ALL' ? null : _selectedType;
    final res = await _itemService.getUserItems(itemType: typeParam);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() { _items = res.data; _isLoading = false; });
    } else {
      setState(() { _items = []; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  // 아이템 타입 필터 변경 — 목록 재조회
  void _onTypeChanged(String type) {
    setState(() => _selectedType = type);
    _loadItems();
  }

  // 아이템 선택 처리 — 타입별 액션 시트 표시
  void _onItemTap(UserItemGroup group) {
    final firstOwned = group.items.where((i) => i.status == 'OWNED').toList();
    if (firstOwned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용 가능한 아이템이 없습니다.')));
      return;
    }

    final userItemId = firstOwned.first.userItemId;

    if (group.itemType == 'POT') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: PotEquipBottomSheet(userItemId: userItemId, onSuccess: _loadItems),
        ),
      );
    } else if (group.itemType == 'NUTRIENT') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: NutrientUseBottomSheet(userItemId: userItemId, onSuccess: _loadItems),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${group.name}은 씨앗 심기 화면에서 사용할 수 있습니다.')));
    }
  }

  // 위젯 렌더링
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('인벤토리')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              '씨앗, 화분, 영양제를 확인하고 사용해요',
              style: TextStyle(fontSize: 15, color: AppColors.bodyMuted),
            ),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStrong)))
                : _items == null || _items!.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _items!.length,
                        itemBuilder: (context, index) => _buildItemCard(_items![index]),
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
        children: _typeFilters.entries.map((e) {
          final isSelected = _selectedType == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSelected,
              onSelected: (_) => _onTypeChanged(e.key),
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
  Widget _buildItemCard(UserItemGroup group) {
    final usable = group.usableCount > 0;

    Color typeColor;
    Color typeBg;
    IconData typeIcon;

    switch (group.itemType) {
      case 'SEED':
        typeColor = AppColors.primaryStrong;
        typeBg = AppColors.primarySoft;
        typeIcon = Icons.grass_rounded;
        break;
      case 'POT':
        typeColor = const Color(0xFF8A6500);
        typeBg = const Color(0xFFFFF4D8);
        typeIcon = Icons.inventory_2_rounded;
        break;
      case 'NUTRIENT':
        typeColor = const Color(0xFF3A8FC8);
        typeBg = const Color(0xFFDEEFFB);
        typeIcon = Icons.water_drop_rounded;
        break;
      default:
        typeColor = AppColors.bodyMuted;
        typeBg = AppColors.canvasSoft;
        typeIcon = Icons.category_outlined;
    }

    return GestureDetector(
      onTap: usable ? () => _onItemTap(group) : null,
      child: Opacity(
        opacity: usable ? 1.0 : 0.45,
        child: GreenlinkCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: group.imageUrl != null
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.network(group.imageUrl!, fit: BoxFit.contain),
                        )
                      : Icon(typeIcon, size: 36, color: typeColor),
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                group.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Count & type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: usable ? typeBg : AppColors.canvasSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${group.usableCount}개',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: usable ? typeColor : AppColors.bodyMuted,
                      ),
                    ),
                  ),
                  if (usable)
                    Icon(Icons.chevron_right, size: 16, color: AppColors.bodyMuted),
                ],
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
              child: const Icon(Icons.backpack_outlined, size: 40, color: AppColors.bodyMuted),
            ),
            const SizedBox(height: 24),
            const Text('아직 아이템이 없어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text('퀘스트 보상으로 아이템을 얻을 수 있어요', style: TextStyle(fontSize: 14, color: AppColors.bodyMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
