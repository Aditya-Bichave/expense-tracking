import re

def main():
    with open('test/core/sync/sync_service_test.dart', 'r') as f:
        content = f.read()

    # Line 161 is: when(() => mockSupabaseClient.from(any())).thenReturn(mockQueryBuilder);
    # Is `mockQueryBuilder` a Future? `MockSupabaseQueryBuilder` implements `SupabaseQueryBuilder`. Does `SupabaseQueryBuilder` implement `Future`? NO.
    # What about line 161 itself? Wait, "Invalid argument(s): `thenReturn` should not be used to return a Future. Instead, use `thenAnswer((_) => future)`."

    # What if it's `when(() => mockStorageFileApi.upload(...)).thenAnswer(...)` but wait,
    # I should change `thenReturn(mockQueryBuilder)` to `thenAnswer((_) => mockQueryBuilder)` just to be safe.

    content = content.replace("when(() => mockSupabaseClient.from(any())).thenReturn(mockQueryBuilder);", "when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockQueryBuilder);")

    # I should also make sure my `FakeDeleteFilterBuilder` throws or completes. The previous run threw `Bad state: Cannot call 'when' within a stub response`.
    # `thenAnswer` should not contain `when` inside it.

    with open('test/core/sync/sync_service_test.dart', 'w') as f:
        f.write(content)

if __name__ == '__main__':
    main()
