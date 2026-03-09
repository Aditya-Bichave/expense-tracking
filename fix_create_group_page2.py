import re

f = 'lib/features/groups/presentation/pages/create_group_page.dart'
with open(f, 'r') as file:
    content = file.read()

# remove @override from Future<void> _pickImage()
content = content.replace("  @override\n  Future<void> _pickImage()", "  Future<void> _pickImage()")

# Fix kit.colors.surfaceContainerHigh
content = content.replace("kit.colors.surfaceContainerHigh", "kit.colors.elevated")
content = content.replace("backgroundColor: kit.colors.elevated", "backgroundColor: kit.colors.elevated") # if elevated is defined, let's just use kit.colors.borderSubtle or kit.colors.elevated. Let's just use kit.colors.borderSubtle to be safe.

# In AppColors we had `Color get elevated => _scheme.surfaceContainerHigh;` and `Color get surfaceContainer => _scheme.surfaceContainer;`. We can use `kit.colors.surfaceContainer`. Or just `kit.colors.bg`.
content = content.replace("kit.colors.elevated", "kit.colors.bg")

with open(f, 'w') as file:
    file.write(content)
