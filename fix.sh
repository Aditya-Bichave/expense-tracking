#!/bin/bash
sed -i "s/when(() => mockSupabaseClient.from(any())).thenReturn(mockQueryBuilder);/ /g" test/core/sync/sync_service_test.dart
