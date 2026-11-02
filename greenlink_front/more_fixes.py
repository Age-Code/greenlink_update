import os
import re

fixes = [
    ('lib/screens/auth/login_page.dart', [
        ("import '../main_page.dart';", "import '../main_page.dart';"), # actually it should be import '../main_page.dart'; let's check
        ("import '../services/auth_service.dart';", "import '../../services/auth_service.dart';"),
    ]),
    ('lib/screens/auth/signup_page.dart', [
        ("import '../services/auth_service.dart';", "import '../../services/auth_service.dart';"),
    ]),
    ('lib/screens/home/home_page.dart', [
        ("Map<String, dynamic>? _homeData;", "HomeResponse? _homeData;"),
        ("_homeData!['user']", "_homeData!.user"),
        ("_homeData!['mainUserPlant']", "_homeData!.mainUserPlant"),
        ("_userPlants.add(UserPlantSummary(", "/* removed manual addition */"),
        ("userPlantId: mainP['userPlantId'],", ""),
        ("plantId: 0,", ""),
        ("plantName: mainP['plantName'],", ""),
        ("nickname: mainP['nickname'],", ""),
        ("status: mainP['status'],", ""),
        ("imageUrl: mainP['imageUrl'],", ""),
        ("plantedAt: mainP['plantedAt'],", ""),
        ("daysAfterPlanting: mainP['daysAfterPlanting'],", ""),
        ("remainingDays: mainP['remainingDays']", ""),
        ("));", ""),
        ("final user = _homeData!.user;", "final user = _homeData!.user;"),
        ("user['nickname']", "user.nickname"),
    ]),
    ('lib/screens/inventory/inventory_action_sheets.dart', [
        ("import '../models/user_plant_models.dart';", "import '../../models/user_plant_models.dart';"),
        ("import '../widgets/selectable_user_plant_card.dart';", "import '../../widgets/selectable_user_plant_card.dart';"),
        ("PlantService", "UserPlantService"),
        ("UserItemDetailService", "UserItemService"),
        ("SelectableUserPlantSummaryCard", "SelectableUserPlantCard"),
    ]),
    ('lib/screens/inventory/inventory_page.dart', [
        ("import '../seed_planting_page.dart';", "import '../user_plant/seed_planting_page.dart';"),
    ]),
    ('lib/screens/splash_page.dart', [
        ("import 'login_page.dart';", "import 'auth/login_page.dart';"),
    ]),
    ('lib/widgets/selectable_user_plant_card.dart', [
        ("import '../models/plant.dart';", "import '../models/user_plant_models.dart';"),
        ("UserPlant ", "UserPlantSummary "),
    ]),
]

for file_path, replacements in fixes:
    if not os.path.exists(file_path): continue
    with open(file_path, 'r') as f:
        content = f.read()

    for old, new in replacements:
        content = content.replace(old, new)
        
    # special fix for home_page adding manual
    if 'home_page.dart' in file_path:
        content = content.replace(
"""      if (_userPlants.isEmpty && _homeData!.mainUserPlant != null) {
        final mainP = _homeData!.mainUserPlant;
        /* removed manual addition */
                  
                  
                  
                  
                  
                  
                  
                  
                  
        
      }""",
"""      if (_userPlants.isEmpty && _homeData!.mainUserPlant != null) {
        _userPlants.add(UserPlantSummary(
          userPlantId: _homeData!.mainUserPlant!.userPlantId,
          plantId: _homeData!.mainUserPlant!.plantId,
          plantName: _homeData!.mainUserPlant!.plantName,
          nickname: _homeData!.mainUserPlant!.nickname,
          status: _homeData!.mainUserPlant!.status,
          imageUrl: _homeData!.mainUserPlant!.imageUrl,
          daysAfterPlanting: _homeData!.mainUserPlant!.daysAfterPlanting,
          remainingDays: _homeData!.mainUserPlant!.remainingDays
        ));
      }""")
      
    with open(file_path, 'w') as f:
        f.write(content)

print("More fixes done.")
