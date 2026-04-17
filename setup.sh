#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║         YOUSSEF JABER VIDEO CONVERTER — Flutter Setup v3.0 PROD         ║
# ║         Clean Architecture + BLoC + FFmpeg → 3GP (itel Golden Profile)  ║
# ║         Supports: Android  |  minSdk: 24                                ║
# ║                                                                          ║
# ║  🔧 PRODUCTION FIXES v3.0:                                               ║
# ║  • ffmpeg_kit_flutter_full (Full Package — دعم كامل لكل الترميزات)      ║
# ║  • gradle.properties تُكتب محلياً داخل المشروع (2GB Java heap)          ║
# ║  • local.properties من $ANDROID_HOME تلقائياً                           ║
# ║  • أمر FFmpeg المحدَّث للمعيار الذهبي لهواتف itel                       ║
# ║    (-vcodec h263 -pix_fmt yuv420p -acodec amr_nb -ar 8000 -s 176x144)  ║
# ║  • أذونات READ/WRITE في AndroidManifest.xml كاملة                       ║
# ║  • وسيط --no-build لتوليد الكود فقط بدون بناء محلي                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ════════════════════════════════════════════════════════════════════════════
# معالجة الوسيطات (Arguments)
# --no-build : توليد الكود فقط بدون flutter build apk
# ════════════════════════════════════════════════════════════════════════════
NO_BUILD=false
for arg in "$@"; do
  case "$arg" in
    --no-build)
      NO_BUILD=true
      ;;
    --help|-h)
      echo "الاستخدام: $0 [--no-build]"
      echo ""
      echo "  (بدون وسيطات) : يولّد المشروع ثم يبني APK محلياً"
      echo "  --no-build     : يولّد الكود فقط (موصى به في البيئات ذات RAM محدودة)"
      exit 0
      ;;
    *)
      echo "وسيط غير معروف: $arg  (استخدم --help للمساعدة)"
      exit 1
      ;;
  esac
done

APP_NAME="yj_converter"
APP_DISPLAY="Youssef Jaber Converter"
ORG="com.youssefjaber"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/$APP_NAME"

# ── Colours ─────────────────────────────────────────────────────────────────
AQUA='\033[38;2;0;229;255m'
NEON='\033[38;2;204;0;255m'
GRN='\033[38;2;0;230;118m'
RED='\033[38;2;255;23;68m'
YLW='\033[38;2;255;215;64m'
RST='\033[0m'

log()  { echo -e "${AQUA}[YJ]${RST} $1"; }
ok()   { echo -e "${GRN}[✓]${RST} $1"; }
warn() { echo -e "${YLW}[!]${RST} $1"; }
err()  { echo -e "${RED}[✗]${RST} $1"; exit 1; }
sec()  { echo -e "\n${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"; \
         echo -e "${NEON}  $1${RST}"; \
         echo -e "${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}\n"; }

if $NO_BUILD; then
  warn "وضع --no-build مفعّل: سيتم توليد الكود فقط دون بناء APK"
fi

# ════════════════════════════════════════════════════════════════════════════
# FIX #1: ضبط PATH بشكل دائم لتجنب "Flutter not found" في أي جلسة
# ════════════════════════════════════════════════════════════════════════════
sec "🛠️  FIX #1 — ضبط PATH الدائم (Flutter + Android SDK + Java 17)"

# اكتشاف مسار Flutter تلقائيًا
FLUTTER_BIN=""
for candidate in \
    "$HOME/flutter/bin" \
    "$HOME/development/flutter/bin" \
    "/opt/flutter/bin" \
    "/usr/local/flutter/bin" \
    "$(which flutter 2>/dev/null | xargs dirname 2>/dev/null || true)"; do
  if [ -x "$candidate/flutter" ]; then
    FLUTTER_BIN="$candidate"
    break
  fi
done

[ -z "$FLUTTER_BIN" ] && err "Flutter غير مثبت. قم بتثبيته من flutter.dev ثم أعد تشغيل هذا السكريبت."

FLUTTER_ROOT="$(dirname "$FLUTTER_BIN")"

# ── FIX: جلب ANDROID_SDK من $ANDROID_HOME أولاً (متغير البيئة الرسمي) ──────
# يتبع الأولوية: ANDROID_HOME ← ANDROID_SDK_ROOT ← المسار الافتراضي
ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"

JAVA_HOME_PATH=""

