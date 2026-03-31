import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/component_model.dart';
import '../services/api_service.dart';

class SearchProvider extends ChangeNotifier {
  final ApiService apiService;
  List<ComponentModel> _results = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;

  List<ComponentModel> get results => _results;
  List<Map<String, dynamic>> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SearchProvider({required this.apiService});

  Future<void> search(String query, {String? category}) async {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      _results = [];
      _suggestions = [];
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _results = await apiService.searchComponents(query, category: category);
    } catch (e) {
      _error = e.toString();
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void fetchSuggestions(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        _suggestions = await apiService.getSuggestions(query);
        notifyListeners();
      } catch (e) {
        debugPrint('Suggestions error: $e');
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
