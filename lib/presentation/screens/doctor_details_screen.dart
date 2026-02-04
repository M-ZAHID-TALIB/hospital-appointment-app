import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../data/models/doctor_model.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/appointment_provider.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final ApiService _apiService = ApiService();
  String _selectedDate = '';
  String _selectedSlot = '';
  bool _isBooking = false;
  bool _isLoadingFee = true;
  int _registrationFee = 0;
  List<Map<String, dynamic>> _availableDays = [];

  @override
  void initState() {
    super.initState();
    _prepareDates();
    _checkFees();
  }

  void _prepareDates() {
    final now = DateTime.now();
    _availableDays = [
      {'label': 'Today', 'date': DateFormat('EEEE MMMM d, yyyy').format(now)},
      {
        'label': 'Tomorrow',
        'date': DateFormat(
          'EEEE MMMM d, yyyy',
        ).format(now.add(const Duration(days: 1))),
      },
      {
        'label': 'Later',
        'date': DateFormat(
          'EEEE MMMM d, yyyy',
        ).format(now.add(const Duration(days: 2))),
      },
    ];
    _selectedDate = _availableDays[0]['date'];
  }

  void _checkFees() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      bool applyFee = await _apiService.doesApplyRegistrationFee(auth.userId!);
      if (mounted) {
        setState(() {
          _registrationFee = applyFee ? 100 : 0;
          _isLoadingFee = false;
        });
      }
    } else {
      setState(() => _isLoadingFee = false);
    }
  }

  void _bookAppointment() async {
    if (_selectedSlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isBooking = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(
      context,
      listen: false,
    );

    if (!auth.isAuthenticated) {
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book appointments')),
      );
      return;
    }

    final appointmentData = {
      'ref_id': DateTime.now().millisecondsSinceEpoch.toString().substring(7),
      'user_id': int.parse(auth.userId!),
      'doctor_id': widget.doctor.id,
      'appointment_date': _selectedDate,
      'slot_time': _selectedSlot,
      'appointment_type': 'Normal',
      'registration_fee': _registrationFee,
      'consultation_fee': widget.doctor.fee,
      'status': 'Active',
    };

    final result = await appointmentProvider.addAppointment(appointmentData);

    if (mounted) {
      setState(() => _isBooking = false);
      if (result['status'] == 'success') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Booking Successful!'),
            content: Text(
              'Your appointment has been booked. Reference ID: #${appointmentData['ref_id']}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${result['message']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0056b3);
    final doc = widget.doctor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'doctor_${doc.id}',
                child: Image.asset(
                  doc.photoUrl ?? 'assets/doctor_pics/default.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            doc.dept ?? 'Specialist',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '₹${doc.fee}',
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSection('Qualifications', doc.qualifications ?? 'N/A'),
                  const SizedBox(height: 20),
                  _buildSection(
                    'About',
                    doc.expertise ?? 'Specialist in ${doc.dept}',
                  ),
                  const Divider(height: 50),
                  const Text(
                    'Select Schedule',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  _buildDateSelector(),
                  const SizedBox(height: 30),
                  const Text(
                    'Available Slots',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  _buildSlotSelector(),
                  const SizedBox(height: 40),
                  _buildPriceSummary(primaryColor),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isBooking
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CONFIRM BOOKING',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: _availableDays.map((dateMap) {
        bool isSelected = _selectedDate == dateMap['date'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedDate = dateMap['date'];
              _selectedSlot = '';
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0056b3) : Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0056b3)
                      : Colors.grey[200]!,
                ),
              ),
              child: Text(
                dateMap['label'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlotSelector() {
    String dayOfWeek = _selectedDate.split(' ')[0];
    final timings = widget.doctor.timings ?? [];
    var todayTiming = timings.firstWhere(
      (t) => t.day == dayOfWeek,
      orElse: () => DoctorTiming(id: 0, day: dayOfWeek),
    );

    if (todayTiming.id == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          'No slots available for this day',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    List<String> slots = [];
    if (todayTiming.morningStart != null) {
      slots.add(
        'Morning: ${todayTiming.morningStart} - ${todayTiming.morningEnd}',
      );
    }
    if (todayTiming.eveningStart != null) {
      slots.add(
        'Evening: ${todayTiming.eveningStart} - ${todayTiming.eveningEnd}',
      );
    }

    return Column(
      children: slots.map((slot) {
        bool isSelected = _selectedSlot == slot;
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slot),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF0056b3) : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? const Color(0xFF0056b3) : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  slot,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0056b3)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSummary(Color color) {
    if (_isLoadingFee) return const Center(child: CircularProgressIndicator());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _priceRow('Consultation Fee', '₹${widget.doctor.fee}'),
          if (_registrationFee > 0) ...[
            const SizedBox(height: 12),
            _priceRow('Registration Fee (First Time)', '₹$_registrationFee'),
          ],
          const Divider(height: 32),
          _priceRow(
            'Total Amount',
            '₹${widget.doctor.fee + _registrationFee}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 22 : 15,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF0056b3) : Colors.black,
          ),
        ),
      ],
    );
  }
}
