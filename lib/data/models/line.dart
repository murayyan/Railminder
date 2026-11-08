class StationLine {
  final String id;
  final String name;
  final String colorHex;
  final List<String> stationIds;

  const StationLine({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.stationIds,
  });

  factory StationLine.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final colorHex = json['colorHex'];
    final stationIds = json['stationIds'];

    if (id is! String || !RegExp(r'^[A-Z][A-Z0-9_]{2,40}$').hasMatch(id)) {
      throw FormatException('Invalid line id: $id');
    }
    if (name is! String || name.length < 3) {
      throw FormatException('Invalid line name for $id');
    }
    if (colorHex is! String || !RegExp(r'^#[0-9A-F]{6}$').hasMatch(colorHex)) {
      throw FormatException('Invalid colour for $id');
    }
    if (stationIds is! List || stationIds.length < 2) {
      throw FormatException('Line $id needs at least two stations');
    }

    return StationLine(
      id: id,
      name: name,
      colorHex: colorHex,
      stationIds: stationIds.cast<String>().toSet().toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorHex': colorHex,
    'stationIds': stationIds,
  };
}
