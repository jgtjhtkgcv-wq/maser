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
        return AppColors.aqua.withValues(alpha: 0.3);
      case ConvertStatus.done:
        return AppColors.success.withValues(alpha: 0.3);
      case ConvertStatus.error:
        return AppColors.error.withValues(alpha: 0.3);
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
