import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/enums.dart';
import '../../providers/journey_providers.dart';
import '../../providers/providers.dart';
import 'monitoring_status_widget.dart';

class ActiveJourneyScreen extends ConsumerWidget {
  const ActiveJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeJourneyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perjalanan Selesai')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppColors.accent),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada perjalanan aktif.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      );
    }

    final distanceMeters = active.currentDistanceMeters;
    final distanceText = distanceMeters != null
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : 'Menghitung...';

    final hasMismatch = ref.watch(routeMismatchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perjalanan Aktif'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Monitoring status
              Center(
                child: MonitoringStatusWidget(
                  health: active.health,
                  onFixPermission: () {
                    ref.read(permissionServiceProvider).openAppSettings();
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Route mismatch warning banner (R8 / T052)
              if (hasMismatch) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.waiting.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                    border: Border.all(
                      color: AppColors.waiting.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.waiting),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Periksa arah perjalanan: posisi terpantau menjauhi stasiun tujuan.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.waiting,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Focal point: Destination Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STASIUN TUJUAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        active.destinationStationName,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Jarak saat ini',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                          Text(
                            distanceText,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Peringatan bergetar di ambang ${(active.alertThresholdMeters / 1000).toStringAsFixed(1)} km.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Primary Actions
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(activeJourneyProvider.notifier)
                      .confirmArrived();
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Saya Sudah Turun'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hentikan Perjalanan?'),
                      content: const Text(
                        'Pemantauan lokasi akan dihentikan dan notifikasi dibatalkan.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Hentikan'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(activeJourneyProvider.notifier)
                        .stopJourney(resolution: ResolutionType.manualStop);
                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Hentikan Perjalanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
