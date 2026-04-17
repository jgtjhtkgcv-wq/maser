import 'dart:async';
import 'dart:io';

import 'package:video_compress/video_compress.dart';

/// ═══════════════════════════════════════════════════════════════════
/// استخدام VideoCompress لضغط الفيديو ونقل الناتج إلى المجلد المحدد.
/// ═══════════════════════════════════════════════════════════════════
class VideoCompressDatasource {
  /// يحوّل [inputPath] إلى ملف مضغوط باستخدام VideoCompress.
  /// يُرسل قيم progress من 0.0 إلى 1.0 عبر [onProgress].
  Future<bool> convertTo3gp({
    required String inputPath,
    required String outputPath,
    required void Function(double) onProgress,
    required void Function(String) onLog,
  }) async {
    final subscription = VideoCompress.compressProgress$.subscribe((progress) {
      final prog = (progress / 100.0).clamp(0.0, 1.0);
      onProgress(prog);
    });

    try {
      final info = await VideoCompress.compressVideo(
        inputPath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      final resultPath = info?.path;
      if (resultPath == null || resultPath.isEmpty) {
        onLog('VideoCompress failed: no output path returned');
        return false;
      }

      onLog('VideoCompress completed: $resultPath');
      onProgress(1.0);

      final compressedFile = File(resultPath);
      if (!await compressedFile.exists()) {
        onLog('VideoCompress failed: compressed file not found');
        return false;
      }

      final movedFile = File(outputPath);
      await movedFile.parent.create(recursive: true);
      if (await movedFile.exists()) {
        await movedFile.delete();
      }

      await compressedFile.copy(outputPath);
      await compressedFile.delete();

      return true;
    } catch (error) {
      onLog(error.toString());
      return false;
    } finally {
      subscription.unsubscribe();
    }
  }
}
