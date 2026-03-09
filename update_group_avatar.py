import re

f = 'lib/features/groups/presentation/pages/group_list_page.dart'
with open(f, 'r') as file:
    content = file.read()

replacement = """                  leading: AppAvatar(
                    initials: _getInitialsForGroup(group.name),
                    imageUrl: group.photoUrl,
                    backgroundColor: kit.colors.primaryContainer,
                    foregroundColor: kit.colors.onPrimaryContainer,
                  ),"""

content = content.replace("""                  leading: AppAvatar(
                    initials: _getInitialsForGroup(group.name),
                    backgroundColor: kit.colors.primaryContainer,
                    foregroundColor: kit.colors.onPrimaryContainer,
                  ),""", replacement)

with open(f, 'w') as file:
    file.write(content)