# اكتشاف Java 17
for jcandidate in \
    "/usr/lib/jvm/java-17-openjdk-amd64" \
    "/usr/lib/jvm/java-17-openjdk" \
    "/usr/lib/jvm/temurin-17" \
    "$HOME/.sdkman/candidates/java/17.*/java" \
    "$(update-java-alternatives -l 2>/dev/null | grep '17' | awk '{print $3}' | head -1 || true)"; do
  if [ -d "$jcandidate" ] && [ -x "$jcandidate/bin/java" ]; then
    JAVA_HOME_PATH="$jcandidate"
    break
  fi
done

# تثبيت Java 17 إذا لم يكن موجودًا
if [ -z "$JAVA_HOME_PATH" ]; then
  warn "Java 17 غير موجود — سيتم التثبيت..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y openjdk-17-jdk 2>/dev/null || apt-get install -y openjdk-17-jdk || warn "تعذّر تثبيت Java 17 تلقائيًا"
    JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
  fi
fi

# كتابة الـ PATH في ملف البيئة الدائم
ENV_FILE="$HOME/.yj_env"
cat > "$ENV_FILE" << ENVEOF
# YJ Converter — بيئة عمل ثابتة
export FLUTTER_ROOT="$FLUTTER_ROOT"
export FLUTTER_BIN="$FLUTTER_BIN"
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
${JAVA_HOME_PATH:+export JAVA_HOME="$JAVA_HOME_PATH"}
export PATH="\$FLUTTER_BIN:\$ANDROID_SDK/platform-tools:\$ANDROID_SDK/tools/bin:${JAVA_HOME_PATH:+$JAVA_HOME_PATH/bin:}\$PATH"
ENVEOF

# تحميل البيئة للجلسة الحالية
# shellcheck source=/dev/null
source "$ENV_FILE"

# إضافة source لـ .bashrc و .zshrc لتجنب "ينسى المسار" عند فتح جلسة جديدة
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  if [ -f "$rcfile" ] && ! grep -q "yj_env" "$rcfile" 2>/dev/null; then
    echo "" >> "$rcfile"
    echo "# YJ Converter env — added automatically" >> "$rcfile"
    echo "[ -f \"$ENV_FILE\" ] && source \"$ENV_FILE\"" >> "$rcfile"
    ok "تمت إضافة source إلى $rcfile"
  fi
done

ok "PATH مضبوط: Flutter=$FLUTTER_BIN | Android=$ANDROID_SDK | Java=${JAVA_HOME_PATH:-system}"
flutter --version | head -1

# ════════════════════════════════════════════════════════════════════════════
# FIX #2: ضبط حد RAM لـ Gradle — عالمياً (في ~/.gradle) لمنع OOM
# ════════════════════════════════════════════════════════════════════════════
sec "🧠 FIX #2 — حد RAM لـ Gradle العالمي (منع Killed)"

GRADLE_GLOBAL_DIR="$HOME/.gradle"
mkdir -p "$GRADLE_GLOBAL_DIR"
GRADLE_PROPS_GLOBAL="$GRADLE_GLOBAL_DIR/gradle.properties"

cat > "$GRADLE_PROPS_GLOBAL" << 'GPROPS'
# YJ Converter — Gradle memory limits to prevent OOM/Killed
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.parallel=false
org.gradle.caching=true
org.gradle.configureondemand=false
android.useAndroidX=true
android.enableJetifier=true
GPROPS

ok "~/.gradle/gradle.properties كُتب: -Xmx2g (آمن لـ Codespaces وIDX)"

# ── Pre-flight checks ────────────────────────────────────────────────────────
sec "🔍 فحص المتطلبات"
command -v flutter >/dev/null 2>&1 || err "Flutter غير موجود في PATH"
command -v dart    >/dev/null 2>&1 || err "Dart غير موجود"
ok "Flutter & Dart متاحان"
flutter --version | head -1

# ── إنشاء مشروع Flutter ─────────────────────────────────────────────────────
sec "🚀 إنشاء مشروع Flutter"
if [ -d "$PROJECT_DIR" ]; then
  warn "المجلد '$APP_NAME' موجود — سيتم الحذف والإعادة"
  rm -rf "$PROJECT_DIR"
fi
flutter create \
  --org "$ORG" \
  --project-name "$APP_NAME" \
  --platforms android \
  --description "Youssef Jaber MP4 to 3GP Video Converter" \
  "$PROJECT_DIR"
ok "تم إنشاء المشروع في $PROJECT_DIR"
cd "$PROJECT_DIR"

