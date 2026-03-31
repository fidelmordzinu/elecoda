import 'package:flutter/foundation.dart';
import '../models/circuit_model.dart';
import '../services/api_service.dart';

class CircuitProvider extends ChangeNotifier {
  final ApiService apiService;
  CircuitResponse? _response;
  bool _isLoading = false;
  String? _error;

  CircuitResponse? get response => _response;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CircuitProvider({required this.apiService});

  Future<void> generateCircuit({
    required String query,
    required List<String> inventory,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _response = await apiService.generateCircuit(
        query: query,
        inventory: inventory,
      );
    } catch (e) {
      _error = e.toString();
      _response = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _response = null;
    _error = null;
    notifyListeners();
  }
}
