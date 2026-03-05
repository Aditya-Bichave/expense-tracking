import sys

with open('test/features/auth/data/repositories/auth_repository_impl_test.dart', 'r') as f:
    content = f.read()

target = 'when(\n          () => mockDataManagement.clearAllData(),\n        ).thenAnswer((_) async => Future<void>.value());'
replacement = 'when(\n          () => mockDataManagement.clearAllData(),\n        ).thenAnswer((_) async => const Right(null));'

if target not in content:
    print("Error: Target snippet not found in the file.")
    sys.exit(1)

content = content.replace(target, replacement)

with open('test/features/auth/data/repositories/auth_repository_impl_test.dart', 'w') as f:
    f.write(content)
