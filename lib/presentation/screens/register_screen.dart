import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _feeController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedRole = 'user';
  String _selectedSpec = 'General Physician';
  String _selectedQual = 'MBBS';

  final List<String> _specializations = [
    'General Physician',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Gynecology',
    'Dentistry',
    'Psychiatry',
    'ENT Specialist',
    'Ophthalmology',
    'Oncology',
  ];

  final List<String> _qualificationsList = [
    'MBBS',
    'MBBS, MD',
    'MBBS, MS',
    'BDS',
    'BDS, MDS',
    'BAMS',
    'BHMS',
    'MBBS, DNB',
    'DPT (Physiotherapy)',
    'PhD',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final result = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      gender: _selectedGender,
      role: _selectedRole,
      contact: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      age: _selectedRole == 'user' ? _ageController.text.trim() : null,
      specialization: _selectedRole == 'doctor' ? _selectedSpec : null,
      fee: _selectedRole == 'doctor' ? int.tryParse(_feeController.text) : null,
      qualifications: _selectedRole == 'doctor' ? _selectedQual : null,
    );

    if (!mounted) return;

    if (result['status'] == 'success') {
      if (_selectedRole == 'doctor') {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registration failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Registration Sent'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text(
              'Your profile is currently pending admin approval.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            Text(
              'An administrator will review your credentials shortly. You can log in and view your profile once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056b3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'GOT IT',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    const primaryColor = Color(0xFF0056b3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 30),
                _buildRoleSelector(primaryColor),
                const SizedBox(height: 30),

                _buildSectionTitle('Basic Information'),
                _buildTextField(
                  _nameController,
                  'Full Name',
                  Icons.person,
                  (v) => v!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _usernameController,
                  'Unique Username',
                  Icons.alternate_email,
                  (v) => v!.isEmpty ? 'Enter a username' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _emailController,
                  'Email Address',
                  Icons.email,
                  (v) {
                    if (v!.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email format';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _mobileController,
                  'Mobile Number',
                  Icons.phone,
                  (v) => v!.length < 10 ? 'Enter valid 10-digit number' : null,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Gender',
                        value: _selectedGender,
                        items: ['Male', 'Female', 'Other'],
                        onChanged: (v) => setState(() => _selectedGender = v!),
                        icon: Icons.wc,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        _cityController,
                        'City',
                        Icons.location_city,
                        (v) => v!.isEmpty ? 'Enter city' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _addressController,
                  _selectedRole == 'doctor'
                      ? 'Clinic/Hospital Address'
                      : 'Residential Address',
                  Icons.home,
                  (v) => v!.isEmpty ? 'Enter address' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  'Password',
                  Icons.lock,
                  (v) => v!.length < 6 ? 'Password must be 6+ chars' : null,
                  isPassword: true,
                ),

                const SizedBox(height: 30),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedRole == 'user'
                      ? _buildUserFields()
                      : _buildDoctorFields(),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildRoleSelector(Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _buildRoleChip('user', Icons.person_outline, 'Patient', color),
          _buildRoleChip(
            'doctor',
            Icons.medical_services_outlined,
            'Doctor',
            color,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, IconData icon, String label, Color color) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildUserFields() {
    return Column(
      key: const ValueKey('user_fields'),
      children: [
        _buildSectionTitle('Patient Details'),
        _buildTextField(
          _ageController,
          'Age',
          Icons.calendar_today,
          (v) => v!.isEmpty ? 'Enter age' : null,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildDoctorFields() {
    return Column(
      key: const ValueKey('doctor_fields'),
      children: [
        _buildSectionTitle('Professional Specialization'),
        _buildDropdown(
          label: 'Specialization',
          value: _selectedSpec,
          items: _specializations,
          onChanged: (v) => setState(() => _selectedSpec = v!),
          icon: Icons.workspace_premium,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Qualifications',
          value: _selectedQual,
          items: _qualificationsList,
          onChanged: (v) => setState(() => _selectedQual = v!),
          icon: Icons.school,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _feeController,
          'Consultation Fee (₹)',
          Icons.payments,
          (v) => v!.isEmpty ? 'Enter fee' : null,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    bool isPassword = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF0056b3)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData icon = Icons.category_outlined,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
