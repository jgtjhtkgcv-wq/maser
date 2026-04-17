import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/video_item.dart';
import '../../domain/usecases/pick_videos_usecase.dart';
import '../../domain/usecases/convert_video_usecase.dart';
import '../../domain/repositories/converter_repository.dart';
import 'converter_event.dart';
import 'converter_state.dart';

const int _maxParallel = 2; // توازي محدود لتوفير RAM

class ConverterBloc extends Bloc<ConverterEvent, ConverterState> {
  final PickVideosUseCase pickVideos;
  final ConvertVideoUseCase convertVideo;
  final ConverterRepository repository;

  String? _outputDir;
  final Map<String, StreamSubscription<VideoItem>> _subs = {};

  ConverterBloc({
    required this.pickVideos,
    required this.convertVideo,
    required this.repository,
  }) : super(const ConverterState()) {
    on<PickVideosEvent>(_onPick);
    on<ConvertAllEvent>(_onConvertAll);
    on<RetryItemEvent>(_onRetry);
    on<RemoveItemEvent>(_onRemove);
    on<RenameItemEvent>(_onRename);
    on<ClearDoneEvent>(_onClearDone);
    on<ItemProgressEvent>(_onItemProgress);
  }

  Future<void> _ensureOutputDir() async {
    _outputDir ??= await repository.getOutputDirectory();
  }

  Future<void> _onPick(PickVideosEvent event, Emitter<ConverterState> emit) async {
    final picked = await pickVideos();
    if (picked.isEmpty) return;
    final updated = [...state.items, ...picked];
    emit(state.copyWith(
      items: updated,
      toastMessage: '✦ تمت إضافة ${picked.length} فيديو',
    ));
    add(ConvertAllEvent());
  }

  void _onConvertAll(ConvertAllEvent event, Emitter<ConverterState> emit) {
    _triggerQueue();
  }

  void _onRetry(RetryItemEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      if (i.id == event.itemId) {
        return i.copyWith(status: ConvertStatus.queued, progress: 0.0);
      }
      return i;
    }).toList();
    emit(state.copyWith(items: items));
    _triggerQueue();
  }

  void _onRemove(RemoveItemEvent event, Emitter<ConverterState> emit) {
    _subs[event.itemId]?.cancel();
    _subs.remove(event.itemId);
    final items = state.items.where((i) => i.id != event.itemId).toList();
    emit(state.copyWith(items: items));
  }

  void _onRename(RenameItemEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      if (i.id == event.itemId) return i.copyWith(outputName: event.newName);
      return i;
    }).toList();
    emit(state.copyWith(items: items));
  }

  void _onClearDone(ClearDoneEvent event, Emitter<ConverterState> emit) {
    final items = state.items.where((i) => i.status != ConvertStatus.done).toList();
    emit(state.copyWith(items: items));
  }

  void _onItemProgress(ItemProgressEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      return i.id == event.item.id ? event.item : i;
    }).toList();
    emit(state.copyWith(items: items));
  }

  void _triggerQueue() {
    final active = state.items.where((i) => i.status == ConvertStatus.processing).length;
    final queued = state.items.where((i) => i.status == ConvertStatus.queued).toList();
    final slots  = _maxParallel - active;
    for (var i = 0; i < slots && i < queued.length; i++) {
      _startConvert(queued[i]);
    }
  }

  void _startConvert(VideoItem item) {
    _ensureOutputDir().then((_) {
      final stream = convertVideo(item, _outputDir!);
      _subs[item.id] = stream.listen(
        (updated) => add(ItemProgressEvent(updated)),
        onDone: () {
          _subs.remove(item.id);
          _triggerQueue();
        },
      );
    });
  }

  @override
  Future<void> close() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    return super.close();
  }
}
