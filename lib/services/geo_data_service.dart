import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class GeoDataService {
  static final GeoDataService _instance = GeoDataService._internal();
  factory GeoDataService() => _instance;
  GeoDataService._internal();

  List<dynamic>? _allCountriesData;
  List<String>? _countryNames;

  bool get isLoaded => _allCountriesData != null;

  Future<void> loadData() async {
    if (isLoaded) return;
    try {
      // Use compute to parse large JSON in a separate isolate to prevent UI lag
      final String jsonString = await rootBundle.loadString('assets/countries_states_cities.json');
      _allCountriesData = await compute(json.decode, jsonString) as List<dynamic>;
      _countryNames = _allCountriesData!.map((c) => c['name'].toString()).toList();
    } catch (e) {
      debugPrint('Error loading geo data: $e');
    }
  }

  List<dynamic> get allCountriesData => _allCountriesData ?? [];
  List<String> get countryNames => _countryNames ?? [];

  List<String> getStates(String countryName) {
    if (_allCountriesData == null) return [];
    final country = _allCountriesData!.firstWhere(
      (c) => c['name'] == countryName, 
      orElse: () => null
    );
    return country != null 
        ? (country['states'] as List).map((s) => s['name'].toString()).toList() 
        : [];
  }

  List<String> getCities(String countryName, String stateName) {
    if (_allCountriesData == null) return [];
    final country = _allCountriesData!.firstWhere(
      (c) => c['name'] == countryName, 
      orElse: () => null
    );
    if (country != null) {
      final state = (country['states'] as List).firstWhere(
        (s) => s['name'] == stateName, 
        orElse: () => null
      );
      return state != null 
          ? (state['cities'] as List).map((c) => c['name'].toString()).toList() 
          : [];
    }
    return [];
  }
}
