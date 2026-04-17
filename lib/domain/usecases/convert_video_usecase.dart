import '../entities/video_item.dart';
import '../repositories/converter_repository.dart';

class ConvertVideoUseCase {
  final ConverterRepository repository;
  ConvertVideoUseCase(this.repository);

  Stream<VideoItem> call(VideoItem item, String outputDir) =>
      repository.convertVideo(item, outputDir);
}
