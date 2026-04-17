import 'package:equatable/equatable.dart';
import '../../domain/entities/video_item.dart';

class ConverterState extends Equatable {
  final List<VideoItem> items;
  final String? toastMessage;
  final String? outputDirectory;

  const ConverterState({
    this.items = const [],
    this.toastMessage,
    this.outputDirectory,
  });

  ConverterState copyWith({
    List<VideoItem>? items,
    String? toastMessage,
    String? outputDirectory,
  }) =>
      ConverterState(
        items: items ?? this.items,
        toastMessage: toastMessage,
        outputDirectory: outputDirectory ?? this.outputDirectory,
      );

  int get total       => items.length;
  int get doneCount   => items.where((i) => i.status == ConvertStatus.done).length;
  int get activeCount => items.where((i) => i.status == ConvertStatus.processing).length;
  int get errorCount  => items.where((i) => i.status == ConvertStatus.error).length;

  @override
  List<Object?> get props => [items, toastMessage, outputDirectory];
}
