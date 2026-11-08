import 'enums.dart';

class AlertEvent {
  final String id;
  final String journeyId;
  final DateTime triggeredAt;
  final double distanceMeters;
  final double accuracyMeters;
  final bool isRepeat;
  final UserAlertAction? userAction;
  final DateTime? actionTimestamp;

  const AlertEvent({
    required this.id,
    required this.journeyId,
    required this.triggeredAt,
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.isRepeat,
    this.userAction,
    this.actionTimestamp,
  });

  AlertEvent copyWith({UserAlertAction? userAction, DateTime? actionTimestamp}) {
    return AlertEvent(
      id: id,
      journeyId: journeyId,
      triggeredAt: triggeredAt,
      distanceMeters: distanceMeters,
      accuracyMeters: accuracyMeters,
      isRepeat: isRepeat,
      userAction: userAction ?? this.userAction,
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'journey_id': journeyId,
    'triggered_at': triggeredAt.toIso8601String(),
    'distance_meters': distanceMeters,
    'accuracy_meters': accuracyMeters,
    'is_repeat': isRepeat ? 1 : 0,
    'user_action': userAction?.name,
    'action_timestamp': actionTimestamp?.toIso8601String(),
  };

  factory AlertEvent.fromMap(Map<String, dynamic> map) {
    return AlertEvent(
      id: map['id'] as String,
      journeyId: map['journey_id'] as String,
      triggeredAt: DateTime.parse(map['triggered_at'] as String),
      distanceMeters: (map['distance_meters'] as num).toDouble(),
      accuracyMeters: (map['accuracy_meters'] as num).toDouble(),
      isRepeat: (map['is_repeat'] as int) == 1,
      userAction: UserAlertAction.fromWire(map['user_action'] as String?),
      actionTimestamp: map['action_timestamp'] != null
          ? DateTime.parse(map['action_timestamp'] as String)
          : null,
    );
  }
}
