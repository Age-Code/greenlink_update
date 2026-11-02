import os

base_dir = '/Users/gwang/Documents/workspace/GreenLink/front/lib'

files = {
    'screens/my_plants_screen.dart': '''
import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../widgets/custom_card.dart';
import 'plant_seed_screen.dart';
import 'plant_detail_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  @override
  _MyPlantsScreenState createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final PlantService _plantService = PlantService();
  List<UserPlant> _plants = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, GROWING, HARVESTABLE, HARVESTED

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  void _loadPlants() async {
    setState(() => _isLoading = true);
    String? statusQuery;
    if (_selectedFilter != 'ALL') {
      statusQuery = _selectedFilter;
    }
    final res = await _plantService.getUserPlants(status: statusQuery);
    if (res.success && res.data != null) {
      setState(() {
        _plants = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 식물"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'GROWING', 'HARVESTABLE', 'HARVESTED'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(filter == 'ALL' ? '전체' :
                                filter == 'GROWING' ? '성장 중' :
                                filter == 'HARVESTABLE' ? '수확 가능' : '수확 완료'),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                        _loadPlants();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("아직 키우는 식물이 없어요"),
                      const Text("씨앗을 심고 첫 식물 친구를 만나보세요"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PlantSeedScreen()));
                        },
                        child: const Text("씨앗 심기"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plants.length,
                  itemBuilder: (context, index) {
                    final plant = _plants[index];
                    return CustomCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(userPlantId: plant.userPlantId)));
                      },
                      child: Row(
                        children: [
                          Icon(Icons.eco, size: 50, color: theme.primaryColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plant.nickname, style: theme.textTheme.titleMedium),
                                Text(plant.plantName, style: theme.textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(plant.status == 'GROWING' ? '자라는 중' :
                                     plant.status == 'HARVESTABLE' ? '수확 가능' : '수확 완료',
                                     style: theme.textTheme.bodyMedium),
                                Text("남은 일수: ${plant.remainingDays ?? 0}일", style: theme.textTheme.bodySmall),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PlantSeedScreen()));
        },
        child: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
      ),
    );
  }
}
''',
    'screens/plant_detail_screen.dart': '''
import 'package:flutter/material.dart';

class PlantDetailScreen extends StatelessWidget {
  final int userPlantId;

  const PlantDetailScreen({Key? key, required this.userPlantId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("식물 상세")),
      body: Center(child: Text("식물 상세 조회 (ID: $userPlantId)")),
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
      appBar: AppBar(
        title: const Text("식물 도감"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("함께한 식물 친구들이 기록돼요", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Text("도감 화면 (개발 중)"),
          ],
        ),
      ),
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
      appBar: AppBar(
        title: const Text("퀘스트"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("식물 친구와 함께하는 작은 약속이에요", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Text("퀘스트 화면 (개발 중)"),
          ],
        ),
      ),
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

print("Additional screens generated successfully.")
