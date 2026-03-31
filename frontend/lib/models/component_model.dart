class ComponentModel {
  final int? id;
  final String mpn;
  final String? description;
  final String? datasheetUrl;
  final String? specs;
  final String? category;

  ComponentModel({
    this.id,
    required this.mpn,
    this.description,
    this.datasheetUrl,
    this.specs,
    this.category,
  });

  factory ComponentModel.fromJson(Map<String, dynamic> json) {
    return ComponentModel(
      id: json['id'] as int?,
      mpn: json['mpn'] as String? ?? '',
      description: json['description'] as String?,
      datasheetUrl: json['datasheet_url'] as String?,
      specs: json['specs']?.toString(),
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mpn': mpn,
      if (description != null) 'description': description,
      if (datasheetUrl != null) 'datasheet_url': datasheetUrl,
      if (specs != null) 'specs': specs,
      if (category != null) 'category': category,
    };
  }
}
