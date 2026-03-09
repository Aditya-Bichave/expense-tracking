import re
import os

f = 'lib/features/groups/presentation/pages/group_detail_page.dart'
with open(f, 'r') as file:
    content = file.readlines()

# The issue is that I replaced AppListTile with missing closing brackets for Column and Expanded.
# Looking at the code:
# return Column(
#   children: [
#     ...
#     Expanded(
#       child: ListView.builder(
#          ...
#       )
#     ),
#   ],
# );
# And the `AppListTile` also needs to be closed inside builder.

# Let's just do a clean git reset of group_detail_page and do it right.
