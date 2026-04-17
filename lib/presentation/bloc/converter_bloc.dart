import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_compress/video_compress.dart';
import '../../domain/entities/video_item.dart';
import '../../domain/usecases/pick_videos_usecase.dart';
import '../../domain/usecases/convert_video_usecase.dart';
import '../../domain/repositories/converter_repository.dart';
import 'converter_event.dart';
import 'converter_state.dart';

const int _maxParallel = 1; // تشغيل متسلسل لتتابع المراحل

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
    on<LoadOutputDirectoryEvent>(_onLoadOutputDirectory);
    on<SelectOutputDirectoryEvent>(_onSelectOutputDirectory);
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

    final offset = state.items.length;
    final numbered = picked.asMap().entries.map((entry) {
      final index = offset + entry.key + 1;
      return entry.value.copyWith(outputName: 'video_$index');
    }).toList();

    emit(state.copyWith(
      items: [...state.items, ...numbered],
      toastMessage: '✦ تمت إضافة ${numbered.length} فيديو',
    ));
  }

  Future<void> _onLoadOutputDirectory(
    LoadOutputDirectoryEvent event,
    Emitter<ConverterState> emit,
  ) async {
    final outputDirectory = await repository.getOutputDirectory();
    _outputDir = outputDirectory;
    emit(state.copyWith(outputDirectory: outputDirectory));
  }

  Future<void> _onSelectOutputDirectory(
    SelectOutputDirectoryEvent event,
    Emitter<ConverterState> emit,
  ) async {
    await repository.saveOutputDirectory(event.outputPath);
    _outputDir = event.outputPath;
    emit(state.copyWith(
      outputDirectory: event.outputPath,
      toastMessage: '✦ تم حفظ مجلد الإخراج',
    ));
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
          _cleanupTempFilesIfComplete();
        },
      );
    });
  }

  void _cleanupTempFilesIfComplete() {
    final active = state.items.where((i) => i.status == ConvertStatus.processing).length;
    final queued = state.items.where((i) => i.status == ConvertStatus.queued).length;
    if (active == 0 && queued == 0) {
      VideoCompress.deleteAllCache();
    }
  }

  @override
  Future<void> close() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    return super.close();
  }
}
