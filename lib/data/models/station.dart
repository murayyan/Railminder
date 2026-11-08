class Station {
  final String id;
  final String name;
  final List<String> lineIds;
  final double latitude;
  final double longitude;
  final int orderIndex;

  const Station({
    required this.id,
    required this.name,
    required this.lineIds,
    required this.latitude,
    required this.longitude,
    required this.orderIndex,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final lineIds = json['lineIds'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final orderIndex = json['orderIndex'];

    if (id is! String || !RegExp(r'^[A-Z]{2,5}$').hasMatch(id)) {
      throw FormatException('Invalid station id: $id');
    }
    if (name is! String || name.length < 3 || name.length > 80) {
      throw FormatException('Invalid station name for $id');
    }
    if (lineIds is! List || lineIds.isEmpty || lineIds.any((e) => e is! String)) {
      throw FormatException('Invalid lineIds for $id');
    }
    if (latitude is! num || latitude < -7.0 || latitude > -5.8) {
      throw FormatException('Latitude out of service area for $id');
    }
    if (longitude is! num || longitude < 106.1 || longitude > 107.4) {
      throw FormatException('Longitude out of service area for $id');
    }
    if (orderIndex is! int || orderIndex < 0) {
      throw FormatException('Invalid orderIndex for $id');
    }

    return Station(
      id: id,
      name: name,
      lineIds: lineIds.cast<String>(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      orderIndex: orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lineIds': lineIds,
    'latitude': latitude,
    'longitude': longitude,
    'orderIndex': orderIndex,
  };

  String get searchKey => name.toLowerCase();
}
