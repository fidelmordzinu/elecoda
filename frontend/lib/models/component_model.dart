import 'dart:convert';

class ComponentModel {
  final int? id;
  final String partNumber;
  final String manufacturer;
  final String? category;
  final Map<String, dynamic>? attributes;

  ComponentModel({
    this.id,
    required this.partNumber,
    required this.manufacturer,
    this.category,
    this.attributes,
  });

  factory ComponentModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedAttributes;
    final raw = json['attributes'];
    if (raw != null) {
      if (raw is Map) {
        parsedAttributes = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        try {
          parsedAttributes = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {
          parsedAttributes = {'raw': raw};
        }
      }
    }

    return ComponentModel(
      id: json['id'] as int?,
      partNumber: json['part_number'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      category: json['category'] as String?,
      attributes: parsedAttributes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'part_number': partNumber,
      'manufacturer': manufacturer,
      if (category != null) 'category': category,
      if (attributes != null) 'attributes': attributes,
    };
  }
}
