import os
import re

# Move auth and inventory action sheets
move_files = {
    'lib/screens/login_page.dart': 'lib/screens/auth/login_page.dart',
    'lib/screens/signup_page.dart': 'lib/screens/auth/signup_page.dart',
    'lib/screens/inventory_action_sheets.dart': 'lib/screens/inventory/inventory_action_sheets.dart',
}

for old, new in move_files.items():
    if os.path.exists(old):
        os.makedirs(os.path.dirname(new), exist_ok=True)
        os.rename(old, new)

# Fix imports in auth and inventory_action_sheets
fix_files = [
    'lib/screens/auth/login_page.dart',
    'lib/screens/auth/signup_page.dart',
    'lib/screens/inventory/inventory_action_sheets.dart',
    'lib/services/auth_service.dart',
    'lib/widgets/quest_detail_bottom_sheet.dart',
    'lib/widgets/selectable_user_plant_card.dart',
    'lib/screens/user_plant/user_plant_detail_page.dart'
]

import_replacements = {
    "import '../models/plant.dart';": "import '../../models/user_plant_models.dart';\nimport '../../models/collection_models.dart';",
    "import '../../models/plant.dart';": "import '../../models/user_plant_models.dart';\nimport '../../models/collection_models.dart';",
    "import '../models/item.dart';": "import '../../models/user_item_models.dart';",
    "import '../../models/item.dart';": "import '../../models/user_item_models.dart';",
    "import '../models/collection.dart';": "import '../../models/collection_models.dart';",
    "import '../models/quest.dart';": "import '../../models/quest_models.dart';",
    "import '../models/attend.dart';": "import '../../models/attend_models.dart';",
    "import '../models/api_response.dart';": "import '../../core/network/api_response.dart';",
    "import '../../models/api_response.dart';": "import '../../core/network/api_response.dart';",
    "import '../services/plant_service.dart';": "import '../../services/user_plant_service.dart';",
    "import '../../services/plant_service.dart';": "import '../../services/user_plant_service.dart';",
    "import '../services/item_service.dart';": "import '../../services/user_item_service.dart';",
    "import '../../services/item_service.dart';": "import '../../services/user_item_service.dart';",
    "import '../services/collection_service.dart';": "import '../../services/collection_service.dart';",
    "import '../services/quest_service.dart';": "import '../../services/quest_service.dart';",
    "import '../services/attend_service.dart';": "import '../../services/attend_service.dart';",
    "import '../services/home_service.dart';": "import '../../services/home_service.dart';",
    "import '../widgets/custom_card.dart';": "import '../../core/widgets/greenlink_card.dart';",
    "import '../../widgets/custom_card.dart';": "import '../../core/widgets/greenlink_card.dart';",
    "import '../widgets/custom_button.dart';": "import '../../core/widgets/greenlink_button.dart';",
    "import '../../widgets/custom_button.dart';": "import '../../core/widgets/greenlink_button.dart';",
    
    # Auth service specific
    "import '../models/api_response.dart';": "import '../core/network/api_response.dart';",
    "import 'api_client.dart';": "import '../core/network/api_client.dart';",
    
    # Widget specific
    "import '../models/plant.dart';": "import '../models/user_plant_models.dart';",
    "import '../models/item.dart';": "import '../models/user_item_models.dart';",
    "import '../widgets/custom_card.dart';": "import '../core/widgets/greenlink_card.dart';",
}

for file_path in fix_files:
    if not os.path.exists(file_path): continue
    with open(file_path, 'r') as f:
        content = f.read()

    if 'auth_service.dart' in file_path:
        content = content.replace("import '../models/api_response.dart';", "import '../core/network/api_response.dart';")
        content = content.replace("import 'api_client.dart';", "import '../core/network/api_client.dart';")
    else:
        for old, new in import_replacements.items():
            content = content.replace(old, new)

    if 'inventory_action_sheets.dart' in file_path:
        content = content.replace("ItemService", "UserItemService")
        content = content.replace("UserItem", "UserItemDetail")
        content = content.replace("UserPlant", "UserPlantSummary")
        content = content.replace("CustomButton", "GreenlinkButton")
        content = content.replace("import '../seed_planting_page.dart';", "import '../user_plant/seed_planting_page.dart';")
        content = content.replace("import 'seed_planting_page.dart';", "import '../user_plant/seed_planting_page.dart';")
    
    if 'login_page.dart' in file_path or 'signup_page.dart' in file_path:
        content = content.replace("CustomButton", "GreenlinkButton")
        content = content.replace("import '../main_page.dart';", "import '../main_page.dart';")
        
    if 'user_plant_detail_page.dart' in file_path:
        content = content.replace("UserPlantSummary?", "UserPlantDetail?")

    if 'quest_detail_bottom_sheet.dart' in file_path:
        content = content.replace("rewardQuantity", "rewardItem?.quantity")
        
    if 'selectable_user_plant_card.dart' in file_path:
        content = content.replace("UserPlant", "UserPlantSummary")
        content = content.replace("import '../models/plant.dart';", "import '../models/user_plant_models.dart';")
        
    with open(file_path, 'w') as f:
        f.write(content)

print("Additional fixes done.")
