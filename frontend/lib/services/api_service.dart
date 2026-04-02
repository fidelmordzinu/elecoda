import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/component_model.dart';
import '../models/circuit_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const String _defaultUrl = 'https://elecoda.onrender.com';

  String get baseUrl {
    final envUrl = dotenv.env['BACKEND_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return _defaultUrl;
  }

  Future<List<ComponentModel>> searchComponents(
    String query, {
    String? category,
  }) async {
    if (query.isEmpty) return [];

    final params = {'q': query, 'limit': '50'};
    if (category != null) params['category'] = category;

    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map(
              (json) => ComponentModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ApiException(
          'Search failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: '/search',
        );
      }
    } on SocketException {
      throw ApiException(
        'No internet connection. Check your network.',
        endpoint: '/search',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', endpoint: '/search');
    } on FormatException {
      throw ApiException(
        'Server returned invalid response',
        endpoint: '/search',
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e', endpoint: '/search');
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse(
      '$baseUrl/suggestions',
    ).replace(queryParameters: {'q': query, 'limit': '5'});

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final uri = Uri.parse('$baseUrl/categories');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ComponentModel> getComponent(int id) async {
    final uri = Uri.parse('$baseUrl/component/$id');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ComponentModel.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          'Failed to get component: ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: '/component/$id',
        );
      }
    } on SocketException {
      throw ApiException('No internet connection.', endpoint: '/component/$id');
    } on http.ClientException catch (e) {
      throw ApiException(
        'Network error: ${e.message}',
        endpoint: '/component/$id',
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e', endpoint: '/component/$id');
    }
  }

  Future<CircuitResponse> generateCircuit({
    required String query,
    required List<String> inventory,
  }) async {
    final uri = Uri.parse('$baseUrl/generate_circuit');

    try {
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
        throw ApiException(
          'Circuit generation failed: ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: '/generate_circuit',
        );
      }
    } on SocketException {
      throw ApiException(
        'No internet connection.',
        endpoint: '/generate_circuit',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Network error: ${e.message}',
        endpoint: '/generate_circuit',
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e', endpoint: '/generate_circuit');
    }
  }
}
