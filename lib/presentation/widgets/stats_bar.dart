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
