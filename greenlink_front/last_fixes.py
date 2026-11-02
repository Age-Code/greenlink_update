import os

def fix_last(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()

    if 'attend_page.dart' in file_path:
        content = content.replace('attendDate', 'attendedAt')
    
    if 'home_page.dart' in file_path:
        content = content.replace('return const Center(child: CircularProgressIndicator(\n    }', 'return const Center(child: CircularProgressIndicator());\n    }')

    with open(file_path, 'w') as f:
        f.write(content)

fix_last('lib/screens/attend/attend_page.dart')
fix_last('lib/screens/home/home_page.dart')
print("Last fixes")
