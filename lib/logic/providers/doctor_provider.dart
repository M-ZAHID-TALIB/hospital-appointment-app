import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../data/models/doctor_model.dart';

class DoctorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<DoctorModel> _allDoctors = [];
  List<DoctorModel> _filteredDoctors = [];
  List<DoctorModel> _pendingDoctors = [];
  DoctorModel? _currentDoctor;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedDept = 'All';

  List<DoctorModel> get doctors => _filteredDoctors;
  List<DoctorModel> get pendingDoctors => _pendingDoctors;
  DoctorModel? get currentDoctor => _currentDoctor;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedDept => _selectedDept;

  List<String> get departments {
    final depts = _allDoctors
        .map((d) => d.dept ?? 'Specialist')
        .toSet()
        .toList();
    depts.sort();
    return ['All', ...depts];
  }

  Future<void> fetchDoctors() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allDoctors = await _apiService.getDoctors();
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentDoctor(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentDoctor = await _apiService.getDoctorById(int.parse(id));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingDoctors() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingDoctors = await _apiService.getPendingDoctors();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveDoctor(int id) async {
    final success = await _apiService.approveDoctor(id);
    if (success) {
      _pendingDoctors.removeWhere((d) => d.id == id);
      fetchDoctors(); // Refresh active list
      notifyListeners();
    }
    return success;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSelectedDept(String dept) {
    _selectedDept = dept;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredDoctors = _allDoctors.where((doctor) {
      final matchesSearch =
          doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (doctor.dept?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesDept =
          _selectedDept == 'All' || doctor.dept == _selectedDept;

      return matchesSearch && matchesDept;
    }).toList();
    notifyListeners();
  }

  Future<DoctorModel?> getDoctorById(int id) async {
    return await _apiService.getDoctorById(id);
  }

  bool isProfileComplete(DoctorModel? doctor) {
    if (doctor == null) return false;
    return doctor.status == 'active' &&
        doctor.expertise != 'Pending profile completion' &&
        _isValidValue(doctor.expertise) &&
        _isValidValue(doctor.qualifications);
  }

  bool _isValidValue(String? val) {
    return val != null &&
        val.isNotEmpty &&
        val != 'N/A' &&
        val != 'Pending profile completion';
  }
}
