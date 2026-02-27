import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_event.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_state.dart';
import 'package:expense_tracker/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockSessionCubit extends MockBloc<void, SessionState>
    implements SessionCubit {}

void main() {
  late MockProfileBloc mockProfileBloc;
  late MockSessionCubit mockSessionCubit;

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    mockSessionCubit = MockSessionCubit();
    registerFallbackValue(
      const UpdateProfile(UserProfile(id: '', currency: '', timezone: '')),
    );
  });

  Widget createWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
          BlocProvider<SessionCubit>.value(value: mockSessionCubit),
        ],
        child: const ProfileSetupPage(),
      ),
    );
  }

  testWidgets('ProfileSetupPage renders all fields including UPI ID', (
    tester,
  ) async {
    whenListen(
      mockProfileBloc,
      Stream.fromIterable([
        ProfileLoading(),
        const ProfileLoaded(
          UserProfile(
            id: '1',
            fullName: 'Test User',
            email: 'test@test.com',
            currency: 'USD',
            timezone: 'UTC',
            upiId: 'test@upi',
          ),
        ),
      ]),
      initialState: ProfileLoading(),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump(); // Frame for Loading
    await tester.pump(); // Frame for Loaded
    await tester.pumpAndSettle(); // Allow listener to update text fields

    expect(find.text('Setup Profile'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('UPI ID (VPA)'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);

    // Verify initial values in Controllers by accessing the AppTextField widgets
    final nameField = tester.widget<AppTextField>(
      find.widgetWithText(AppTextField, 'Full Name'),
    );
    expect(nameField.controller?.text, 'Test User');

    final upiField = tester.widget<AppTextField>(
      find.widgetWithText(AppTextField, 'UPI ID (VPA)'),
    );
    expect(upiField.controller?.text, 'test@upi');
  });

  testWidgets(
    'Submitting form dispatches UpdateProfile event with new values',
    (tester) async {
      final initialProfile = const UserProfile(
        id: '1',
        fullName: 'Old Name',
        email: 'test@test.com',
        currency: 'USD',
        timezone: 'UTC',
      );

      when(
        () => mockProfileBloc.state,
      ).thenReturn(ProfileLoaded(initialProfile));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter new Name
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Full Name'),
        'New Name',
      );

      // Enter UPI ID
      await tester.enterText(
        find.widgetWithText(AppTextField, 'UPI ID (VPA)'),
        'new@upi',
      );
      await tester.pump();

      // Tap Complete
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();

      verify(
        () => mockProfileBloc.add(
          any(
            that: isA<UpdateProfile>()
                .having((e) => e.profile.fullName, 'fullName', 'New Name')
                .having((e) => e.profile.upiId, 'upiId', 'new@upi'),
          ),
        ),
      ).called(1);

      verify(() => mockSessionCubit.profileSetupCompleted()).called(1);
    },
  );

  testWidgets('Validates required name field', (tester) async {
    final initialProfile = const UserProfile(
      id: '1',
      fullName: null,
      email: 'test@test.com',
      currency: 'USD',
      timezone: 'UTC',
    );

    when(() => mockProfileBloc.state).thenReturn(ProfileLoaded(initialProfile));

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap Complete without entering name
    await tester.tap(find.text('Complete Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);

    // Verify UpdateProfile was NOT called. FetchProfile IS called in initState.
    verifyNever(() => mockProfileBloc.add(any(that: isA<UpdateProfile>())));
  });
}
