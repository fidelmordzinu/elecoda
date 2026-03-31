import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/component_model.dart';
import 'package:frontend/models/circuit_model.dart';

void main() {
  group('ComponentModel', () {
    test('fromJson parses valid JSON', () {
      final json = {
        'id': 1,
        'mpn': 'RC0402FR-0710KL',
        'description': 'Resistor 10k',
        'category': 'resistor',
      };
      final component = ComponentModel.fromJson(json);
      expect(component.id, 1);
      expect(component.mpn, 'RC0402FR-0710KL');
      expect(component.description, 'Resistor 10k');
      expect(component.category, 'resistor');
    });

    test('toJson serializes correctly', () {
      final component = ComponentModel(
        id: 1,
        mpn: 'RC0402FR-0710KL',
        description: 'Resistor 10k',
        category: 'resistor',
      );
      final json = component.toJson();
      expect(json['id'], 1);
      expect(json['mpn'], 'RC0402FR-0710KL');
    });

    test('handles null fields', () {
      final json = {'mpn': 'TEST'};
      final component = ComponentModel.fromJson(json);
      expect(component.mpn, 'TEST');
      expect(component.description, isNull);
      expect(component.category, isNull);
    });
  });

  group('CircuitComponent', () {
    test('fromJson parses valid JSON', () {
      final json = {
        'ref': 'R1',
        'type': 'resistor',
        'value': '10k',
        'mpn': 'RC0402FR-0710KL',
        'in_inventory': true,
      };
      final comp = CircuitComponent.fromJson(json);
      expect(comp.ref, 'R1');
      expect(comp.type, 'resistor');
      expect(comp.value, '10k');
      expect(comp.inInventory, true);
    });
  });

  group('CircuitConnection', () {
    test('fromJson parses valid JSON', () {
      final json = {'from': 'R1.pin1', 'to': 'C1.pin1'};
      final conn = CircuitConnection.fromJson(json);
      expect(conn.from, 'R1.pin1');
      expect(conn.to, 'C1.pin1');
    });
  });

  group('CircuitResponse', () {
    test('fromJson parses full response', () {
      final json = {
        'components': [
          {'ref': 'R1', 'type': 'resistor', 'value': '10k'},
        ],
        'connections': [
          {'from': 'R1.pin1', 'to': 'C1.pin1'},
        ],
      };
      final response = CircuitResponse.fromJson(json);
      expect(response.components.length, 1);
      expect(response.connections.length, 1);
    });

    test('handles empty lists', () {
      final json = <String, dynamic>{};
      final response = CircuitResponse.fromJson(json);
      expect(response.components, isEmpty);
      expect(response.connections, isEmpty);
    });
  });
}
