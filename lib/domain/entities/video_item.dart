import 'package:equatable/equatable.dart';

enum ConvertStatus { queued, processing, done, error }

class VideoItem extends Equatable {
  final String id;
  final String sourcePath;
  final String outputName;
  final String size;
  final String duration;
  final ConvertStatus status;
  final double progress;
  final String? errorMessage;

  const VideoItem({
    required this.id,
    required this.sourcePath,
    required this.outputName,
    required this.size,
    required this.duration,
    this.status = ConvertStatus.queued,
    this.progress = 0.0,
    this.errorMessage,
  });

  VideoItem copyWith({
    String? id,
    String? sourcePath,
    String? outputName,
    String? size,
    String? duration,
    ConvertStatus? status,
    double? progress,
    String? errorMessage,
  }) =>
      VideoItem(
        id: id ?? this.id,
        sourcePath: sourcePath ?? this.sourcePath,
        outputName: outputName ?? this.outputName,
        size: size ?? this.size,
        duration: duration ?? this.duration,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        id, sourcePath, outputName, size, duration, status, progress, errorMessage
      ];
}
