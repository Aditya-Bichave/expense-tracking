import json

with open('linear_issues.json', 'r') as f:
    data = json.load(f)

for issue in data['issues']:
    if issue['status'] not in ['Done', 'Canceled', 'Duplicate']:
        print(f"{issue['identifier']} - {issue['title']} ({issue['status']}) - {issue['priority']['name']} - {issue.get('description', '')[:50]}")
