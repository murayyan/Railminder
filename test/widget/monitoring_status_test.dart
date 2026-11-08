import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/core/theme.dart';
import 'package:railminder/data/models/enums.dart';
import 'package:railminder/features/active_journey/monitoring_status_widget.dart';

void main() {
  Future<void> pumpStatus(
    WidgetTester tester,
    MonitoringHealth health, {
    VoidCallback? onFix,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: MonitoringStatusWidget(
              health: health,
              onFixPermission: onFix,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('active state shows Memantau', (tester) async {
    await pumpStatus(tester, MonitoringHealth.active);
    expect(find.text('Memantau'), findsOneWidget);
  });

  testWidgets('waiting state shows amber label', (tester) async {
    await pumpStatus(tester, MonitoringHealth.waitingForSignal);
    expect(find.text('Menunggu sinyal GPS'), findsOneWidget);
  });

  testWidgets('permission lost shows label and fix action', (tester) async {
    var tapped = false;
    await pumpStatus(
      tester,
      MonitoringHealth.permissionLost,
      onFix: () => tapped = true,
    );

    expect(find.text('Izin lokasi bermasalah'), findsOneWidget);
    expect(find.text('Perbaiki'), findsOneWidget);

    await tester.tap(find.text('Perbaiki'));
    expect(tapped, isTrue);
  });

  testWidgets('fix action meets the 44px tap target', (tester) async {
    await pumpStatus(
      tester,
      MonitoringHealth.permissionLost,
      onFix: () {},
    );

    final size = tester.getSize(find.byType(TextButton));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
  });
}
