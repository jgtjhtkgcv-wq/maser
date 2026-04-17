import 'package:equatable/equatable.dart';
import '../../domain/entities/video_item.dart';

abstract class ConverterEvent extends Equatable {
  const ConverterEvent();
  @override
  List<Object?> get props => [];
}

class PickVideosEvent extends ConverterEvent {}
class ConvertAllEvent extends ConverterEvent {}
class LoadOutputDirectoryEvent extends ConverterEvent {}
class SelectOutputDirectoryEvent extends ConverterEvent {
  final String outputPath;
  const SelectOutputDirectoryEvent(this.outputPath);
  @override
  List<Object?> get props => [outputPath];
}

class RetryItemEvent extends ConverterEvent {
  final String itemId;
  const RetryItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class RemoveItemEvent extends ConverterEvent {
  final String itemId;
  const RemoveItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class RenameItemEvent extends ConverterEvent {
  final String itemId;
  final String newName;
  const RenameItemEvent(this.itemId, this.newName);
  @override
  List<Object?> get props => [itemId, newName];
}

class ClearDoneEvent extends ConverterEvent {}

class ItemProgressEvent extends ConverterEvent {
  final VideoItem item;
  const ItemProgressEvent(this.item);
  @override
  List<Object?> get props => [item];
}
