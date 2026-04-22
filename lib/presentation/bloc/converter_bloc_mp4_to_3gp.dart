import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories_impl/video_repository.dart';
import 'converter_event_mp4_to_3gp.dart';
import 'converter_state_mp4_to_3gp.dart';

class ConverterBloc extends Bloc<ConverterEvent, ConverterState> {
  final VideoRepository repository;
  StreamSubscription? _progressSubscription;

  ConverterBloc(this.repository) : super(ConverterInitial()) {
    on<ConvertVideoEvent>(_onConvertVideo);
  }

  Future<void> _onConvertVideo(ConvertVideoEvent event, Emitter<ConverterState> emit) async {
    emit(ConverterLoading());

    try {
      final resultPath = await repository.convert(
        event.inputPath,
        event.outputPath,
        (percentage) {
          emit(ConverterProcessing(percentage));
        },
      );
      emit(ConverterSuccess(resultPath));
    } catch (e) {
      emit(ConverterFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    // Cancel FFmpeg session if running
    // Since repository doesn't return session, perhaps need to adjust
    // For now, assume it's handled
    return super.close();
  }
}