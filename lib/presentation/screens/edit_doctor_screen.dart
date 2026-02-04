import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/doctor_model.dart';
import '../../data/services/api_service.dart';
import '../../logic/providers/doctor_provider.dart';

class EditDoctorScreen extends StatefulWidget {
  final DoctorModel doctor;

  const EditDoctorScreen({super.key, required this.doctor});

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _deptController;
  late TextEditingController _feeController;
  late TextEditingController _qualController;
  late TextEditingController _expertiseController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  List<DoctorTiming> _timings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctor.name);
    _deptController = TextEditingController(text: widget.doctor.dept);
    _feeController = TextEditingController(text: widget.doctor.fee.toString());
    _qualController = TextEditingController(
      text: widget.doctor.qualifications == 'N/A'
          ? ''
          : widget.doctor.qualifications,
    );
    _expertiseController = TextEditingController(
      text: widget.doctor.expertise == 'Pending profile completion'
          ? ''
          : widget.doctor.expertise,
    );
    _phoneController = TextEditingController(
      text: widget.doctor.phone == '0000000000' ? '' : widget.doctor.phone,
    );
    _addressController = TextEditingController(
      text: widget.doctor.address == 'Pending completion'
          ? ''
          : widget.doctor.address,
    );
    _cityController = TextEditingController(
      text: widget.doctor.city == 'Pending completion'
          ? ''
          : widget.doctor.city,
    );
    _timings = List.from(widget.doctor.timings ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _feeController.dispose();
    _qualController.dispose();
    _expertiseController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'dept': _deptController.text,
      'fee': int.parse(_feeController.text),
      'qualifications': _qualController.text,
      'expertise': _expertiseController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'city': _cityController.text,
    };

    final success = await _apiService.updateDoctor(widget.doctor.id, data);

    if (success) {
      final timingData = _timings
          .map(
            (t) => {
              'available_day': t.day,
              'morning_timing_start': t.morningStart,
              'morning_timing_end': t.morningEnd,
              'evening_timing_start': t.eveningStart,
              'evening_timing_end': t.eveningEnd,
            },
          )
          .toList();

      await _apiService.updateDoctorTimings(widget.doctor.id, timingData);

      if (mounted) {
        // Refresh doctor data in provider
        final docProvider = Provider.of<DoctorProvider>(context, listen: false);
        docProvider.fetchDoctors();
        // Also refresh current doctor specifically
        docProvider.fetchCurrentDoctor(widget.doctor.id.toString());
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text(
            success ? 'Profile updated successfully' : 'Update failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0056b3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Complete Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    _buildTextField(
                      _nameController,
                      'Doctor Name',
                      Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _deptController,
                      'Department / Specialization',
                      Icons.medical_services,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _phoneController,
                      'Contact Number',
                      Icons.phone,
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _feeController,
                      'Consultation Fee (₹)',
                      Icons.payments,
                      isNumber: true,
                    ),
                    const SizedBox(height: 40),

                    _buildSectionTitle('Professional Details'),
                    _buildTextField(
                      _qualController,
                      'Qualifications (e.g. MBBS, MD)',
                      Icons.school,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _expertiseController,
                      'Expertise / Biography',
                      Icons.info,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 40),

                    _buildSectionTitle('Location Details'),
                    _buildTextField(
                      _cityController,
                      'City',
                      Icons.location_city,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _addressController,
                      'Full Clinic/Hospital Address',
                      Icons.home,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Available Timings'),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _timings.add(DoctorTiming(id: 0, day: 'Monday'));
                            });
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: primaryColor,
                          ),
                          label: const Text(
                            'Add Slot',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._timings.asMap().entries.map(
                      (entry) => _buildTimingCard(
                        entry.key,
                        entry.value,
                        primaryColor,
                      ),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'SAVE PROFILE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0056b3),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildTimingCard(int index, DoctorTiming timing, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: timing.day,
                  decoration: const InputDecoration(
                    labelText: 'Available Day',
                    border: InputBorder.none,
                  ),
                  items:
                      [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ]
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _timings[index] = _updateTiming(timing, day: val);
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() => _timings.removeAt(index)),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  'Morning Start',
                  timing.morningStart,
                  (v) => _updateTimingState(index, morningStart: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  'Morning End',
                  timing.morningEnd,
                  (v) => _updateTimingState(index, morningEnd: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  'Evening Start',
                  timing.eveningStart,
                  (v) => _updateTimingState(index, eveningStart: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  'Evening End',
                  timing.eveningEnd,
                  (v) => _updateTimingState(index, eveningEnd: v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateTimingState(
    int index, {
    String? morningStart,
    String? morningEnd,
    String? eveningStart,
    String? eveningEnd,
  }) {
    setState(() {
      _timings[index] = _updateTiming(
        _timings[index],
        morningStart: morningStart,
        morningEnd: morningEnd,
        eveningStart: eveningStart,
        eveningEnd: eveningEnd,
      );
    });
  }

  DoctorTiming _updateTiming(
    DoctorTiming old, {
    String? day,
    String? morningStart,
    String? morningEnd,
    String? eveningStart,
    String? eveningEnd,
  }) {
    return DoctorTiming(
      id: old.id,
      day: day ?? old.day,
      morningStart: morningStart ?? old.morningStart,
      morningEnd: morningEnd ?? old.morningEnd,
      eveningStart: eveningStart ?? old.eveningStart,
      eveningEnd: eveningEnd ?? old.eveningEnd,
    );
  }

  Widget _buildTimeField(
    String label,
    String? current,
    Function(String) onChanged,
  ) {
    return TextFormField(
      initialValue: current,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'e.g. 09:00 AM',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: onChanged,
    );
  }
}
