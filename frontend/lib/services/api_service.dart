import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/component_model.dart';
import '../models/circuit_model.dart';

class ApiService {
  String get baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  Future<List<ComponentModel>> searchComponents(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse(
      '$baseUrl/search',
    ).replace(queryParameters: {'q': query, 'limit': '50'});

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => ComponentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Search failed: ${response.statusCode}');
    }
  }

  Future<ComponentModel> getComponent(int id) async {
    final uri = Uri.parse('$baseUrl/component/$id');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ComponentModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to get component: ${response.statusCode}');
    }
  }

  Future<CircuitResponse> generateCircuit({
    required String query,
    required List<String> inventory,
  }) async {
    final uri = Uri.parse('$baseUrl/generate_circuit');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'query': query, 'inventory': inventory}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return CircuitResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Circuit generation failed: ${response.statusCode}');
    }
  }
}
