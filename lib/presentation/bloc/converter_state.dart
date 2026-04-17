import 'package:equatable/equatable.dart';
import '../../domain/entities/video_item.dart';

class ConverterState extends Equatable {
  final List<VideoItem> items;
  final String? toastMessage;

  const ConverterState({
    this.items = const [],
    this.toastMessage,
  });

  ConverterState copyWith({
    List<VideoItem>? items,
    String? toastMessage,
  }) =>
      ConverterState(
        items: items ?? this.items,
        toastMessage: toastMessage,
      );

  int get total       => items.length;
  int get doneCount   => items.where((i) => i.status == ConvertStatus.done).length;
  int get activeCount => items.where((i) => i.status == ConvertStatus.processing).length;
  int get errorCount  => items.where((i) => i.status == ConvertStatus.error).length;

  @override
  List<Object?> get props => [items, toastMessage];
}
