import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../../../helpers/pump_app.dart';

class MockSummaryBloc extends MockBloc<SummaryEvent, SummaryState>
    implements SummaryBloc {}

void main() {
  late MockSummaryBloc mockSummaryBloc;

  setUp(() {
    mockSummaryBloc = MockSummaryBloc();
    when(() => mockSummaryBloc.state).thenReturn(SummaryInitial());
  });

  testWidgets('SummaryCard renders loading state', (WidgetTester tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: false, // Don't settle for progress indicator
      blocProviders: [BlocProvider<SummaryBloc>.value(value: mockSummaryBloc)],
      widget: const Scaffold(body: SummaryCard()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
