import 'package:expense_tracker/main_shell.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// Use StatefulWidget to satisfy inheritance
class FakeStatefulNavigationShell extends StatefulWidget
    implements StatefulNavigationShell {
  @override
  final int currentIndex;

  const FakeStatefulNavigationShell({this.currentIndex = 0, super.key});

  @override
  State<FakeStatefulNavigationShell> createState() =>
      _FakeStatefulNavigationShellState();

  @override
  void goBranch(int index, {bool initialLocation = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStatefulNavigationShellState
    extends State<FakeStatefulNavigationShell> {
  @override
  Widget build(BuildContext context) => Container();
}

class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  late FakeStatefulNavigationShell fakeShell;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    fakeShell = const FakeStatefulNavigationShell(currentIndex: 0);
    mockSettingsBloc = MockSettingsBloc();

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('MainShell renders navigation bar and body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: mockSettingsBloc,
          child: MainShell(navigationShell: fakeShell),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    // Dashboard (index 0) has FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
