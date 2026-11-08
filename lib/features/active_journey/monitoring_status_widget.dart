import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/enums.dart';

class MonitoringStatusWidget extends StatelessWidget {
  final MonitoringHealth health;
  final VoidCallback? onFixPermission;

  const MonitoringStatusWidget({
    super.key,
    required this.health,
    this.onFixPermission,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = StatusPalette.of(Theme.of(context).brightness);

    final (color, label, icon) = switch (health) {
      MonitoringHealth.active => (
        palette.active,
        'Memantau',
        Icons.radio_button_checked,
      ),
      MonitoringHealth.waitingForSignal => (
        palette.waiting,
        'Menunggu sinyal GPS',
        Icons.satellite_alt_outlined,
      ),
      MonitoringHealth.permissionLost => (
        palette.error,
        'Izin lokasi bermasalah',
        Icons.error_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (health == MonitoringHealth.permissionLost &&
              onFixPermission != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onFixPermission,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(44, 44),
              ),
              child: const Text('Perbaiki'),
            ),
          ],
        ],
      ),
    );
  }
}
