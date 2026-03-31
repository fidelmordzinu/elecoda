import 'package:flutter/foundation.dart';
import '../models/component_model.dart';
import '../services/api_service.dart';

class SearchProvider extends ChangeNotifier {
  final ApiService apiService;
  List<ComponentModel> _results = [];
  bool _isLoading = false;
  String? _error;

  List<ComponentModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SearchProvider({required this.apiService});

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _results = [];
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _results = await apiService.searchComponents(query);
    } catch (e) {
      _error = e.toString();
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
