import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nudge_event.dart';
import 'nudge_state.dart';

class NudgeBloc extends Bloc<NudgeEvent, NudgeState> {
  final SupabaseClient supabase;
  final _log = Logger('NudgeBloc');

  NudgeBloc({required this.supabase}) : super(NudgeInitial()) {
    on<SendNudge>(_onSendNudge);
  }

  Future<void> _onSendNudge(SendNudge event, Emitter<NudgeState> emit) async {
    final targetUserId = event.debt.fromUserId;
    emit(NudgeSending(targetUserId));

    try {
      final response = await supabase.functions.invoke(
        'send-nudge',
        body: {
          'group_id': event.groupId,
          'target_user_id': targetUserId,
          'amount_owed': event.debt.amount,
          'currency': 'INR',
        },
      );

      emit(NudgeSuccess(targetUserId));
    } catch (e, s) {
      _log.severe('Failed to send nudge', e, s);

      String message = 'Could not send nudge.';
      if (e is FunctionException) {
        if (e.status == 429) {
          message = 'Whoa there! You can only nudge once every few minutes.';
        } else if (e.status == 404) {
          message = 'User has no registered devices to receive nudges.';
        } else if (e.reasonPhrase != null) {
          message = e.reasonPhrase!;
        }
      } else {
        message = e.toString();
        if (message.contains('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
      }

      emit(NudgeFailure(userId: targetUserId, message: message));
    }
  }
}
