import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() => runApp(MaterialApp(home: YJConverter(), theme: ThemeData.dark()));

class YJConverter extends StatefulWidget {
  @override
  _YJConverterState createState() => _YJConverterState();
}

class _YJConverterState extends State<YJConverter> {
  String status = "جاهز للتحويل";
  double progress = 0.0;

  Future<void> convertVideo() async {
    FilePickerResult? result = await FilePicker().pickFiles(type: FileType.video);
    if (result == null) return;

    File inputFile = File(result.files.single.path!);
    final directory = await getExternalStorageDirectory();
    String outputPath = "${directory!.path}/converted_${DateTime.now().millisecondsSinceEpoch}.3gp";

    setState(() => status = "جاري التحويل بأقصى سرعة...");

    // الأمر السحري للسرعة القصوى
    String command = "-i ${inputFile.path} -vcodec h263 -acodec amr_nb -ar 8000 -ac 1 -ab 12.2k -s qcif -r 12 -preset ultrafast $outputPath";

    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() => status = "تم التحويل بنجاح: $outputPath");
      } else {
        setState(() => status = "حدث خطأ أثناء التحويل");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("YJ Converter - MP4 to 3GP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(onPressed: convertVideo, child: Text("اختر فيديو ضخم للتحويل")),
          ],
        ),
      ),
    );
  }
}
