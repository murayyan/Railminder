import 'enums.dart';

/// Immutable progress carried between engine evaluations. Persisted with the
/// active journey so a restart resumes exactly where it stopped.
class EngineProgress {
  final bool armed;
  final double? lastDistanceMeters;
  final DateTime? lastAlertAt;
  final int alertCount;
  final double? minDistanceMeters;
  final int mismatchStreak;

  const EngineProgress({
    this.armed = false,
    this.lastDistanceMeters,
    this.lastAlertAt,
    this.alertCount = 0,
    this.minDistanceMeters,
    this.mismatchStreak = 0,
  });

  EngineProgress copyWith({
    bool? armed,
    double? lastDistanceMeters,
    DateTime? lastAlertAt,
    int? alertCount,
    double? minDistanceMeters,
    int? mismatchStreak,
  }) {
    return EngineProgress(
      armed: armed ?? this.armed,
      lastDistanceMeters: lastDistanceMeters ?? this.lastDistanceMeters,
      lastAlertAt: lastAlertAt ?? this.lastAlertAt,
      alertCount: alertCount ?? this.alertCount,
      minDistanceMeters: minDistanceMeters ?? this.minDistanceMeters,
      mismatchStreak: mismatchStreak ?? this.mismatchStreak,
    );
  }

  Map<String, dynamic> toJson() => {
    'armed': armed,
    'lastDistanceMeters': lastDistanceMeters,
    'lastAlertAt': lastAlertAt?.toIso8601String(),
    'alertCount': alertCount,
    'minDistanceMeters': minDistanceMeters,
    'mismatchStreak': mismatchStreak,
  };

  factory EngineProgress.fromJson(Map<String, dynamic> json) {
    return EngineProgress(
      armed: json['armed'] as bool? ?? false,
      lastDistanceMeters: (json['lastDistanceMeters'] as num?)?.toDouble(),
      lastAlertAt: json['lastAlertAt'] != null
          ? DateTime.parse(json['lastAlertAt'] as String)
          : null,
      alertCount: (json['alertCount'] as num?)?.toInt() ?? 0,
      minDistanceMeters: (json['minDistanceMeters'] as num?)?.toDouble(),
      mismatchStreak: (json['mismatchStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class ActiveJourneyState {
  final String journeyId;
  final String destinationStationId;
  final String destinationStationName;
  final DateTime startedAt;
  final int alertThresholdMeters;
  final EngineProgress progress;
  final MonitoringHealth health;
  final double? currentDistanceMeters;

  const ActiveJourneyState({
    required this.journeyId,
    required this.destinationStationId,
    required this.destinationStationName,
    required this.startedAt,
    required this.alertThresholdMeters,
    this.progress = const EngineProgress(),
    this.health = MonitoringHealth.active,
    this.currentDistanceMeters,
  });

  ActiveJourneyState copyWith({
    EngineProgress? progress,
    MonitoringHealth? health,
    double? currentDistanceMeters,
  }) {
    return ActiveJourneyState(
      journeyId: journeyId,
      destinationStationId: destinationStationId,
      destinationStationName: destinationStationName,
      startedAt: startedAt,
      alertThresholdMeters: alertThresholdMeters,
      progress: progress ?? this.progress,
      health: health ?? this.health,
      currentDistanceMeters: currentDistanceMeters ?? this.currentDistanceMeters,
    );
  }

  Map<String, dynamic> toJson() => {
    'journeyId': journeyId,
    'destinationStationId': destinationStationId,
    'destinationStationName': destinationStationName,
    'startedAt': startedAt.toIso8601String(),
    'alertThresholdMeters': alertThresholdMeters,
    'progress': progress.toJson(),
    'health': health.name,
    'currentDistanceMeters': currentDistanceMeters,
  };

  factory ActiveJourneyState.fromJson(Map<String, dynamic> json) {
    return ActiveJourneyState(
      journeyId: json['journeyId'] as String,
      destinationStationId: json['destinationStationId'] as String,
      destinationStationName: json['destinationStationName'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      alertThresholdMeters: (json['alertThresholdMeters'] as num).toInt(),
      progress: EngineProgress.fromJson(
        Map<String, dynamic>.from(json['progress'] as Map? ?? const {}),
      ),
      health: MonitoringHealth.values.firstWhere(
        (value) => value.name == json['health'],
        orElse: () => MonitoringHealth.active,
      ),
      currentDistanceMeters: (json['currentDistanceMeters'] as num?)?.toDouble(),
    );
  }
}
