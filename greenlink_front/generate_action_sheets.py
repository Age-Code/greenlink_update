import os

base_dir = '/Users/gwang/Documents/workspace/GreenLink/front/lib'

files = {
    'services/item_service.dart': '''
import '../models/api_response.dart';
import '../models/item.dart';
import 'api_client.dart';

class ItemService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<InventoryItem>>> getUserItems({String? itemType}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    List<InventoryItem> allItems = [
      InventoryItem(
        itemId: 1, name: "바질 씨앗", itemType: "SEED", description: "바질을 심을 수 있는 씨앗입니다.",
        ownedCount: 1, usableCount: 1, usedCount: 0, items: [
          UserItem(userItemId: 1, status: "OWNED")
        ]
      ),
      InventoryItem(
        itemId: 2, name: "파란 화분", itemType: "POT", description: "식물에게 편안한 집이 되어주는 화분이에요.",
        ownedCount: 2, usableCount: 1, usedCount: 1, items: [
          UserItem(userItemId: 25, status: "OWNED"),
          UserItem(userItemId: 3, status: "EQUIPPED")
        ]
      ),
      InventoryItem(
        itemId: 3, name: "튼튼 영양제", itemType: "NUTRIENT", description: "식물이 무럭무럭 자랄 수 있게 도와줘요.",
        ownedCount: 1, usableCount: 1, usedCount: 2, items: [
          UserItem(userItemId: 30, status: "OWNED"),
          UserItem(userItemId: 4, status: "USED"),
          UserItem(userItemId: 5, status: "USED")
        ]
      ),
    ];

    if (itemType != null) {
      allItems = allItems.where((item) => item.itemType == itemType).toList();
    }

    return ApiResponse(
      success: true,
      message: "내 아이템 조회 성공",
      data: allItems
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> equipPot(int userItemId, int userPlantId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "화분이 장착되었습니다.",
      data: {
        "userItemId": userItemId,
        "itemId": 4,
        "itemName": "파란 화분",
        "itemType": "POT",
        "status": "EQUIPPED",
        "userPlantId": userPlantId
      }
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> useNutrient(int userItemId, int userPlantId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: "영양제를 사용했습니다.",
      data: {
        "userItemId": userItemId,
        "itemType": "NUTRIENT",
        "status": "USED",
        "userPlantId": userPlantId
      }
    );
  }
}
''',
    'widgets/selectable_user_plant_card.dart': '''
import 'package:flutter/material.dart';
import '../models/plant.dart';

class SelectableUserPlantCard extends StatelessWidget {
  final UserPlant plant;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableUserPlantCard({
    Key? key,
    required this.plant,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String statusText = "자라는 중";
    if (plant.status == 'HARVESTABLE') statusText = "수확 가능";
    if (plant.status == 'HARVESTED') statusText = "수확 완료";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.secondary.withOpacity(0.3) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: plant.imageUrl != null
                  ? ClipOval(child: Image.network(plant.imageUrl!, fit: BoxFit.cover))
                  : Icon(Icons.local_florist, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.nickname, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16)),
                  Text(plant.plantName, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(statusText, style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColorDark, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (plant.remainingDays != null)
                        Text("D-\${plant.remainingDays}", style: theme.textTheme.bodySmall),
                    ],
                  )
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.primaryColor)
            else
              Icon(Icons.radio_button_unchecked, color: theme.disabledColor)
          ],
        ),
      ),
    );
  }
}
''',
    'screens/inventory_action_sheets.dart': '''
import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../services/item_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/selectable_user_plant_card.dart';
import 'seed_planting_page.dart';

class PotEquipBottomSheet extends StatefulWidget {
  final int userItemId;
  final VoidCallback onSuccess;

  const PotEquipBottomSheet({Key? key, required this.userItemId, required this.onSuccess}) : super(key: key);

  @override
  _PotEquipBottomSheetState createState() => _PotEquipBottomSheetState();
}

class _PotEquipBottomSheetState extends State<PotEquipBottomSheet> {
  final PlantService _plantService = PlantService();
  final ItemService _itemService = ItemService();
  
  List<UserPlant>? _plants;
  bool _isLoading = true;
  int? _selectedPlantId;
  bool _isEquipping = false;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  void _loadPlants() async {
    final res = await _plantService.getUserPlants(status: 'GROWING');
    if (!mounted) return;
    setState(() {
      _plants = res.data ?? [];
      _isLoading = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Text("어떤 식물에게 장착할까요?", style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text("화분을 선물할 식물 친구를 골라주세요", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _plants!.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        itemCount: _plants!.length,
                        itemBuilder: (context, index) {
                          final plant = _plants![index];
                          return SelectableUserPlantCard(
                            plant: plant,
                            isSelected: _selectedPlantId == plant.userPlantId,
                            onTap: () {
                              setState(() => _selectedPlantId = plant.userPlantId);
                            },
                          );
                        },
                      ),
            ),
            if (_plants != null && _plants!.isNotEmpty) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: "장착하기",
                isDisabled: _selectedPlantId == null,
                isLoading: _isEquipping,
                onPressed: _equip,
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.nature_people_outlined, size: 60, color: theme.disabledColor),
        const SizedBox(height: 16),
        Text("아직 돌볼 식물이 없어요", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("씨앗을 심고 첫 식물 친구를 만나보세요", style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        CustomButton(
          text: "씨앗 심기",
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => SeedPlantingPage()));
          },
        )
      ],
    );
  }
}

class NutrientUseBottomSheet extends StatefulWidget {
  final int userItemId;
  final VoidCallback onSuccess;

  const NutrientUseBottomSheet({Key? key, required this.userItemId, required this.onSuccess}) : super(key: key);

  @override
  _NutrientUseBottomSheetState createState() => _NutrientUseBottomSheetState();
}

class _NutrientUseBottomSheetState extends State<NutrientUseBottomSheet> {
  final PlantService _plantService = PlantService();
  final ItemService _itemService = ItemService();
  
  List<UserPlant>? _plants;
  bool _isLoading = true;
  int? _selectedPlantId;
  bool _isUsing = false;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  void _loadPlants() async {
    final res = await _plantService.getUserPlants(status: 'GROWING');
    if (!mounted) return;
    setState(() {
      _plants = res.data ?? [];
      _isLoading = false;
    });
  }

  void _useNutrient() async {
    if (_selectedPlantId == null) return;
    setState(() => _isUsing = true);
    final res = await _itemService.useNutrient(widget.userItemId, _selectedPlantId!);
    if (!mounted) return;
    setState(() => _isUsing = false);

    if (res.success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("영양제를 사용했어요\\n식물 친구가 좋아할 거예요")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Text("어떤 식물에게 줄까요?", style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text("영양제를 줄 식물 친구를 골라주세요", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _plants!.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        itemCount: _plants!.length,
                        itemBuilder: (context, index) {
                          final plant = _plants![index];
                          return SelectableUserPlantCard(
                            plant: plant,
                            isSelected: _selectedPlantId == plant.userPlantId,
                            onTap: () {
                              setState(() => _selectedPlantId = plant.userPlantId);
                            },
                          );
                        },
                      ),
            ),
            if (_plants != null && _plants!.isNotEmpty) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: "영양제 주기",
                isDisabled: _selectedPlantId == null,
                isLoading: _isUsing,
                onPressed: _useNutrient,
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.nature_people_outlined, size: 60, color: theme.disabledColor),
        const SizedBox(height: 16),
        Text("아직 돌볼 식물이 없어요", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("씨앗을 심고 첫 식물 친구를 만나보세요", style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        CustomButton(
          text: "씨앗 심기",
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => SeedPlantingPage()));
          },
        )
      ],
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

print("Generated files successfully.")
