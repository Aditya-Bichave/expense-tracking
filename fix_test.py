with open('test/features/auth/data/repositories/auth_repository_impl_test.dart', 'r') as f:
    content = f.read()

content = content.replace(
    'when(\n          () => mockDataManagement.clearAllData(),\n        ).thenAnswer((_) async => Future<void>.value());',
    'when(\n          () => mockDataManagement.clearAllData(),\n        ).thenAnswer((_) async => const Right(null));'
)

with open('test/features/auth/data/repositories/auth_repository_impl_test.dart', 'w') as f:
    f.write(content)
