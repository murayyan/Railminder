import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/models/alert_event.dart';
import '../../data/models/enums.dart';
import '../../data/models/journey.dart';
import '../../providers/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Perjalanan'),
        actions: [
          IconButton(
            tooltip: 'Hapus semua riwayat',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Riwayat?'),
                  content: const Text(
                    'Seluruh catatan perjalanan dan peringatan akan dihapus permanen dari perangkat.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(journeyRepositoryProvider).clearAllHistory();
                ref.invalidate(historyProvider);
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Gagal memuat riwayat: $err'),
          ),
        ),
        data: (journeys) {
          if (journeys.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 56,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Riwayat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Perjalanan yang selesai akan dicatat di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id');

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: journeys.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final journey = journeys[index];
              final dateStr = formatter.format(journey.startedAt);

              final resolutionLabel = switch (journey.finalResolution) {
                ResolutionType.confirmedArrived => 'Sudah turun',
                ResolutionType.manualStop => 'Dihentikan manual',
                ResolutionType.stillOnTrainTimeout => 'Selesai otomatis',
                null => journey.status == JourneyStatus.active
                    ? 'Aktif'
                    : 'Selesai',
              };

              return ListTile(
                title: Text(
                  journey.destinationStationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$dateStr • $resolutionLabel • ${journey.alertTriggeredCount} getar',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.secondaryText,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _JourneyDetailScreen(journey: journey),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _JourneyDetailScreen extends ConsumerWidget {
  final Journey journey;

  const _JourneyDetailScreen({required this.journey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyRepo = ref.watch(journeyRepositoryProvider);
    final formatter = DateFormat('dd MMMM yyyy, HH:mm:ss', 'id');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Perjalanan')),
      body: FutureBuilder<List<AlertEvent>>(
        future: journeyRepo.getAlertEvents(journey.id),
        builder: (context, snapshot) {
          final events = snapshot.data ?? const [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STASIUN TUJUAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journey.destinationStationName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _detailRow('Mulai', formatter.format(journey.startedAt)),
                      if (journey.completedAt != null)
                        _detailRow('Selesai', formatter.format(journey.completedAt!)),
                      _detailRow(
                        'Ambang peringatan',
                        '${(journey.alertThresholdMeters / 1000).toStringAsFixed(1)} km',
                      ),
                      _detailRow('Total peringatan', '${journey.alertTriggeredCount} kali'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'RIWAYAT PERINGATAN (${events.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Tidak ada peringatan yang terpicu selama perjalanan ini.',
                    style: TextStyle(fontSize: 14),
                  ),
                )
              else
                ...events.map(
                  (e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        e.isRepeat ? 'Peringatan ulang' : 'Peringatan awal',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${formatter.format(e.triggeredAt)}\n'
                        'Jarak: ${(e.distanceMeters / 1000).toStringAsFixed(2)} km '
                        '(akurasi ±${e.accuracyMeters.toStringAsFixed(0)} m)',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
