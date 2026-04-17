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
