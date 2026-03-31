class CircuitComponent {
  final String ref;
  final String type;
  final String value;
  final String? mpn;
  final bool inInventory;

  CircuitComponent({
    required this.ref,
    required this.type,
    required this.value,
    this.mpn,
    this.inInventory = false,
  });

  factory CircuitComponent.fromJson(Map<String, dynamic> json) {
    return CircuitComponent(
      ref: json['ref'] as String? ?? '',
      type: json['type'] as String? ?? '',
      value: json['value'] as String? ?? '',
      mpn: json['mpn'] as String?,
      inInventory: json['in_inventory'] as bool? ?? false,
    );
  }
}

class CircuitConnection {
  final String from;
  final String to;

  CircuitConnection({required this.from, required this.to});

  factory CircuitConnection.fromJson(Map<String, dynamic> json) {
    return CircuitConnection(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
    );
  }
}

class CircuitResponse {
  final List<CircuitComponent> components;
  final List<CircuitConnection> connections;

  CircuitResponse({required this.components, required this.connections});

  factory CircuitResponse.fromJson(Map<String, dynamic> json) {
    return CircuitResponse(
      components:
          (json['components'] as List<dynamic>?)
              ?.map((c) => CircuitComponent.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      connections:
          (json['connections'] as List<dynamic>?)
              ?.map(
                (c) => CircuitConnection.fromJson(c as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
