import re

f = 'lib/features/groups/presentation/widgets/group_balance_card.dart'
with open(f, 'r') as file:
    content = file.read()
# Let's change to kit.typography.bodyStrong or kit.typography.title
content = content.replace("kit.typography.h3", "kit.typography.title")
with open(f, 'w') as file:
    file.write(content)
