import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/station.dart';
import '../../providers/journey_providers.dart';
import '../../providers/providers.dart';
import '../active_journey/active_journey_screen.dart';
import '../destination_picker/destination_picker_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _handleStartJourney(BuildContext context, WidgetRef ref) async {
    final permService = ref.read(permissionServiceProvider);
    final audit = await permService.auditPrerequisites();

    if (!context.mounted) return;

    if (!audit.locationServiceEnabled) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Layanan Lokasi Mati'),
          content: const Text(
            'Aktifkan GPS / Layanan Lokasi agar Railminder dapat menghitung jarak ke stasiun.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                permService.openLocationSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      return;
    }

    if (!audit.canStartTracking) {
      await permService.requestLocationPermission();
      if (!context.mounted) return;

      final reAudit = await permService.auditPrerequisites();
      if (!reAudit.canStartTracking) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Izin Lokasi Diperlukan'),
            content: const Text(
              'Railminder membutuhkan izin lokasi agar dapat memantau jarak stasiun saat di kereta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  permService.openAppSettings();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (!audit.notificationGranted) {
      await ref.read(notificationServiceProvider).requestPermissions();
    }
    if (!context.mounted) return;

    final Station? chosen = await Navigator.of(context).push<Station>(
      MaterialPageRoute(
        builder: (_) => const DestinationPickerScreen(),
      ),
    );

    if (chosen == null || !context.mounted) return;

    await ref.read(activeJourneyProvider.notifier).startJourney(
          destination: chosen,
        );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ActiveJourneyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeJourneyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alreadyArrived = ref.watch(alreadyArrivedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Railminder',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner when started within alert radius (R4 / T044)
              if (alreadyArrived && active != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.waiting.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                    border: Border.all(
                      color: AppColors.waiting.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.waiting),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Anda sudah di dekat ${active.destinationStationName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.waiting,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Posisi awal berada di dalam radius peringatan. Apakah Anda sudah tiba?',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            onPressed: () async {
                              await ref
                                  .read(activeJourneyProvider.notifier)
                                  .confirmArrived();
                            },
                            child: const Text('Sudah Turun'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            onPressed: () {
                              ref
                                  .read(activeJourneyProvider.notifier)
                                  .armMonitoring();
                              ref
                                  .read(alreadyArrivedProvider.notifier)
                                  .set(false);
                            },
                            child: const Text('Masih di Kereta'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Active Journey Card if journey is currently in progress
              if (active != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PERJALANAN AKTIF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.secondaryText,
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          active.destinationStationName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          active.currentDistanceMeters != null
                              ? 'Sekitar ${(active.currentDistanceMeters! / 1000).toStringAsFixed(1)} km lagi'
                              : 'Menghitung jarak...',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ActiveJourneyScreen(),
                              ),
                            );
                          },
                          child: const Text('Buka Layar Perjalanan'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Clean hero section
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.train_rounded,
                          size: 38,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Siap naik KRL?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Pilih stasiun tujuan Anda. Railminder akan bergetar sebelum kereta tiba.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main CTA
              if (active == null)
                FilledButton(
                  onPressed: () => _handleStartJourney(context, ref),
                  child: const Text('Mulai Perjalanan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
