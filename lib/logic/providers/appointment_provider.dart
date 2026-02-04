import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/api_service.dart';
import '../../data/models/appointment_model.dart';

class AppointmentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _supabase = Supabase.instance.client;

  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  StreamSubscription? _realtimeSubscription;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;

  Future<void> fetchAppointments(
    String userId,
    String role, {
    bool isRealtime = false,
  }) async {
    if (_isLoading && !isRealtime) return;

    if (!isRealtime) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (role == 'user') {
        _appointments = await _apiService.getUserAppointments(userId);
      } else if (role == 'doctor') {
        _appointments = await _apiService.getDoctorAppointments(userId);
      } else if (role == 'admin') {
        _appointments = await _apiService.getAdminAppointments();
      }

      if (!isRealtime) {
        _setupRealtime(userId, role);
      }
    } catch (e) {
      // In a real app, handle error UI state
    } finally {
      if (!isRealtime) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _setupRealtime(String userId, String role) {
    _realtimeSubscription?.cancel();

    _realtimeSubscription = _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          // Re-fetch but marked as realtime to prevent infinite loop
          fetchAppointments(userId, role, isRealtime: true);
        });
  }

  Future<Map<String, dynamic>> addAppointment(Map<String, dynamic> data) async {
    final result = await _apiService.addAppointment(data);
    return result;
  }

  Future<bool> cancelAppointment(int id) async {
    final success = await _apiService.cancelAppointment(id);
    return success;
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
