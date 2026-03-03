enum AlertType { typeA, typeB, typeC }

class PolyfoxAlert {
  final String id;
  final String name;
  final String description;
  final AlertType type;
  final List<String> categories;
  final double threshold;
  final bool isEnabled;

  PolyfoxAlert({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.categories,
    required this.threshold,
    this.isEnabled = true,
  });

  factory PolyfoxAlert.fromJson(Map<String, dynamic> json) => PolyfoxAlert(
    id: json['id'],
    name: json['name'],
    description: json['description'] ?? 'Alerta personalizada',
    type: _mapType(json['type_filter']?[0]),
    categories: List<String>.from(json['category_filter'] ?? []),
    threshold: (json['min_delta'] as num?)?.toDouble() ?? 7.0,
    isEnabled: json['is_active'] ?? true,
  );

  static AlertType _mapType(String? type) {
    if (type == 'type_b') return AlertType.typeB;
    if (type == 'type_c') return AlertType.typeC;
    return AlertType.typeA;
  }
}
