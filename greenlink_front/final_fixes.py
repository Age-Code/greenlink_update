import os

def fix_attend(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()

    content = content.replace('res.data!.streakCount', 'res.data!.streakDays')
    content = content.replace('res.data!.streakDays', 'res.data!.streakDays') # prevent double replacement
    content = content.replace('!_attendData!.attends', '!_attendData!.days')
    content = content.replace('_attendData!.totalAttendCount', '_attendData!.attendanceCount')
    content = content.replace('_attendData!.currentStreakCount', '_attendData!.currentStreak')
    content = content.replace('_attendData!.attends.any', '_attendData!.days.any')
    content = content.replace('dayData.attendedAt', 'dayData.attendedAt') # should be fine

    with open(file_path, 'w') as f:
        f.write(content)

fix_attend('lib/screens/attend/attend_page.dart')

def fix_login(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()
    content = content.replace("import 'main_page.dart';", "import '../../main_page.dart';")
    with open(file_path, 'w') as f:
        f.write(content)

fix_login('lib/screens/auth/login_page.dart')

# fix home_page.dart syntax
def fix_home(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Needs import '../../models/home_models.dart';
    if "import '../../models/home_models.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../models/home_models.dart';")

    # Syntax fixes. Let's fix them correctly.
    content = content.replace('SnackBar(content: Text("수확이 완료되었습니다!"))\n', 'SnackBar(content: const Text("수확이 완료되었습니다!")));\n')
    content = content.replace('SnackBar(content: Text(res.message)))\n', 'SnackBar(content: Text(res.message)));\n')
    content = content.replace('return const Center(child: CircularProgressIndicator())\n', 'return const Center(child: CircularProgressIndicator());\n')
    content = content.replace('return const Center(child: Text("데이터를 불러오지 못했습니다."))\n', 'return const Center(child: Text("데이터를 불러오지 못했습니다."));\n')
    content = content.replace('MaterialPageRoute(builder: (_) => UserPlantListPage()))\n', 'MaterialPageRoute(builder: (_) => UserPlantListPage()));\n')
    content = content.replace('MaterialPageRoute(builder: (_) => SeedPlantingPage()))\n', 'MaterialPageRoute(builder: (_) => SeedPlantingPage()));\n')
    content = content.replace('MaterialPageRoute(builder: (_) => UserPlantDetailPage(userPlantId: plant.userPlantId)))\n', 'MaterialPageRoute(builder: (_) => UserPlantDetailPage(userPlantId: plant.userPlantId)));\n')

    with open(file_path, 'w') as f:
        f.write(content)

fix_home('lib/screens/home/home_page.dart')

print("Fixed attend, login, home")
