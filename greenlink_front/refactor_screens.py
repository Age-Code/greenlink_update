import os
import re

screen_mapping = {
    'home_page.dart': 'home/',
    'main_page.dart': '',
    'inventory_page.dart': 'inventory/',
    'collection_page.dart': 'collection/',
    'collection_detail_page.dart': 'collection/',
    'quest_page.dart': 'quest/',
    'attend_page.dart': 'attend/',
    'user_plant_list_page.dart': 'user_plant/',
    'user_plant_detail_page.dart': 'user_plant/',
    'seed_planting_page.dart': 'user_plant/',
}

# we also need to move widgets/quest_detail_bottom_sheet.dart ? The user said:
# screens/
# ├── auth/
# ├── home/
# ├── inventory/
# ├── collection/
# ├── quest/
# ├── attend/
# ├── user_plant/

import_replacements = {
    "import '../models/plant.dart';": "import '../../models/user_plant_models.dart';\nimport '../../models/collection_models.dart';",
    "import '../models/item.dart';": "import '../../models/user_item_models.dart';",
    "import '../models/collection.dart';": "import '../../models/collection_models.dart';",
    "import '../models/quest.dart';": "import '../../models/quest_models.dart';",
    "import '../models/attend.dart';": "import '../../models/attend_models.dart';",
    "import '../models/api_response.dart';": "import '../../core/network/api_response.dart';",
    "import '../services/plant_service.dart';": "import '../../services/user_plant_service.dart';",
    "import '../services/item_service.dart';": "import '../../services/user_item_service.dart';",
    "import '../services/collection_service.dart';": "import '../../services/collection_service.dart';",
    "import '../services/quest_service.dart';": "import '../../services/quest_service.dart';",
    "import '../services/attend_service.dart';": "import '../../services/attend_service.dart';",
    "import '../services/home_service.dart';": "import '../../services/home_service.dart';",
    "import '../widgets/custom_card.dart';": "import '../../core/widgets/greenlink_card.dart';",
    "import '../widgets/custom_button.dart';": "import '../../core/widgets/greenlink_button.dart';",
}

model_name_replacements = {
    "UserPlant": "UserPlantSummary",
    "UserPlantSummarySummary": "UserPlantSummary", # In case it was already replaced
    "CollectionItem": "CollectionPlant",
    "InventoryItem": "UserItemGroup",
    "UserItem": "UserItemDetail",
    "UserQuest": "UserQuestSummary",
    "UserQuestSummarySummary": "UserQuestSummary",
    "UserQuestSummaryDetail": "UserQuestDetail",
    "UserPlantSummaryDetail": "UserPlantDetail",
    "QuestService": "QuestService",
    "PlantService": "UserPlantService",
    "ItemService": "UserItemService",
    "CollectionService": "CollectionService",
    "HomeService": "HomeService",
    "AttendService": "AttendService",
    "CustomCard": "GreenlinkCard",
    "CustomButton": "GreenlinkButton",
}

def process_file(file_path, dest_dir):
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Replace imports
    for old, new in import_replacements.items():
        if dest_dir == '': # main_page.dart
            new = new.replace('../../', '../')
        content = content.replace(old, new)
        
    # fix relative paths for siblings if needed
    if 'main_page.dart' in file_path:
        content = content.replace("import 'home_page.dart';", "import 'home/home_page.dart';")
        content = content.replace("import 'inventory_page.dart';", "import 'inventory/inventory_page.dart';")
        content = content.replace("import 'collection_page.dart';", "import 'collection/collection_page.dart';")
        content = content.replace("import 'quest_page.dart';", "import 'quest/quest_page.dart';")

    if dest_dir != '':
        # other sibling imports
        content = re.sub(r"import '([a-z_]+_page.dart)';", r"import '../\1';", content)
        # Fix back the ones that are in the same dir
        # Too complex to regex properly, let's just do it manually for known cases:
        if 'collection_page.dart' in file_path:
            content = content.replace("import '../collection_detail_page.dart';", "import 'collection_detail_page.dart';")
        if 'user_plant_list_page.dart' in file_path:
            content = content.replace("import '../user_plant_detail_page.dart';", "import 'user_plant_detail_page.dart';")
            content = content.replace("import '../seed_planting_page.dart';", "import 'seed_planting_page.dart';")
        if 'home_page.dart' in file_path:
            content = content.replace("import '../user_plant_list_page.dart';", "import '../user_plant/user_plant_list_page.dart';")
            content = content.replace("import '../seed_planting_page.dart';", "import '../user_plant/seed_planting_page.dart';")
            content = content.replace("import '../user_plant_detail_page.dart';", "import '../user_plant/user_plant_detail_page.dart';")
        if 'quest_page.dart' in file_path:
            content = content.replace("import '../attend_page.dart';", "import '../attend/attend_page.dart';")
            content = content.replace("import '../widgets/quest_detail_bottom_sheet.dart';", "import '../../widgets/quest_detail_bottom_sheet.dart';")

    # 2. Replace models and services
    for old, new in model_name_replacements.items():
        # Match whole words to avoid UserPlantSummarySummary
        content = re.sub(r'\b' + old + r'\b', new, content)

    # 3. Specific fixes
    content = content.replace('UserPlantSummaryDetail', 'UserPlantDetail')
    content = content.replace('UserQuestSummaryDetail', 'UserQuestDetail')

    os.makedirs(os.path.dirname(os.path.join('lib/screens', dest_dir, os.path.basename(file_path))), exist_ok=True)
    with open(os.path.join('lib/screens', dest_dir, os.path.basename(file_path)), 'w') as f:
        f.write(content)


for root, _, files in os.walk('lib/screens'):
    if root != 'lib/screens': continue
    for file in files:
        if file in screen_mapping:
            process_file(os.path.join(root, file), screen_mapping[file])
            if screen_mapping[file] != '':
                os.remove(os.path.join(root, file))

# Also fix quest_detail_bottom_sheet.dart
q_sheet_path = 'lib/widgets/quest_detail_bottom_sheet.dart'
if os.path.exists(q_sheet_path):
    with open(q_sheet_path, 'r') as f:
        content = f.read()
    content = content.replace("import '../models/quest.dart';", "import '../models/quest_models.dart';")
    content = content.replace("import '../services/quest_service.dart';", "import '../services/quest_service.dart';")
    content = content.replace("import '../models/api_response.dart';", "import '../core/network/api_response.dart';")
    content = re.sub(r'\bUserQuest\b', 'UserQuestSummary', content)
    content = content.replace('UserQuestSummaryDetail', 'UserQuestDetail')
    with open(q_sheet_path, 'w') as f:
        f.write(content)

# Remove old models and services
old_files = [
    'lib/models/plant.dart', 'lib/models/item.dart', 'lib/models/collection.dart', 
    'lib/models/quest.dart', 'lib/models/attend.dart', 'lib/models/api_response.dart',
    'lib/services/plant_service.dart', 'lib/services/item_service.dart',
    'lib/services/api_client.dart', 'lib/widgets/custom_card.dart', 'lib/widgets/custom_button.dart'
]
for f in old_files:
    if os.path.exists(f):
        os.remove(f)

print("Screens refactored.")
