import 'package:equatable/equatable.dart';

abstract class ConverterEvent extends Equatable {
  const ConverterEvent();

  @override
  List<Object?> get props => [];
}

class ConvertVideoEvent extends ConverterEvent {
  final String inputPath;
  final String outputPath;

  const ConvertVideoEvent(this.inputPath, this.outputPath);

  @override
  List<Object?> get props => [inputPath, outputPath];
}