import os

def fix_syntax(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()

    # Home page syntax fixes
    content = content.replace('SnackBar(content: Text("수확이 완료되었습니다!")\n', 'SnackBar(content: Text("수확이 완료되었습니다!"))\n')
    content = content.replace('SnackBar(content: Text("수확이 완료되었습니다!")\n', 'SnackBar(content: Text("수확이 완료되었습니다!"))\n') # in case
    content = content.replace('SnackBar(content: Text(res.message)\n', 'SnackBar(content: Text(res.message)))\n')
    content = content.replace('Center(child: CircularProgressIndicator()\n', 'Center(child: CircularProgressIndicator())\n')
    content = content.replace('Center(child: Text("데이터를 불러오지 못했습니다."\n', 'Center(child: Text("데이터를 불러오지 못했습니다."))\n')
    content = content.replace('MaterialPageRoute(builder: (_) => UserPlantListPage()\n', 'MaterialPageRoute(builder: (_) => UserPlantListPage()))\n')
    content = content.replace('MaterialPageRoute(builder: (_) => SeedPlantingPage()\n', 'MaterialPageRoute(builder: (_) => SeedPlantingPage()))\n')
    content = content.replace('MaterialPageRoute(builder: (_) => UserPlantDetailPage(userPlantId: plant.userPlantId)\n', 'MaterialPageRoute(builder: (_) => UserPlantDetailPage(userPlantId: plant.userPlantId)))\n')

    with open(file_path, 'w') as f:
        f.write(content)

fix_syntax('lib/screens/home/home_page.dart')

# attend page syntax fix
def fix_attend(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()
    content = content.replace('AttendModel?', 'AttendMonth?')
    content = content.replace('checkTodayAttend()', 'attendToday()')
    with open(file_path, 'w') as f:
        f.write(content)

fix_attend('lib/screens/attend/attend_page.dart')

# inventory action sheets
def fix_sheets(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()
    content = content.replace('getUserPlantSummarys', 'getUserPlants')
    content = content.replace('SelectableUserPlantCard', 'SelectableUserPlantCard')
    content = content.replace('SelectableUserPlantCard(\n', 'SelectableUserPlantCard(\n')
    
    # We need to remove isDisabled if it's there? Wait, the SelectableUserPlantCard in lib/widgets/selectable_user_plant_card.dart
    # Let's check what it has.
    with open(file_path, 'w') as f:
        f.write(content)
        
fix_sheets('lib/screens/inventory/inventory_action_sheets.dart')
print("Syntax fixed")
