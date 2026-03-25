import 'package:expense_tracker/core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'record_settlement_event.dart';
import 'record_settlement_state.dart';

class RecordSettlementBloc
    extends Bloc<RecordSettlementEvent, RecordSettlementState> {
  final SupabaseClient supabase;
  final AuthSessionService authSessionService;
  final ImageCompressionService imageCompressionService;
  final _log = Logger('RecordSettlementBloc');
  final Uuid _uuid = const Uuid();

  RecordSettlementBloc({
    required this.supabase,
    required this.authSessionService,
    required this.imageCompressionService,
    required double initialAmount,
  }) : super(RecordSettlementState(amount: initialAmount)) {
    on<AmountChanged>(_onAmountChanged);
    on<NoteChanged>(_onNoteChanged);
    on<ImageAttached>(_onImageAttached);
    on<RemoveImage>(_onRemoveImage);
    on<SubmitSettlement>(_onSubmitSettlement);
    on<ConfirmReturnedFromUpi>(_onConfirmReturnedFromUpi);
  }

  void _onAmountChanged(
    AmountChanged event,
    Emitter<RecordSettlementState> emit,
  ) {
    emit(state.copyWith(amount: event.amount, status: FormStatus.editing));
  }

  void _onNoteChanged(NoteChanged event, Emitter<RecordSettlementState> emit) {
    emit(state.copyWith(note: event.note, status: FormStatus.editing));
  }

  void _onImageAttached(
    ImageAttached event,
    Emitter<RecordSettlementState> emit,
  ) {
    emit(
      state.copyWith(attachedImage: event.image, status: FormStatus.editing),
    );
  }

  void _onRemoveImage(RemoveImage event, Emitter<RecordSettlementState> emit) {
    emit(state.copyWith(clearImage: true, status: FormStatus.editing));
  }

  void _onConfirmReturnedFromUpi(
    ConfirmReturnedFromUpi event,
    Emitter<RecordSettlementState> emit,
  ) {
    emit(state.copyWith(waitingForUpiConfirmation: true));
  }

  Future<void> _onSubmitSettlement(
    SubmitSettlement event,
    Emitter<RecordSettlementState> emit,
  ) async {
    if (state.status == FormStatus.processing) return;

    emit(
      state.copyWith(
        status: FormStatus.processing,
        clearError: true,
        waitingForUpiConfirmation: false,
      ),
    );

    try {
      final currentUser = authSessionService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      String? proofUrl;

      if (state.attachedImage != null) {
        try {
          final compressedXFile = await imageCompressionService.compressImage(
            state.attachedImage!.path,
          );
          if (compressedXFile != null) {
            final path = 'proofs/${_uuid.v4()}.jpg';
            await supabase.storage
                .from('settlement_proofs')
                .uploadBinary(path, await compressedXFile.readAsBytes());
            proofUrl = supabase.storage
                .from('settlement_proofs')
                .getPublicUrl(path);
          }
        } catch (e, s) {
      log.severe("Msg: $e\n$s");
          _log.severe('Failed to compress or upload image: $e\n$s');
        }
      }

      await supabase.from('settlements').insert({
        'group_id': event.groupId,
        'from_user_id': currentUser.id,
        'to_user_id': event.receiverId,
        'amount': state.amount,
        'currency': event.currency,
        'note': state.note,
        'proof_url': proofUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      emit(state.copyWith(status: FormStatus.success));
    } catch (e, s) {
      log.severe("Msg: $e\n$s");
      _log.severe('Failed to record settlement: $e\n$s');
      emit(
        state.copyWith(status: FormStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
