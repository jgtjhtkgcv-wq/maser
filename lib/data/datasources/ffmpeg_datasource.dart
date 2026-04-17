import 'dart:async';

// FIX: استخدام الحزمة الكاملة ffmpeg_kit_flutter_full
// تضمن دعم: H.263, AMR-NB (opencore-amr), 3GP, وكل الترميزات الكلاسيكية
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/statistics.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';

/// ═══════════════════════════════════════════════════════════════════
/// المعيار الذهبي لتحويل الفيديو لهواتف itel والشاشات الصغيرة:
///
///   -i input
///   -vcodec h263          ← ترميز فيديو H.263 (دعم كامل على الأجهزة القديمة)
///   -pix_fmt yuv420p      ← تنسيق ألوان YUV 4:2:0 (متوافق مع كل الشاشات)
///   -acodec amr_nb        ← ترميز صوت AMR-NB (المعيار في 3GP)
///   -ar 8000              ← معدل عينات الصوت: 8000 Hz
///   -ac 1                 ← قناة صوتية واحدة (Mono)
///   -ab 12.2k             ← معدل بت الصوت: 12.2 kbps (AMR-NB القياسي)
///   -s 176x144            ← دقة QCIF (القياس الأمثل لـ itel وشاشات 128px)
///   output.3gp
/// ═══════════════════════════════════════════════════════════════════
class FfmpegDatasource {
  /// يحوّل [inputPath] إلى 3GP باستخدام إعدادات itel الذهبية.
  /// يُرسل قيم progress من 0.0 إلى 1.0 عبر [onProgress].
  Future<bool> convertTo3gp({
    required String inputPath,
    required String outputPath,
    required double videoDurationSec,
    required void Function(double) onProgress,
    required void Function(String) onLog,
  }) async {
    final completer = Completer<bool>();

    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
      if (videoDurationSec > 0) {
        final timeSec = stats.getTime() / 1000.0;
        final prog = (timeSec / videoDurationSec).clamp(0.0, 1.0);
        onProgress(prog);
      }
    });

    FFmpegKitConfig.enableLogCallback((Log log) {
      onLog(log.getMessage());
    });

    // ─── أمر FFmpeg — المعيار الذهبي لـ itel ─────────────────────────────
    // تم تحديثه وفق المواصفات المطلوبة:
    //   • -vcodec h263        : ترميز الفيديو
    //   • -pix_fmt yuv420p    : تنسيق الألوان (حل مشكلة Codec Incompatible)
    //   • -acodec amr_nb      : ترميز الصوت AMR-NB
    //   • -ar 8000            : 8000 Hz (معيار AMR-NB)
    //   • -ac 1               : Mono
    //   • -ab 12.2k           : 12.2 kbps (AMR-NB القياسي)
    //   • -s 176x144          : دقة QCIF
    //   • -y                  : الكتابة فوق الملف الموجود
    final command = [
      '-y',
      '-i', '"$inputPath"',
      '-vcodec', 'h263',
      '-pix_fmt', 'yuv420p',
      '-acodec', 'amr_nb',
      '-ar', '8000',
      '-ac', '1',
      '-ab', '12.2k',
      '-s', '176x144',
      '"$outputPath"',
    ].join(' ');

    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final rc = await session.getReturnCode();
        completer.complete(ReturnCode.isSuccess(rc));
      },
    );

    return completer.future;
  }
}