# ════════════════════════════════════════════════════════════════════════════
# FIX #3: pubspec.yaml
#   • ffmpeg_kit_flutter_full (النسخة الكاملة — دعم كل الترميزات)
#     بدلاً من ffmpeg_kit_flutter_video أو _new_full
#   • إصدارات مستقرة متوافقة مع Dart >=3.0.0
# ════════════════════════════════════════════════════════════════════════════
sec "📦 FIX #3 — pubspec.yaml (ffmpeg_kit_flutter_full + إصدارات 2025)"
cat > pubspec.yaml << 'PUBSPEC'
name: yj_converter
description: Youssef Jaber MP4 to 3GP Video Converter
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ── BLoC ──────────────────────────────────────────────────────────
  flutter_bloc: ^9.0.0
  equatable: ^2.0.5

  # ── FFmpeg FULL — يدعم كل الترميزات شاملاً: AMR-NB, H.263, 3GP ──
  # هذه هي النسخة الكاملة (Full Package) التي تحتوي على opencore-amr
  # وتضمن دعم ترميز الصوت amr_nb المطلوب لهواتف itel
  ffmpeg_kit_flutter_full: ^6.0.3

  # ── اختيار الملفات والصلاحيات ─────────────────────────────────────
  file_picker: ^9.0.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.4
  path: ^1.9.0

  # ── واجهة المستخدم ─────────────────────────────────────────────────
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  gap: ^3.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
PUBSPEC
ok "pubspec.yaml جاهز (ffmpeg_kit_flutter_full — النسخة الكاملة)"

mkdir -p assets

# ════════════════════════════════════════════════════════════════════════════
# FIX #4: local.properties — يجلب sdk.dir من $ANDROID_HOME تلقائياً
# ════════════════════════════════════════════════════════════════════════════
sec "📍 FIX #4 — local.properties (sdk.dir من \$ANDROID_HOME)"

# استخدام قيمة ANDROID_SDK التي جُلبت سابقاً من $ANDROID_HOME
cat > android/local.properties << LOCALPROPS
# تم التوليد تلقائياً من متغير البيئة \$ANDROID_HOME
sdk.dir=${ANDROID_SDK}
flutter.sdk=${FLUTTER_ROOT}
LOCALPROPS
ok "local.properties كُتب (sdk.dir=$ANDROID_SDK)"

# ════════════════════════════════════════════════════════════════════════════
# FIX #5: android/gradle.properties — ضبط الذاكرة محلياً داخل المشروع
#   يضمن ضبط -Xmx2g حتى لو لم يُقرأ الملف العالمي في ~/.gradle
# ════════════════════════════════════════════════════════════════════════════
sec "🧠 FIX #5 — android/gradle.properties المحلي (2GB Java Heap)"

cat > android/gradle.properties << 'PROJGPROPS'
# YJ Converter — ضبط ذاكرة Gradle محلياً داخل المشروع
# يمنع انهيار البناء في البيئات ذات الموارد المحدودة (IDX / Codespaces / CI)
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.parallel=false
org.gradle.caching=true
org.gradle.configureondemand=false
android.useAndroidX=true
android.enableJetifier=true
PROJGPROPS
ok "android/gradle.properties كُتب: -Xmx2g (محلي داخل المشروع)"

