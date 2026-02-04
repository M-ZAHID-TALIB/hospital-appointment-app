import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';

class ApiService {
  final supabase = Supabase.instance.client;
  final logger = Logger();

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    try {
      logger.i('Login attempt: Email: $email, Role: $role');
      final response = await supabase
          .from('hospital_users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .eq('role', role)
          .limit(1)
          .maybeSingle();

      logger.i('Login response: $response');

      if (response != null) {
        String finalId = response['id'].toString();

        // If doctor, find their actual doctor_id from 'doctors' table
        if (role == 'doctor') {
          final doctorProfile = await supabase
              .from('doctors')
              .select('id')
              .eq('email', email)
              .maybeSingle();
          if (doctorProfile != null) {
            finalId = doctorProfile['id'].toString();
          }
        }

        return {
          'status': 'success',
          'user': {
            'id': finalId,
            'name': response['name'],
            'email': response['email'],
            'role': response['role'],
          },
        };
      } else {
        // Diagnostic check: check if user exists with just email
        final emailCheck = await supabase
            .from('hospital_users')
            .select('role')
            .eq('email', email)
            .limit(1)
            .maybeSingle();

        if (emailCheck == null) {
          // Check if this email exists in the 'doctors' table instead
          final doctorCheck = await supabase
              .from('doctors')
              .select('id, name')
              .eq('email', email)
              .maybeSingle();

          if (doctorCheck != null) {
            return {
              'status': 'error',
              'message':
                  'Doctor found but has no login account. Please register this email in hospital_users table.',
            };
          }
          return {'status': 'error', 'message': 'Email not found in database'};
        } else if (emailCheck['role'].toString().toLowerCase() !=
            role.toLowerCase()) {
          logger.w(
            'Role Mismatch Debug: Database has "${emailCheck['role']}", UI requested "$role"',
          );
          return {
            'status': 'error',
            'message':
                'Role mismatch. This email is registered as ${emailCheck['role']}. Please select the correct role in the login screen.',
          };
        } else {
          // Diagnostic: If we are here, it means email + role matched for something,
          // but maybe the password was wrong OR multiple exist.
          final allUsersWithEmail = await supabase
              .from('hospital_users')
              .select('name, role, password')
              .eq('email', email);

          if (allUsersWithEmail.length > 1) {
            logger.w(
              'CRITICAL: Multiple users found with this email: ${allUsersWithEmail.map((u) => "${u['name']} (${u['role']})").toList()}',
            );
            return {
              'status': 'error',
              'message':
                  'Multiple accounts found for this email. Please use unique emails for each doctor.',
            };
          }
          return {'status': 'error', 'message': 'Invalid password'};
        }
      }
    } catch (e) {
      logger.e('Login Error: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String role, // Now dynamic
    String? contact,
    String? age,
    String? address,
    String? city,
    String? specialization,
    String? username,
    int? fee,
    String? qualifications,
  }) async {
    try {
      // 1. Create Login Account
      final userResponse = await supabase
          .from('hospital_users')
          .insert({
            'name': name,
            'email': email,
            'password': password,
            'gender': gender,
            'contact': contact,
            'age': age,
            'address': address,
            'city': city,
            'role': role,
            'status': 'active',
          })
          .select()
          .single();

      final userId = userResponse['id'];

      // 2. If registering as a doctor, create their profile entry in the doctors table
      if (role == 'doctor') {
        await supabase.from('doctors').insert({
          'doctor_id':
              userId, // Linking the login account ID to the doctor profile
          'name': name,
          'email': email,
          'dept': specialization ?? 'General Specialist',
          'photo': 'default.png',
          'fee': fee ?? 500,
          'qualifications': qualifications ?? 'N/A',
          'status': 'pending',
          'address': address ?? 'Consultation Clinic',
          'contact': contact ?? 'N/A',
          'gender': gender,
          'username': username ?? email.split('@')[0],
          'password': password,
          'expertise': 'Specialist in $specialization',
        });
      }

      return {'status': 'success', 'message': 'Registration successful'};
    } catch (e) {
      logger.e('Register Error: $e');
      return {'status': 'error', 'message': 'Registration error: $e'};
    }
  }

  Future<List<DoctorModel>> getDoctors() async {
    try {
      final response = await supabase
          .from('doctors')
          .select('*, doctor_timings(*)')
          .eq('status', 'active');

      return response
          .map(
            (doc) => DoctorModel.fromJson({
              ...doc,
              'photo_url': 'assets/doctor_pics/${doc['photo']}',
            }),
          )
          .toList();
    } catch (e) {
      logger.e('GetDoctors Error: $e');
      return [];
    }
  }

  Future<List<DoctorModel>> getPendingDoctors() async {
    try {
      final response = await supabase
          .from('doctors')
          .select('*, doctor_timings(*)')
          .eq('status', 'pending');

      return response
          .map(
            (doc) => DoctorModel.fromJson({
              ...doc,
              'photo_url': 'assets/doctor_pics/${doc['photo']}',
            }),
          )
          .toList();
    } catch (e) {
      logger.e('GetPendingDoctors Error: $e');
      return [];
    }
  }

  Future<bool> approveDoctor(int id) async {
    try {
      await supabase.from('doctors').update({'status': 'active'}).eq('id', id);
      return true;
    } catch (e) {
      logger.e('ApproveDoctor Error: $e');
      return false;
    }
  }

  Future<DoctorModel?> getDoctorById(int id) async {
    try {
      final response = await supabase
          .from('doctors')
          .select('*, doctor_timings(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return DoctorModel.fromJson({
        ...response,
        'photo_url': 'assets/doctor_pics/${response['photo']}',
      });
    } catch (e) {
      logger.e('GetDoctorById Error: $e');
      return null;
    }
  }

