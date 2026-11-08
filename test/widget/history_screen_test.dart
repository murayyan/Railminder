import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:railminder/data/models/enums.dart';
import 'package:railminder/data/models/journey.dart';
import 'package:railminder/features/history/history_screen.dart';

import '../support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;

  setUp(() async {
    await initializeDateFormatting('id');
    harness = await TestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithScope(const HistoryScreen(), harness.container),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when there is no journey', (tester) async {
    await pumpHistory(tester);
    expect(find.text('Belum Ada Riwayat'), findsOneWidget);
  });

  testWidgets('lists stored journeys newest first', (tester) async {
    await harness.journeys.insertJourney(
      Journey(
        id: 'j1',
        destinationStationId: 'BOO',
        destinationStationName: 'Bogor',
        startedAt: DateTime(2026, 11, 7, 9, 0),
        status: JourneyStatus.completed,
        alertThresholdMeters: 1500,
        alertTriggeredCount: 2,
        finalResolution: ResolutionType.confirmedArrived,
      ),
    );
    await harness.journeys.insertJourney(
      Journey(
        id: 'j2',
        destinationStationId: 'TNG',
        destinationStationName: 'Tangerang',
        startedAt: DateTime(2026, 11, 8, 9, 0),
        status: JourneyStatus.cancelled,
        alertThresholdMeters: 1500,
        finalResolution: ResolutionType.manualStop,
      ),
    );

    await pumpHistory(tester);

    expect(find.text('Bogor'), findsOneWidget);
    expect(find.text('Tangerang'), findsOneWidget);
    expect(
      find.textContaining('Sudah turun'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Dihentikan manual'),
      findsOneWidget,
    );
  });

  testWidgets('deleting all history returns the empty state', (tester) async {
    await harness.journeys.insertJourney(
      Journey(
        id: 'j1',
        destinationStationId: 'BOO',
        destinationStationName: 'Bogor',
        startedAt: DateTime(2026, 11, 7, 9, 0),
        status: JourneyStatus.completed,
        alertThresholdMeters: 1500,
        finalResolution: ResolutionType.confirmedArrived,
      ),
    );

    await pumpHistory(tester);
    expect(find.text('Bogor'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus semua riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus Riwayat?'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Riwayat'), findsOneWidget);
  });
}
