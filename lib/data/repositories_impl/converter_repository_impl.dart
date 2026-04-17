import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/video_item.dart';
import '../../domain/repositories/converter_repository.dart';
import '../datasources/ffmpeg_datasource.dart';

class ConverterRepositoryImpl implements ConverterRepository {
  final FfmpegDatasource ffmpeg;
  ConverterRepositoryImpl(this.ffmpeg);

  @override
  Future<List<VideoItem>> pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return [];

    return result.files.map((f) {
      final sizeBytes = f.size;
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return VideoItem(
        id: '${f.name}_${DateTime.now().microsecondsSinceEpoch}',
        sourcePath: f.path ?? '',
        outputName: p.basenameWithoutExtension(f.name),
        size: '$sizeMb MB',
        duration: '--:--',
        status: ConvertStatus.queued,
      );
    }).toList();
  }

  @override
  Future<String> getOutputDirectory() async {
    final Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/Youssef_Jaber_Converter');
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/Youssef_Jaber_Converter');
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  @override
  Stream<VideoItem> convertVideo(VideoItem item, String outputDir) {
    final controller = StreamController<VideoItem>();

    Future<void> run() async {
      controller.add(item.copyWith(status: ConvertStatus.processing, progress: 0.0));

      final outputPath = p.join(outputDir, '${item.outputName}.3gp');
      const fallbackDuration = 120.0;

      final success = await ffmpeg.convertTo3gp(
        inputPath: item.sourcePath,
        outputPath: outputPath,
        videoDurationSec: fallbackDuration,
        onProgress: (prog) {
          controller.add(item.copyWith(
            status: ConvertStatus.processing,
            progress: prog,
          ));
        },
        onLog: (_) {},
      );

      if (success) {
        controller.add(item.copyWith(status: ConvertStatus.done, progress: 1.0));
      } else {
        controller.add(item.copyWith(
          status: ConvertStatus.error,
          errorMessage: 'FFmpeg فشل · تحقق من صلاحيات الملف أو صحة التنسيق',
        ));
      }
    }

    run().catchError((e) {
      controller.add(item.copyWith(
        status: ConvertStatus.error,
        errorMessage: e.toString(),
      ));
    }).whenComplete(() => controller.close());

    return controller.stream;
  }
}
