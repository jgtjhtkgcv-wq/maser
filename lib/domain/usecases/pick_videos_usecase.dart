import '../entities/video_item.dart';
import '../repositories/converter_repository.dart';

class PickVideosUseCase {
  final ConverterRepository repository;
  PickVideosUseCase(this.repository);

  Future<List<VideoItem>> call() => repository.pickVideos();
}
