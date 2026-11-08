import 'enums.dart';

class Journey {
  final String id;
  final String destinationStationId;
  final String destinationStationName;
  final String? originStationId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final JourneyStatus status;
  final int alertThresholdMeters;
  final int alertTriggeredCount;
  final DateTime? firstAlertTriggeredAt;
  final ResolutionType? finalResolution;

  const Journey({
    required this.id,
    required this.destinationStationId,
    required this.destinationStationName,
    required this.startedAt,
    required this.alertThresholdMeters,
    this.originStationId,
    this.completedAt,
    this.status = JourneyStatus.active,
    this.alertTriggeredCount = 0,
    this.firstAlertTriggeredAt,
    this.finalResolution,
  });

  Journey copyWith({
    DateTime? completedAt,
    JourneyStatus? status,
    int? alertTriggeredCount,
    DateTime? firstAlertTriggeredAt,
    ResolutionType? finalResolution,
  }) {
    return Journey(
      id: id,
      destinationStationId: destinationStationId,
      destinationStationName: destinationStationName,
      originStationId: originStationId,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      alertThresholdMeters: alertThresholdMeters,
      alertTriggeredCount: alertTriggeredCount ?? this.alertTriggeredCount,
      firstAlertTriggeredAt: firstAlertTriggeredAt ?? this.firstAlertTriggeredAt,
      finalResolution: finalResolution ?? this.finalResolution,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'destination_station_id': destinationStationId,
    'destination_station_name': destinationStationName,
    'origin_station_id': originStationId,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'status': status.name,
    'alert_threshold_meters': alertThresholdMeters,
    'alert_triggered_count': alertTriggeredCount,
    'first_alert_triggered_at': firstAlertTriggeredAt?.toIso8601String(),
    'final_resolution': finalResolution?.name,
  };

  factory Journey.fromMap(Map<String, dynamic> map) {
    return Journey(
      id: map['id'] as String,
      destinationStationId: map['destination_station_id'] as String,
      destinationStationName: map['destination_station_name'] as String,
      originStationId: map['origin_station_id'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      status: JourneyStatus.fromWire(map['status'] as String),
      alertThresholdMeters: map['alert_threshold_meters'] as int,
      alertTriggeredCount: (map['alert_triggered_count'] as int?) ?? 0,
      firstAlertTriggeredAt: map['first_alert_triggered_at'] != null
          ? DateTime.parse(map['first_alert_triggered_at'] as String)
          : null,
      finalResolution: ResolutionType.fromWire(map['final_resolution'] as String?),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Journey.fromJson(Map<String, dynamic> json) => Journey.fromMap(json);
}
