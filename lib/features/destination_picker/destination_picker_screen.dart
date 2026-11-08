import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/line.dart';
import '../../data/models/station.dart';
import '../../providers/providers.dart';

class DestinationPickerScreen extends ConsumerStatefulWidget {
  final Station? excludeStation;

  const DestinationPickerScreen({super.key, this.excludeStation});

  @override
  ConsumerState<DestinationPickerScreen> createState() =>
      _DestinationPickerScreenState();
}

class _DestinationPickerScreenState
    extends ConsumerState<DestinationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationRepo = ref.watch(stationRepositoryProvider);
    final results = stationRepo.searchStations(_query);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Stasiun Tujuan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Cari stasiun (mis. Bogor, Sudirman)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Tidak ada stasiun yang cocok dengan "$_query"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final station = results[index];
                      final isExcluded =
                          widget.excludeStation?.id == station.id;
                      final lines = station.lineIds
                          .map((id) => stationRepo.getLineById(id))
                          .whereType<StationLine>()
                          .toList();

                      return ListTile(
                        enabled: !isExcluded,
                        title: Text(
                          station.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isExcluded
                                ? (isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.secondaryText)
                                : null,
                          ),
                        ),
                        subtitle: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: lines
                              .map(
                                (line) => _LineTag(
                                  name: line.name,
                                  colorHex: line.colorHex,
                                ),
                              )
                              .toList(),
                        ),
                        trailing: isExcluded
                            ? const Text(
                                'Posisi saat ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              )
                            : const Icon(Icons.chevron_right, size: 20),
                        onTap: isExcluded
                            ? null
                            : () => Navigator.of(context).pop(station),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LineTag extends StatelessWidget {
  final String name;
  final String colorHex;

  const _LineTag({required this.name, required this.colorHex});

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = AppColors.navy;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
