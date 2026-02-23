import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
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
    // Handle initial link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      add(DeepLinkReceived(initialUri));
    }

    // Handle stream
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      add(DeepLinkReceived(uri));
    });
  }

  Future<void> _onReceived(
    DeepLinkReceived event,
    Emitter<DeepLinkState> emit,
  ) async {
    // Check if it is a join link
    // https://spendos.app/join?token=... or spendos://join?token=...
    if (event.uri.path.contains('/join')) {
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
