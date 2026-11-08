import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'Jarak peringatan'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SegmentedButton<int>(
              segments: AppConstants.thresholdOptionsMeters
                  .map(
                    (meters) => ButtonSegment<int>(
                      value: meters,
                      label: Text(
                        '${(meters / 1000).toStringAsFixed(0)} km',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              selected: {settings.alertDistanceMeters},
              onSelectionChanged: (selection) {
                notifier.setAlertDistance(selection.first);
              },
              showSelectedIcon: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Notifikasi dan getaran dikirim saat jarak ke stasiun tujuan melewati ambang ini.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const _SectionHeader(title: 'Getaran'),
          SwitchListTile(
            title: const Text('Aktifkan getaran', style: TextStyle(fontSize: 16)),
            subtitle: const Text(
              'Notifikasi tetap muncul tanpa suara. Getaran membantu saat HP di tas.',
              style: TextStyle(fontSize: 13),
            ),
            value: settings.enableVibration,
            activeThumbColor: AppColors.accent,
            onChanged: notifier.setVibration,
          ),
          const Divider(),
          const _SectionHeader(title: 'Pengulangan'),
          ListTile(
            title: const Text('Interval pengulangan'),
            subtitle: const Text('Jeda antar peringatan bila Anda masih di kereta.'),
            trailing: DropdownButton<int>(
              value: settings.repeatIntervalMinutes,
              underline: const SizedBox.shrink(),
              items: const [1, 2, 3, 5, 10]
                  .map(
                    (min) => DropdownMenuItem<int>(
                      value: min,
                      child: Text('$min menit'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) notifier.setRepeatInterval(val);
              },
            ),
          ),
          ListTile(
            title: const Text('Jumlah pengulangan maksimum'),
            subtitle: const Text('Setelah batas ini, peringatan berhenti.'),
            trailing: DropdownButton<int>(
              value: settings.maxRepeats,
              underline: const SizedBox.shrink(),
              items: const [0, 1, 2, 3, 5]
                  .map(
                    (count) => DropdownMenuItem<int>(
                      value: count,
                      child: Text('$count kali'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) notifier.setMaxRepeats(val);
              },
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'Tentang'),
          const ListTile(
            title: Text('Pemrosesan di perangkat'),
            subtitle: Text(
              'Lokasi dan riwayat perjalanan tidak dikirim ke server mana pun.',
              style: TextStyle(fontSize: 13),
            ),
            leading: Icon(Icons.lock_outline),
          ),
          const ListTile(
            title: Text('Versi'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
        ),
      ),
    );
  }
}
