import 'package:equatable/equatable.dart';

abstract class ConverterState extends Equatable {
  const ConverterState();

  @override
  List<Object?> get props => [];
}

class ConverterInitial extends ConverterState {}

class ConverterLoading extends ConverterState {}

class ConverterProcessing extends ConverterState {
  final int percentage;

  const ConverterProcessing(this.percentage);

  @override
  List<Object?> get props => [percentage];
}

class ConverterSuccess extends ConverterState {
  final String path;

  const ConverterSuccess(this.path);

  @override
  List<Object?> get props => [path];
}

class ConverterFailure extends ConverterState {
  final String message;

  const ConverterFailure(this.message);

  @override
  List<Object?> get props => [message];
}