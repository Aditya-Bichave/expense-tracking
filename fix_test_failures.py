import re

# 1. Fix create_group_event_test.dart
f = 'test/features/groups/presentation/bloc/create_group/create_group_event_test.dart'
with open(f, 'r') as file:
    content = file.read()
# We added photoFile: null by default in the props.
content = content.replace("['Test', GroupType.trip, 'USD', 'u1']", "['Test', GroupType.trip, 'USD', 'u1', null]")
with open(f, 'w') as file:
    file.write(content)

# 2. Fix Goal_test.dart (Goal copyWith with value getter should allow nulling nullable fields)
f = 'test/features/goals/domain/entities/goal_test.dart'
try:
    with open(f, 'r') as file:
        content = file.read()
    # If the test is failing, maybe we added something to Goal or the test expects a specific output.
    # The error wasn't fully visible. Let's run just this test to see.
except:
    pass