# ════════════════════════════════════════════════════════════════════════════
# FIX #6: build.gradle — Java 17 + AGP متوافق
# ════════════════════════════════════════════════════════════════════════════
sec "🤖 FIX #6 — Android build.gradle (Java 17 + multiDex)"
cat > android/app/build.gradle << 'GRADLE'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.youssefjaber.yj_converter"
    compileSdk flutter.compileSdkVersion
    ndkVersion "27.0.12077973"

    // FIX: Java 17 — مطلوب لـ AGP 8.x و Gradle 8.x
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
        coreLibraryDesugaringEnabled true
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    defaultConfig {
        applicationId "com.youssefjaber.yj_converter"
        minSdk 24
        targetSdk flutter.targetSdkVersion
        versionCode flutter.versionCode
        versionName flutter.versionName
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }
    }

    // FIX: تجنب تعارض ملفات META-INF من ffmpeg
    packagingOptions {
        resources {
            excludes += [
                'META-INF/DEPENDENCIES',
                'META-INF/LICENSE',
                'META-INF/LICENSE.txt',
                'META-INF/NOTICE',
                'META-INF/NOTICE.txt',
            ]
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
GRADLE
ok "build.gradle معدّل (Java 17 + desugar + NDK 27)"

# ════════════════════════════════════════════════════════════════════════════
# FIX #7: gradle-wrapper.properties — Gradle 8.9
# ════════════════════════════════════════════════════════════════════════════
sec "⚙️  FIX #7 — Gradle Wrapper 8.9 (متوافق مع compileSdk 35)"
mkdir -p android/gradle/wrapper
cat > android/gradle/wrapper/gradle-wrapper.properties << 'GWPROPS'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.9-bin.zip
networkTimeout=10000
validateDistributionUrl=true
GWPROPS
ok "gradle-wrapper.properties: Gradle 8.9"

# ════════════════════════════════════════════════════════════════════════════
# FIX #8: settings.gradle — AGP 8.3.2 + Kotlin 1.9.25
# ════════════════════════════════════════════════════════════════════════════
sec "⚙️  FIX #8 — settings.gradle (AGP 8.3.2 + Kotlin 1.9.25)"
cat > android/settings.gradle << 'SETTINGS'
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("${flutterSdkPath}/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-gradle-plugin" version "1.0.0" apply false
    id "com.android.application" version "8.3.2" apply false
    id "org.jetbrains.kotlin.android" version "1.9.25" apply false
}

include ":app"
SETTINGS
ok "settings.gradle: AGP 8.3.2 + Kotlin 1.9.25"

# ════════════════════════════════════════════════════════════════════════════
# FIX #9: AndroidManifest.xml
#   • أذونات READ_EXTERNAL_STORAGE و WRITE_EXTERNAL_STORAGE كاملة
#   • android:requestLegacyExternalStorage="true" للأجهزة القديمة
#   • READ_MEDIA_VIDEO لـ Android 13+
#   • MANAGE_EXTERNAL_STORAGE لـ Android 11+
# ════════════════════════════════════════════════════════════════════════════
sec "🔐 FIX #9 — AndroidManifest.xml (أذونات Read/Write كاملة)"
cat > android/app/src/main/AndroidManifest.xml << 'MANIFEST'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- أذونات التخزين — Read/Write                                    -->
    <!-- ═══════════════════════════════════════════════════════════════ -->

    <!-- قراءة الملفات — Android 9 (API 28) وأقدم -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>

    <!-- كتابة الملفات — Android 9 (API 28) وأقدم (ضروري لحفظ 3GP) -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29"/>

    <!-- قراءة الفيديو — Android 13+ (API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>

    <!-- إدارة التخزين الكامل — Android 11+ (لحفظ الملفات خارج مجلد التطبيق) -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- أذونات FFmpeg والخدمات                                         -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application
        android:label="YJ Converter"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true"
        android:hardwareAccelerated="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="content"/>
        </intent>
    </queries>
</manifest>
MANIFEST
ok "AndroidManifest.xml جاهز (أذونات Read/Write كاملة)"

# ════════════════════════════════════════════════════════════════════════════
# ── ملفات Dart (Clean Architecture + BLoC) ───────────────────────────────
# ════════════════════════════════════════════════════════════════════════════
sec "🎯 كتابة ملفات Dart (Clean Architecture)"

mkdir -p lib/core/theme
mkdir -p lib/domain/entities
mkdir -p lib/domain/usecases
mkdir -p lib/domain/repositories
mkdir -p lib/data/models
mkdir -p lib/data/repositories_impl
mkdir -p lib/data/datasources
mkdir -p lib/presentation/bloc
mkdir -p lib/presentation/pages
mkdir -p lib/presentation/widgets

# ── core/theme/app_theme.dart ────────────────────────────────────────────
cat > lib/core/theme/app_theme.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const bg       = Color(0xFF08080F);
  static const surface  = Color(0xFF0F0F1C);
  static const surface2 = Color(0xFF161626);
  static const aqua     = Color(0xFF00E5FF);
  static const aquaDim  = Color(0xFF00B8CC);
  static const neon     = Color(0xFFCC00FF);
  static const success  = Color(0xFF00E676);
  static const error    = Color(0xFFFF1744);
  static const warn     = Color(0xFFFFD740);
  static const txt1     = Color(0xFFEEF2FF);
  static const txt2     = Color(0xFF6677AA);
  static const txt3     = Color(0xFF334466);
  static const border   = Color(0x12FFFFFF);
  static const card     = Color(0x0EFFFFFF);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.aqua,
      secondary: AppColors.neon,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.scheherazadeNew(
        color: AppColors.txt1,
        fontSize: 40,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.scheherazadeNew(
        color: AppColors.txt1,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.tajawal(color: AppColors.txt1, fontSize: 14),
      bodyMedium: GoogleFonts.tajawal(color: AppColors.txt2, fontSize: 12),
    ),
  );
}
DART

# ── domain/entities/video_item.dart ──────────────────────────────────────
cat > lib/domain/entities/video_item.dart << 'DART'
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
DART

# ── domain/repositories/converter_repository.dart ────────────────────────
cat > lib/domain/repositories/converter_repository.dart << 'DART'
import '../entities/video_item.dart';

abstract class ConverterRepository {
  Future<List<VideoItem>> pickVideos();
  Stream<VideoItem> convertVideo(VideoItem item, String outputDir);
  Future<String> getOutputDirectory();
}
DART

# ── domain/usecases/pick_videos_usecase.dart ─────────────────────────────
cat > lib/domain/usecases/pick_videos_usecase.dart << 'DART'
import '../entities/video_item.dart';
import '../repositories/converter_repository.dart';

class PickVideosUseCase {
  final ConverterRepository repository;
  PickVideosUseCase(this.repository);

  Future<List<VideoItem>> call() => repository.pickVideos();
}
DART

# ── domain/usecases/convert_video_usecase.dart ───────────────────────────
cat > lib/domain/usecases/convert_video_usecase.dart << 'DART'
import '../entities/video_item.dart';
import '../repositories/converter_repository.dart';

class ConvertVideoUseCase {
  final ConverterRepository repository;
  ConvertVideoUseCase(this.repository);

  Stream<VideoItem> call(VideoItem item, String outputDir) =>
      repository.convertVideo(item, outputDir);
}
DART

# ════════════════════════════════════════════════════════════════════════════
# FIX #10: ffmpeg_datasource.dart
#   • import من ffmpeg_kit_flutter_full (النسخة الكاملة)
#   • أمر FFmpeg المحدَّث: المعيار الذهبي لهواتف itel والشاشات الصغيرة:
#     -vcodec h263 -pix_fmt yuv420p -acodec amr_nb -ar 8000 -ac 1
#     -ab 12.2k -s 176x144 output.3gp
# ════════════════════════════════════════════════════════════════════════════
cat > lib/data/datasources/ffmpeg_datasource.dart << 'DART'
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
DART

# ── data/repositories_impl/converter_repository_impl.dart ────────────────
cat > lib/data/repositories_impl/converter_repository_impl.dart << 'DART'
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
DART

# ── presentation/bloc/converter_event.dart ───────────────────────────────
cat > lib/presentation/bloc/converter_event.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../domain/entities/video_item.dart';

abstract class ConverterEvent extends Equatable {
  const ConverterEvent();
  @override
  List<Object?> get props => [];
}

class PickVideosEvent extends ConverterEvent {}
class ConvertAllEvent extends ConverterEvent {}

class RetryItemEvent extends ConverterEvent {
  final String itemId;
  const RetryItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class RemoveItemEvent extends ConverterEvent {
  final String itemId;
  const RemoveItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class RenameItemEvent extends ConverterEvent {
  final String itemId;
  final String newName;
  const RenameItemEvent(this.itemId, this.newName);
  @override
  List<Object?> get props => [itemId, newName];
}

class ClearDoneEvent extends ConverterEvent {}

class _ItemProgressEvent extends ConverterEvent {
  final VideoItem item;
  const _ItemProgressEvent(this.item);
  @override
  List<Object?> get props => [item];
}
DART

# ── presentation/bloc/converter_state.dart ───────────────────────────────
cat > lib/presentation/bloc/converter_state.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../domain/entities/video_item.dart';

class ConverterState extends Equatable {
  final List<VideoItem> items;
  final String? toastMessage;

  const ConverterState({
    this.items = const [],
    this.toastMessage,
  });

  ConverterState copyWith({
    List<VideoItem>? items,
    String? toastMessage,
  }) =>
      ConverterState(
        items: items ?? this.items,
        toastMessage: toastMessage,
      );

  int get total       => items.length;
  int get doneCount   => items.where((i) => i.status == ConvertStatus.done).length;
  int get activeCount => items.where((i) => i.status == ConvertStatus.processing).length;
  int get errorCount  => items.where((i) => i.status == ConvertStatus.error).length;

  @override
  List<Object?> get props => [items, toastMessage];
}
DART

# ── presentation/bloc/converter_bloc.dart ────────────────────────────────
cat > lib/presentation/bloc/converter_bloc.dart << 'DART'
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/video_item.dart';
import '../../domain/usecases/pick_videos_usecase.dart';
import '../../domain/usecases/convert_video_usecase.dart';
import '../../domain/repositories/converter_repository.dart';
import 'converter_event.dart';
import 'converter_state.dart';

const int _maxParallel = 2; // توازي محدود لتوفير RAM

class ConverterBloc extends Bloc<ConverterEvent, ConverterState> {
  final PickVideosUseCase pickVideos;
  final ConvertVideoUseCase convertVideo;
  final ConverterRepository repository;

  String? _outputDir;
  final Map<String, StreamSubscription<VideoItem>> _subs = {};

  ConverterBloc({
    required this.pickVideos,
    required this.convertVideo,
    required this.repository,
  }) : super(const ConverterState()) {
    on<PickVideosEvent>(_onPick);
    on<ConvertAllEvent>(_onConvertAll);
    on<RetryItemEvent>(_onRetry);
    on<RemoveItemEvent>(_onRemove);
    on<RenameItemEvent>(_onRename);
    on<ClearDoneEvent>(_onClearDone);
    on<_ItemProgressEvent>(_onItemProgress);
  }

  Future<void> _ensureOutputDir() async {
    _outputDir ??= await repository.getOutputDirectory();
  }

  Future<void> _onPick(PickVideosEvent event, Emitter<ConverterState> emit) async {
    final picked = await pickVideos();
    if (picked.isEmpty) return;
    final updated = [...state.items, ...picked];
    emit(state.copyWith(
      items: updated,
      toastMessage: '✦ تمت إضافة ${picked.length} فيديو',
    ));
    add(ConvertAllEvent());
  }

  void _onConvertAll(ConvertAllEvent event, Emitter<ConverterState> emit) {
    _triggerQueue();
  }

  void _onRetry(RetryItemEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      if (i.id == event.itemId) {
        return i.copyWith(status: ConvertStatus.queued, progress: 0.0);
      }
      return i;
    }).toList();
    emit(state.copyWith(items: items));
    _triggerQueue();
  }

  void _onRemove(RemoveItemEvent event, Emitter<ConverterState> emit) {
    _subs[event.itemId]?.cancel();
    _subs.remove(event.itemId);
    final items = state.items.where((i) => i.id != event.itemId).toList();
    emit(state.copyWith(items: items));
  }

  void _onRename(RenameItemEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      if (i.id == event.itemId) return i.copyWith(outputName: event.newName);
      return i;
    }).toList();
    emit(state.copyWith(items: items));
  }

  void _onClearDone(ClearDoneEvent event, Emitter<ConverterState> emit) {
    final items = state.items.where((i) => i.status != ConvertStatus.done).toList();
    emit(state.copyWith(items: items));
  }

  void _onItemProgress(_ItemProgressEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      return i.id == event.item.id ? event.item : i;
    }).toList();
    emit(state.copyWith(items: items));
  }

  void _triggerQueue() {
    final active = state.items.where((i) => i.status == ConvertStatus.processing).length;
    final queued = state.items.where((i) => i.status == ConvertStatus.queued).toList();
    final slots  = _maxParallel - active;
    for (var i = 0; i < slots && i < queued.length; i++) {
      _startConvert(queued[i]);
    }
  }

  void _startConvert(VideoItem item) {
    _ensureOutputDir().then((_) {
      final stream = convertVideo(item, _outputDir!);
      _subs[item.id] = stream.listen(
        (updated) => add(_ItemProgressEvent(updated)),
        onDone: () {
          _subs.remove(item.id);
          _triggerQueue();
        },
      );
    });
  }

  @override
  Future<void> close() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    return super.close();
  }
}
DART

