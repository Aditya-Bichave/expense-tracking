import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

part 'deep_link_event.dart';
part 'deep_link_state.dart';

class DeepLinkBloc extends Bloc<DeepLinkEvent, DeepLinkState> {
  final AppLinks _appLinks;
  final GroupsRepository _groupsRepository;
  final AuthRepository _authRepository;
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkBloc(this._appLinks, this._groupsRepository, this._authRepository)
    : super(DeepLinkInitial()) {
    on<DeepLinkStarted>(_onStarted);
    on<DeepLinkReceived>(_onReceived);
    on<DeepLinkManualEntry>(_onManualEntry);
  }

  Future<void> _onStarted(
    DeepLinkStarted event,
    Emitter<DeepLinkState> emit,
  ) async {
    // 1. Handle Windows launch arguments
    if (event.args.isNotEmpty) {
      for (final arg in event.args) {
        if (arg.contains('io.supabase.expensetracker://')) {
          add(DeepLinkReceived(Uri.parse(arg)));
          break;
        }
      }
    }

    // 2. Handle initial link from app_links
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        add(DeepLinkReceived(initialUri));
      }
    } catch (e) {
      log.warning("Failed to get initial link: $e");
    }

    // 3. Handle stream for runtime links
    _linkSubscription ??= _appLinks.uriLinkStream.listen((uri) {
      add(DeepLinkReceived(uri));
    });
  }

  Future<void> _onReceived(
    DeepLinkReceived event,
    Emitter<DeepLinkState> emit,
  ) async {
    log.info("Deep link received: ${event.uri}");

    // 1. Handle Supabase Auth callback
    // io.supabase.expensetracker://login-callback#access_token=...
    if (event.uri.host == 'login-callback' ||
        event.uri.fragment.contains('access_token=')) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(event.uri);
        log.info("Supabase session obtained from URL");
        // No need to emit a state here, as AuthBloc/SessionCubit should listen to Supabase auth changes
        return;
      } catch (e) {
        log.severe("Failed to get Supabase session from URL: $e");
        emit(DeepLinkError("Authentication failed: $e"));
        return;
      }
    }

    // 2. Check if it is a join link
    // Support both https://spendos.app/join and spendos://join
    if (event.uri.path.contains('/join') || event.uri.host == 'join') {
      final token = event.uri.queryParameters['token'];
      if (token != null) {
        await _handleJoin(token, emit);
      }
    }
  }

  Future<void> _onManualEntry(
    DeepLinkManualEntry event,
    Emitter<DeepLinkState> emit,
  ) async {
    await _handleJoin(event.token, emit);
  }

  Future<void> _handleJoin(String token, Emitter<DeepLinkState> emit) async {
    emit(DeepLinkProcessing());

    try {
      // 1. Check Auth
      final currentUser = _authRepository.getCurrentUser().fold(
        (_) => null,
        (user) => user,
      );
      if (currentUser == null) {
        // Log in anonymously
        final authResult = await _authRepository.signInAnonymously();
        if (authResult.isLeft()) {
          emit(const DeepLinkError("Failed to sign in anonymously"));
          return;
        }
      }

      // 2. Call Edge Function
      final result = await _groupsRepository.acceptInvite(token);
      await result.fold(
        (failure) async => emit(DeepLinkError(failure.message)),
        (data) async {
          final groupId = data['group_id'] as String;
          final groupName = data['group_name'] as String?;

          // 3. Sync groups to ensure the new group is visible locally
          await _groupsRepository.syncGroups();

          emit(DeepLinkSuccess(groupId: groupId, groupName: groupName));
        },
      );
    } catch (e) {
      emit(DeepLinkError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _linkSubscription?.cancel();
    return super.close();
  }
}
