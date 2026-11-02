import os

file_path = 'lib/screens/inventory/inventory_action_sheets.dart'
if os.path.exists(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    content = content.replace('SelectableUserPlantCard', 'SelectableUserPlantSummaryCard')
    content = content.replace('isDisabled: _selectedPlantId == null,\n', '')
    
    with open(file_path, 'w') as f:
        f.write(content)
        
print("Fixed inventory_action_sheets.dart")