# ── presentation/pages/home_page.dart ────────────────────────────────────
cat > lib/presentation/pages/home_page.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';
import '../widgets/video_item_card.dart';
import '../widgets/stats_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            const StatsBar(),
            Expanded(
              child: BlocBuilder<ConverterBloc, ConverterState>(
                builder: (context, state) {
                  if (state.items.isEmpty) {
                    return _EmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      return VideoItemCard(item: state.items[index])
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AddButton(),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.aqua.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.aqua.withOpacity(0.3)),
            ),
            child: const Icon(Icons.video_settings_rounded,
                color: AppColors.aqua, size: 22),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YJ Converter',
                    style: Theme.of(context).textTheme.headlineMedium),
                Text('محوّل الفيديو إلى 3GP · معيار itel الذهبي',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          BlocBuilder<ConverterBloc, ConverterState>(
            builder: (context, state) {
              if (state.doneCount == 0) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => context.read<ConverterBloc>().add(ClearDoneEvent()),
                icon: const Icon(Icons.cleaning_services_rounded,
                    color: AppColors.txt2, size: 20),
                tooltip: 'حذف المكتملة',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.aqua.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.aqua.withOpacity(0.2)),
            ),
            child: const Icon(Icons.video_library_outlined,
                color: AppColors.aqua, size: 36),
          ),
          const Gap(16),
          Text('اضغط + لإضافة فيديوهات',
              style: Theme.of(context).textTheme.bodyLarge),
          const Gap(4),
          Text('سيتم تحويلها تلقائياً إلى 3GP',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      )
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _AddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.read<ConverterBloc>().add(PickVideosEvent()),
      backgroundColor: AppColors.aqua,
      foregroundColor: AppColors.bg,
      icon: const Icon(Icons.add_rounded),
      label: const Text('إضافة فيديو',
          style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
DART

# ── presentation/widgets/video_item_card.dart ────────────────────────────
cat > lib/presentation/widgets/video_item_card.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/video_item.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';

class VideoItemCard extends StatelessWidget {
  final VideoItem item;
  const VideoItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusIcon(status: item.status),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.outputName,
                        style: const TextStyle(
                          color: AppColors.txt1,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.size} · ${item.duration}',
                        style: const TextStyle(
                            color: AppColors.txt2, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _ActionButton(item: item),
              ],
            ),
            if (item.status == ConvertStatus.processing) ...[
              const Gap(10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: AppColors.surface2,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.aqua),
                  minHeight: 4,
                ),
              ),
              const Gap(4),
              Text(
                '${(item.progress * 100).toInt()}%',
                style: const TextStyle(
                    color: AppColors.aquaDim, fontSize: 10),
              ),
            ],
            if (item.status == ConvertStatus.error &&
                item.errorMessage != null) ...[
              const Gap(8),
              Text(
                item.errorMessage!,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _borderColor {
    switch (item.status) {
      case ConvertStatus.processing:
        return AppColors.aqua.withOpacity(0.3);
      case ConvertStatus.done:
        return AppColors.success.withOpacity(0.3);
      case ConvertStatus.error:
        return AppColors.error.withOpacity(0.3);
      case ConvertStatus.queued:
        return AppColors.border;
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final ConvertStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (status) {
      case ConvertStatus.queued:
        icon = Icons.schedule_rounded;
        color = AppColors.txt2;
        break;
      case ConvertStatus.processing:
        icon = Icons.sync_rounded;
        color = AppColors.aqua;
        break;
      case ConvertStatus.done:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        break;
      case ConvertStatus.error:
        icon = Icons.error_rounded;
        color = AppColors.error;
        break;
    }
    return Icon(icon, color: color, size: 22);
  }
}

class _ActionButton extends StatelessWidget {
  final VideoItem item;
  const _ActionButton({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.status == ConvertStatus.error) {
      return IconButton(
        onPressed: () =>
            context.read<ConverterBloc>().add(RetryItemEvent(item.id)),
        icon: const Icon(Icons.refresh_rounded,
            color: AppColors.warn, size: 20),
        tooltip: 'إعادة المحاولة',
      );
    }
    return IconButton(
      onPressed: () =>
          context.read<ConverterBloc>().add(RemoveItemEvent(item.id)),
      icon: const Icon(Icons.close_rounded,
          color: AppColors.txt3, size: 20),
      tooltip: 'حذف',
    );
  }
}
DART

# ── presentation/widgets/stats_bar.dart ──────────────────────────────────
cat > lib/presentation/widgets/stats_bar.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/converter_state.dart';
import '../bloc/converter_bloc.dart';

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        if (state.total == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'الكل',
                  value: '${state.total}',
                  color: AppColors.txt2),
              _Stat(label: 'قيد التحويل',
                  value: '${state.activeCount}',
                  color: AppColors.aqua),
              _Stat(label: 'مكتمل',
                  value: '${state.doneCount}',
                  color: AppColors.success),
              _Stat(label: 'خطأ',
                  value: '${state.errorCount}',
                  color: AppColors.error),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 18)),
        const Gap(2),
        Text(label,
            style: const TextStyle(color: AppColors.txt2, fontSize: 10)),
      ],
    );
  }
}
DART

