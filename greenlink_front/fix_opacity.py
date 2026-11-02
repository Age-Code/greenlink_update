import os
import re

def fix_with_opacity(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Replace .withOpacity(X) -> .withValues(alpha: X)
    new_content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
    
    if new_content != content:
        with open(file_path, 'w') as f:
            f.write(new_content)
        print(f"Fixed: {file_path}")

for root, dirs, files in os.walk('lib'):
    # Skip generated files
    dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build']]
    for file in files:
        if file.endswith('.dart'):
            fix_with_opacity(os.path.join(root, file))

print("All withOpacity replaced with withValues(alpha:)")