  Future<bool> updateDoctor(int id, Map<String, dynamic> data) async {
    try {
      await supabase.from('doctors').update(data).eq('id', id);
      return true;
    } catch (e) {
      logger.e('UpdateDoctor Error: $e');
      return false;
    }
  }

  Future<bool> updateDoctorTimings(
    int doctorId,
    List<Map<String, dynamic>> timingsList,
  ) async {
    try {
      await supabase.from('doctor_timings').delete().eq('doctor_id', doctorId);
      if (timingsList.isNotEmpty) {
        await supabase
            .from('doctor_timings')
            .insert(
              timingsList.map((t) => {...t, 'doctor_id': doctorId}).toList(),
            );
      }
      return true;
    } catch (e) {
      logger.e('UpdateDoctorTimings Error: $e');
      return false;
    }
  }

  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    try {
      final response = await supabase
          .from('appointments')
          .select('*, doctors(name)')
          .eq('user_id', int.parse(userId));

      return response.map((app) => AppointmentModel.fromJson(app)).toList();
    } catch (e) {
      logger.e('GetUserAppointments Error: $e');
      return [];
    }
  }

  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    try {
      final response = await supabase
          .from('appointments')
          .select('*, hospital_users(name)')
          .eq('doctor_id', int.parse(doctorId));

      return response.map((app) => AppointmentModel.fromJson(app)).toList();
    } catch (e) {
      logger.e('GetDoctorAppointments Error: $e');
      return [];
    }
  }

  Future<List<AppointmentModel>> getAdminAppointments() async {
    try {
      final response = await supabase
          .from('appointments')
          .select('*, doctors(name), hospital_users(name)');

      return response.map((app) => AppointmentModel.fromJson(app)).toList();
    } catch (e) {
      logger.e('GetAdminAppointments Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addAppointment(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from('appointments')
          .insert(data)
          .select()
          .single();
      return {'status': 'success', 'id': response['id']};
    } on PostgrestException catch (e) {
      logger.e('AddAppointment PostgrestError: ${e.message} (Code: ${e.code})');
      String userMessage = 'Booking failed. Please try again.';
      if (e.code == '23503') {
        userMessage = 'Relationship check failed. Please refresh doctors list.';
      } else if (e.code == '23505') {
        userMessage = 'Slot already booked. Please choose another time.';
      }
      return {'status': 'error', 'message': userMessage};
    } catch (e) {
      logger.e('AddAppointment Error: $e');
      return {
        'status': 'error',
        'message': 'Booking error. Please check connection.',
      };
    }
  }

  Future<bool> cancelAppointment(int appointmentId) async {
    try {
      await supabase
          .from('appointments')
          .update({'status': 'Cancelled'})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      logger.e('CancelAppointment Error: $e');
      return false;
    }
  }

  Future<bool> doesApplyRegistrationFee(String userId) async {
    try {
      final response = await supabase
          .from('appointments')
          .select()
          .eq('user_id', int.parse(userId));
      return response.isEmpty;
    } catch (e) {
      return true;
    }
  }
}
