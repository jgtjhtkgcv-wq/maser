import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/converter_bloc_mp4_to_3gp.dart';
import '../bloc/converter_event_mp4_to_3gp.dart';
import '../bloc/converter_state_mp4_to_3gp.dart';

class Mp4To3gpConverterPage extends StatelessWidget {
  final String inputPath;
  final String outputPath;

  const Mp4To3gpConverterPage({
    super.key,
    required this.inputPath,
    required this.outputPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MP4 to 3GP Converter')),
      body: BlocBuilder<ConverterBloc, ConverterState>(
        builder: (context, state) {
          if (state is ConverterInitial) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<ConverterBloc>().add(
                        ConvertVideoEvent(inputPath, outputPath),
                      );
                },
                child: const Text('Start Conversion'),
              ),
            );
          } else if (state is ConverterLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConverterProcessing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Converting... ${state.percentage}%'),
                  LinearProgressIndicator(value: state.percentage / 100),
                ],
              ),
            );
          } else if (state is ConverterSuccess) {
            return Center(
              child: Text('Conversion successful: ${state.path}'),
            );
          } else if (state is ConverterFailure) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}