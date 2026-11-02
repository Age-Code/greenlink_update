import os
import glob

base_dir = '/Users/gwang/Documents/workspace/GreenLink/front/lib'

renames = {
    'screens/home_screen.dart': 'screens/home_page.dart',
    'screens/inventory_screen.dart': 'screens/inventory_page.dart',
    'screens/collection_screen.dart': 'screens/collection_page.dart',
    'screens/quest_screen.dart': 'screens/quest_page.dart',
    'screens/my_plants_screen.dart': 'screens/user_plant_list_page.dart',
    'screens/plant_detail_screen.dart': 'screens/user_plant_detail_page.dart',
    'screens/plant_seed_screen.dart': 'screens/seed_planting_page.dart',
    'screens/collection_detail_screen.dart': 'screens/collection_detail_page.dart',
    'screens/attend_screen.dart': 'screens/attend_page.dart',
    'screens/splash_screen.dart': 'screens/splash_page.dart',
    'screens/login_screen.dart': 'screens/login_page.dart',
    'screens/signup_screen.dart': 'screens/signup_page.dart',
    'screens/main_screen.dart': 'screens/main_page.dart',
    'screens/settings_screen.dart': 'screens/settings_page.dart',
}

class_renames = {
    'HomeScreen': 'HomePage',
    '_HomeScreenState': '_HomePageState',
    'InventoryScreen': 'InventoryPage',
    'CollectionScreen': 'CollectionPage',
    'QuestScreen': 'QuestPage',
    'MyPlantsScreen': 'UserPlantListPage',
    '_MyPlantsScreenState': '_UserPlantListPageState',
    'PlantDetailScreen': 'UserPlantDetailPage',
    'PlantSeedScreen': 'SeedPlantingPage',
    'CollectionDetailScreen': 'CollectionDetailPage',
    'AttendScreen': 'AttendPage',
    'SplashScreen': 'SplashPage',
    '_SplashScreenState': '_SplashPageState',
    'LoginScreen': 'LoginPage',
    '_LoginScreenState': '_LoginPageState',
    'SignupScreen': 'SignupPage',
    '_SignupScreenState': '_SignupPageState',
    'MainScreen': 'MainPage',
    '_MainScreenState': '_MainPageState',
    'SettingsScreen': 'SettingsPage',
}

# 1. Rename files
for old_file, new_file in renames.items():
    old_path = os.path.join(base_dir, old_file)
    new_path = os.path.join(base_dir, new_file)
    if os.path.exists(old_path):
        os.rename(old_path, new_path)

# 2. Replace file contents
dart_files = glob.glob(os.path.join(base_dir, '**/*.dart'), recursive=True)

for file_path in dart_files:
    with open(file_path, 'r') as f:
        content = f.read()

    # replace imports
    for old_file, new_file in renames.items():
        old_name = os.path.basename(old_file)
        new_name = os.path.basename(new_file)
        content = content.replace(old_name, new_name)

    # replace class names
    for old_cls, new_cls in class_renames.items():
        content = content.replace(old_cls, new_cls)

    with open(file_path, 'w') as f:
        f.write(content)

print("Renamed files and classes successfully.")
