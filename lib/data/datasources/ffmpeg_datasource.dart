import 'dart:async';
import 'dart:io';

import 'package:light_compressor/light_compressor.dart';
import 'package:path/path.dart' as p;

/// ═══════════════════════════════════════════════════════════════════
/// استخدام LightCompressor لضغط الفيديو مع جودة متوافقة مع الأجهزة القديمة.
/// ═══════════════════════════════════════════════════════════════════
class LightCompressorDatasource {
  /// يحوّل [inputPath] إلى ملف مضغوط باستخدام LightCompressor.
  /// يُرسل قيم progress من 0.0 إلى 1.0 عبر [onProgress].
  Future<bool> convertTo3gp({
    required String inputPath,
    required String outputPath,
    required double videoDurationSec,
    required void Function(double) onProgress,
    required void Function(String) onLog,
  }) async {
    final compressor = LightCompressor();
    final subscription = compressor.onProgressUpdated.listen((progress) {
      final prog = (progress / 100.0).clamp(0.0, 1.0);
      onProgress(prog);
    });

    try {
      final result = await compressor.compressVideo(
        path: inputPath,
        videoQuality: VideoQuality.very_low,
        isMinBitrateCheckEnabled: false,
        video: Video(
          videoName: p.basenameWithoutExtension(outputPath),
          keepOriginalResolution: true,
        ),
        android: AndroidConfig(isSharedStorage: true, saveAt: SaveAt.Movies),
        ios: IOSConfig(saveInGallery: false),
      );

      if (result is OnSuccess) {
        onLog('LightCompressor completed: ${result.destinationPath}');
        final outputFile = File(outputPath);
        if (result.destinationPath != outputPath) {
          await outputFile.parent.create(recursive: true);
          await File(result.destinationPath).copy(outputPath);
        }
        onProgress(1.0);
        return true;
      }

      if (result is OnFailure) {
        onLog('LightCompressor failed: ${result.message}');
      } else if (result is OnCancelled) {
        onLog('LightCompressor cancelled');
      }

      return false;
    } catch (error) {
      onLog(error.toString());
      return false;
    } finally {
      await subscription.cancel();
    }
  }
}