# ── main.dart ──────────────────────────────────────────────────────────────
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/ffmpeg_datasource.dart';
import 'data/repositories_impl/converter_repository_impl.dart';
import 'domain/usecases/pick_videos_usecase.dart';
import 'domain/usecases/convert_video_usecase.dart';
import 'presentation/bloc/converter_bloc.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF08080F),
  ));

  await _requestPermissions();

  runApp(const YJConverterApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.videos,
  ].request();
}

class YJConverterApp extends StatelessWidget {
  const YJConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ffmpeg = FfmpegDatasource();
    final repo   = ConverterRepositoryImpl(ffmpeg);

    return BlocProvider(
      create: (_) => ConverterBloc(
        pickVideos:   PickVideosUseCase(repo),
        convertVideo: ConvertVideoUseCase(repo),
        repository:   repo,
      ),
      child: MaterialApp(
        title: 'YJ Converter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomePage(),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
  }
}
DART

ok "كافة ملفات Dart كُتبت (Clean Architecture + BLoC)"

# ════════════════════════════════════════════════════════════════════════════
# FIX #11: .gitignore + .gitattributes
# ════════════════════════════════════════════════════════════════════════════
sec "🔗 FIX #11 — إعداد Git"

git init -b main
git config user.email "youssefjaber@yj-converter.local"
git config user.name "Youssef Jaber"

cat > .gitignore << 'GITIGNORE'
# Flutter / Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.log

# Android
android/.gradle/
android/app/release/
android/captures/
android/local.properties
*.iml

# IDE
.idea/
.vscode/
*.swp
*.swo
.DS_Store
Thumbs.db

# YJ env
.yj_env
GITIGNORE

cat > .gitattributes << 'GITATTR'
* text=auto
*.sh text eol=lf
*.dart text eol=lf
*.gradle text eol=lf
*.properties text eol=lf
*.xml text eol=lf
GITATTR

git add .
git commit -m "feat: YJ Converter v3.0 PROD — ffmpeg_kit_full + itel Golden Profile"
ok "Git repository مُهيّأ (commit أولي جاهز)"

# ════════════════════════════════════════════════════════════════════════════
# تنزيل الحزم
# ════════════════════════════════════════════════════════════════════════════
sec "📥 تنزيل الحزم (flutter pub get)"
flutter pub get
ok "تم تنزيل كافة الحزم"

# ════════════════════════════════════════════════════════════════════════════
# البناء — يُتخطى إذا كان --no-build مفعلاً
# ════════════════════════════════════════════════════════════════════════════
if $NO_BUILD; then
  echo ""
  echo -e "${NEON}╔══════════════════════════════════════════════════════════════╗${RST}"
  echo -e "${NEON}║${RST}  ${YLW}⚡ وضع --no-build: تم توليد الكود فقط بنجاح!${RST}             ${NEON}║${RST}"
  echo -e "${NEON}║${RST}                                                              ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${GRN}لبناء APK لاحقاً عند توفر RAM كافية:${RST}                    ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${AQUA}cd $APP_NAME && flutter build apk --release${RST}              ${NEON}║${RST}"
  echo -e "${NEON}║${RST}                                                              ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${GRN}لرفع الكود على GitHub:${RST}                                   ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${AQUA}git remote add origin <رابط المستودع>${RST}                   ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${AQUA}git push -u origin main${RST}                                  ${NEON}║${RST}"
  echo -e "${NEON}╚══════════════════════════════════════════════════════════════╝${RST}"
  exit 0
fi

sec "🏗️  بناء APK (Release)"
flutter build apk --release

APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
  APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
  echo ""
  echo -e "${NEON}╔══════════════════════════════════════════════════════════════╗${RST}"
  echo -e "${NEON}║${RST}  ${GRN}✓ بناء APK اكتمل بنجاح!${RST}                                  ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  📦 الحجم : ${YLW}$APK_SIZE${RST}                                      ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  📍 المسار: ${AQUA}build/app/outputs/flutter-apk/app-release.apk${RST}  ${NEON}║${RST}"
  echo -e "${NEON}╠══════════════════════════════════════════════════════════════╣${RST}"
  echo -e "${NEON}║${RST}  ${GRN}لتثبيت التطبيق على جهازك المتصل:${RST}                        ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${AQUA}adb install -r $APK_PATH${RST}  ${NEON}║${RST}"
  echo -e "${NEON}║${RST}                                                              ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${YLW}لرفع الكود على GitHub:${RST}                                   ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${AQUA}git remote add origin <رابط المستودع>${RST}                   ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  ${AQUA}git push -u origin main${RST}                                  ${NEON}║${RST}"
  echo -e "${NEON}╚══════════════════════════════════════════════════════════════╝${RST}"
else
  warn "لم يُعثر على APK — راجع أخطاء البناء أعلاه."
fi
