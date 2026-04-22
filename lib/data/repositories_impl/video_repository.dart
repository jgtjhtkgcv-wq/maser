import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:path/path.dart' as path;

/// Handles video conversion operations using FFmpeg
class VideoRepository {
  /// Converts a video file to 3GP format with progress tracking
  ///
  /// [inputPath]: Path to the source video file (must be MP4)
  /// [outputPath]: Path where the converted file will be saved
  /// [onProgress]: Callback function to track conversion progress (0-100)
  ///
  /// Returns the final output path
  /// Throws an exception if validation fails or conversion fails
  Future<String> convert(
    String inputPath,
    String outputPath,
    void Function(int) onProgress,
  ) async {
    // Validate input file
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input file does not exist: $inputPath');
    }

    if (!inputPath.toLowerCase().endsWith('.mp4')) {
      throw Exception('Input file must be MP4 format');
    }

    // Ensure output directory exists
    final outputDir = Directory(path.dirname(outputPath));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // Handle existing output file
    var finalOutputPath = outputPath;
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(outputPath);
      final base = path.basenameWithoutExtension(outputPath);
      finalOutputPath = path.join(path.dirname(outputPath), '${base}_$timestamp$ext');
    }

    // Get video duration for accurate progress calculation
    int? durationMs;
    try {
      final mediaInfoSession = await FFprobeKit.getMediaInformation(inputPath);
      final mediaInfo = mediaInfoSession.getMediaInformation();
      final durationStr = mediaInfo?.getDuration();
      if (durationStr != null && durationStr.isNotEmpty) {
        durationMs = (double.parse(durationStr) * 1000).toInt();
      }
    } catch (e) {
      // If duration retrieval fails, continue without it
      // Progress will be approximated
    }

    // Build FFmpeg command for 3GP conversion
    final command =
        '-i "$inputPath" -vcodec h263 -acodec amr_nb -ar 8000 -ac 1 -ab 12.2k -s qcif -r 12 -preset ultrafast "$finalOutputPath"';

    // Set up progress tracking via statistics
    FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
      if (durationMs != null && durationMs! > 0) {
        final time = statistics.getTime();
        final percentage = ((time / durationMs!) * 100).clamp(0, 100).toInt();
        onProgress(percentage);
      }
    });

    // Execute FFmpeg command
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg conversion failed: $logs');
    }

    return finalOutputPath;
  }
}</content>
<parameter name="filePath">/workspaces/maser/lib/data/repositories_impl/video_repository.dart