import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'trail_path.g.dart';

@HiveType(typeId: 0)
class TrailPath extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<PathPoint> points;

  @HiveField(4)
  final double distance;

  @HiveField(5)
  final double elevationGain;

  TrailPath({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.points,
    required this.distance,
    required this.elevationGain,
  });

  factory TrailPath.fromJson(Map<String, dynamic> json) => TrailPath(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        points: (json['points'] as List)
            .map((p) => PathPoint.fromJson(p))
            .toList(),
        distance: json['distance'] as double,
        elevationGain: json['elevationGain'] as double,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'points': points.map((p) => p.toJson()).toList(),
        'distance': distance,
        'elevationGain': elevationGain,
      };
}

@HiveType(typeId: 1)
class PathPoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double altitude;

  @HiveField(3)
  final String? placeName;

  PathPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.placeName,
  });

  factory PathPoint.fromJson(Map<String, dynamic> json) => PathPoint(
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        altitude: json['altitude'] as double,
        placeName: json['placeName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'placeName': placeName,
      };
}
