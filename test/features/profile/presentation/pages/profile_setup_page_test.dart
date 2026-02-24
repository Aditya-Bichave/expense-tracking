import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_event.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_state.dart';
import 'package:expense_tracker/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

class FakeProfileEvent extends Fake implements ProfileEvent {}

void main() {
  late MockProfileBloc mockProfileBloc;
  late MockSessionCubit mockSessionCubit;

  setUpAll(() {
    registerFallbackValue(FakeProfileEvent());
    registerFallbackValue(
      UpdateProfile(
        UserProfile(
          id: 'dummy',
          email: 'dummy',
          currency: 'USD',
          timezone: 'UTC',
        ),
      ),
    );
  });

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    mockSessionCubit = MockSessionCubit();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_timezone'), (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'getLocalTimezone') {
            return 'UTC';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          null,
        );
  });

  Widget createWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
        BlocProvider<SessionCubit>.value(value: mockSessionCubit),
      ],
      child: const MaterialApp(home: ProfileSetupPage()),
    );
  }

  testWidgets('ProfileSetupPage renders correctly', (
    WidgetTester tester,
  ) async {
    when(() => mockProfileBloc.state).thenReturn(ProfileInitial());

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Setup Profile'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Complete Setup'), findsOneWidget);
  });

  testWidgets('FetchProfile is called on init', (WidgetTester tester) async {
    when(() => mockProfileBloc.state).thenReturn(ProfileInitial());

    await tester.pumpWidget(createWidget());
    verify(() => mockProfileBloc.add(const FetchProfile())).called(1);
  });

  testWidgets('Shows loaded profile data', (WidgetTester tester) async {
    final profile = UserProfile(
      id: '1',
      email: 'test@example.com',
      fullName: 'John Doe',
      currency: 'USD',
      timezone: 'UTC',
    );

    whenListen(
      mockProfileBloc,
      Stream.fromIterable([ProfileInitial(), ProfileLoaded(profile)]),
      initialState: ProfileInitial(),
    );

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Full Name'),
    );
    expect(
      textField.controller,
      isNotNull,
      reason: 'TextField controller should not be null',
    );
    expect(textField.controller!.text, 'John Doe');
  });

  testWidgets('Submit with valid name triggers update', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);

    final profile = UserProfile(
      id: '1',
      email: 'test@example.com',
      currency: 'USD',
      timezone: 'UTC',
    );

    when(() => mockProfileBloc.state).thenReturn(ProfileLoaded(profile));

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Full Name'),
      'Jane Doe',
    );
    await tester.pump();

    await tester.tap(find.text('Complete Setup'));
    await tester.pump();

    verify(
      () => mockProfileBloc.add(any(that: isA<UpdateProfile>())),
    ).called(1);
    verify(() => mockSessionCubit.profileSetupCompleted()).called(1);
  });

  testWidgets('Submit with empty name shows error', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockProfileBloc.state).thenReturn(ProfileInitial());

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Complete Setup'));
    await tester.pumpAndSettle(); // Wait for SnackBar animation

    expect(find.text('Name is required'), findsOneWidget);
    verifyNever(() => mockProfileBloc.add(any(that: isA<UpdateProfile>())));
  });
}
