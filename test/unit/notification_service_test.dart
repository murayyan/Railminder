import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/core/constants.dart';
import 'package:railminder/services/notification_service.dart';

void main() {
  test('payload encodes and decodes losslessly', () {
    final t0 = DateTime(2026, 11, 8, 10, 30, 0);
    final payload = NotificationPayload(
      type: 'station_approach',
      journeyId: 'j-123',
      destinationStationId: 'BOO',
      triggeredAt: t0,
      isRepeat: true,
    );

    final raw = payload.encode();
    final decoded = NotificationPayload.decode(raw);

    expect(decoded, isNotNull);
    expect(decoded!.type, 'station_approach');
    expect(decoded.journeyId, 'j-123');
    expect(decoded.destinationStationId, 'BOO');
    expect(decoded.triggeredAt, t0);
    expect(decoded.isRepeat, isTrue);
  });

  test('payload decode handles null and malformed input gracefully', () {
    expect(NotificationPayload.decode(null), isNull);
    expect(NotificationPayload.decode(''), isNull);
    expect(NotificationPayload.decode('not json'), isNull);
    expect(NotificationPayload.decode('{"incomplete": true}'), isNull);
  });

  test('notificationIdFor produces stable non-negative 31-bit integers', () {
    final id1 = NotificationPayload.notificationIdFor('BOO');
    final id2 = NotificationPayload.notificationIdFor('BOO');
    final id3 = NotificationPayload.notificationIdFor('JAKK');

    expect(id1, id2);
    expect(id1 >= 0, isTrue);
    expect(id1 <= 0x7fffffff, isTrue);
    expect(id3 >= 0, isTrue);
    expect(id1, isNot(id3));
  });

  test('action IDs match contract', () {
    expect(AppConstants.actionArrived, 'saya_sudah_turun');
    expect(AppConstants.actionStillOnTrain, 'saya_masih_di_kereta');
    expect(AppConstants.actionStopJourney, 'hentikan_perjalanan');
  });
}
