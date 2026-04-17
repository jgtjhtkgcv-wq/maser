import '../entities/video_item.dart';

abstract class ConverterRepository {
  Future<List<VideoItem>> pickVideos();
  Stream<VideoItem> convertVideo(VideoItem item, String outputDir);
  Future<String> getOutputDirectory();
}
