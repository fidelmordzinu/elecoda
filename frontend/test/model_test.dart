import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/component_model.dart';
import 'package:frontend/models/circuit_model.dart';

void main() {
  group('ComponentModel', () {
    test('fromJson parses valid JSON', () {
      final json = {
        'id': 1,
        'part_number': 'RC0402FR-0710KL',
        'manufacturer': 'Yageo',
        'category': 'res',
      };
      final component = ComponentModel.fromJson(json);
      expect(component.id, 1);
      expect(component.partNumber, 'RC0402FR-0710KL');
      expect(component.manufacturer, 'Yageo');
      expect(component.category, 'res');
    });

    test('toJson serializes correctly', () {
      final component = ComponentModel(
        id: 1,
        partNumber: 'RC0402FR-0710KL',
        manufacturer: 'Yageo',
        category: 'res',
      );
      final json = component.toJson();
      expect(json['id'], 1);
      expect(json['part_number'], 'RC0402FR-0710KL');
      expect(json['manufacturer'], 'Yageo');
    });

    test('handles null fields', () {
      final json = {'part_number': 'TEST', 'manufacturer': 'TestMfg'};
      final component = ComponentModel.fromJson(json);
      expect(component.partNumber, 'TEST');
      expect(component.manufacturer, 'TestMfg');
      expect(component.category, isNull);
    });

    test('parses attributes from JSON string', () {
      final json = {
        'part_number': 'TEST',
        'manufacturer': 'TestMfg',
        'attributes': '{"resistance": "10k"}',
      };
      final component = ComponentModel.fromJson(json);
      expect(component.attributes, isNotNull);
      expect(component.attributes!['resistance'], '10k');
    });

    test('parses attributes from JSON object', () {
      final json = {
        'part_number': 'TEST',
        'manufacturer': 'TestMfg',
        'attributes': {'capacitance': '100nF'},
      };
      final component = ComponentModel.fromJson(json);
      expect(component.attributes, isNotNull);
      expect(component.attributes!['capacitance'], '100nF');
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
