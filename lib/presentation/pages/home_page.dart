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
              color: AppColors.aqua.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.aqua.withValues(alpha: 0.3)),
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
              color: AppColors.aqua.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.aqua.withValues(alpha: 0.2)),
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
