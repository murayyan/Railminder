enum JourneyStatus {
  active,
  completed,
  cancelled;

  static JourneyStatus fromWire(String value) {
    return JourneyStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => JourneyStatus.active,
    );
  }
}

enum ResolutionType {
  confirmedArrived,
  manualStop,
  stillOnTrainTimeout;

  static ResolutionType? fromWire(String? value) {
    if (value == null) return null;
    for (final resolution in ResolutionType.values) {
      if (resolution.name == value) return resolution;
    }
    return null;
  }
}

enum UserAlertAction {
  arrived,
  stillOnTrain,
  dismissed,
  timedOut;

  static UserAlertAction? fromWire(String? value) {
    if (value == null) return null;
    for (final action in UserAlertAction.values) {
      if (action.name == value) return action;
    }
    return null;
  }
}

enum MonitoringHealth {
  active,
  waitingForSignal,
  permissionLost;

  String get label => switch (this) {
    MonitoringHealth.active => 'Memantau',
    MonitoringHealth.waitingForSignal => 'Menunggu sinyal GPS',
    MonitoringHealth.permissionLost => 'Izin lokasi bermasalah',
  };
}
