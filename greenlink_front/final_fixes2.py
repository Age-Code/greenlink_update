import os

def fix_attend(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()

    # The previous replace didn't work properly because of _attendData!.attends
    # Let's fix everything with regex or standard string replace
    content = content.replace('_attendData!.attends', '_attendData!.days')
    content = content.replace('_attendData!.totalAttendCount', '_attendData!.attendanceCount')
    content = content.replace('_attendData!.currentStreakCount', '_attendData!.currentStreak')
    
    # Just in case
    content = content.replace('totalAttendCount', 'attendanceCount')
    content = content.replace('currentStreakCount', 'currentStreak')

    with open(file_path, 'w') as f:
        f.write(content)

fix_attend('lib/screens/attend/attend_page.dart')

def fix_login(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()
    content = content.replace("import '../../main_page.dart';", "import '../main_page.dart';")
    with open(file_path, 'w') as f:
        f.write(content)

fix_login('lib/screens/auth/login_page.dart')

def fix_home(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()
    content = content.replace('return const Center(child: CircularProgressIndicator()', 'return const Center(child: CircularProgressIndicator());')
    content = content.replace('return const Center(child: CircularProgressIndicator());;\n', 'return const Center(child: CircularProgressIndicator());\n')
    content = content.replace('return const Center(child: CircularProgressIndicator()););\n', 'return const Center(child: CircularProgressIndicator());\n')
    
    content = content.replace('return const Center(child: Text("데이터를 불러오지 못했습니다."))\n', 'return const Center(child: Text("데이터를 불러오지 못했습니다."));\n')
    content = content.replace('return const Center(child: Text("데이터를 불러오지 못했습니다."));;\n', 'return const Center(child: Text("데이터를 불러오지 못했습니다."));\n')
    content = content.replace('return const Center(child: Text("데이터를 불러오지 못했습니다.")););\n', 'return const Center(child: Text("데이터를 불러오지 못했습니다."));\n')
    
    with open(file_path, 'w') as f:
        f.write(content)
        
fix_home('lib/screens/home/home_page.dart')
print("Fixed again")
