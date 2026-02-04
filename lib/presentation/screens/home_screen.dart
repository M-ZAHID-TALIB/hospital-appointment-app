import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/doctor_provider.dart';
import '../../logic/providers/appointment_provider.dart';
import 'doctor_details_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'appointments_screen.dart';
import 'admin_approval_screen.dart';
import 'edit_doctor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Advance Technology',
      'icon': 'assets/images/feature1.png',
      'desc': 'Modern societies reap great benefits.',
    },
    {
      'title': 'Comfortable Place',
      'icon': 'assets/images/feature2.png',
      'desc': 'A variety of treatments provided.',
    },
    {
      'title': 'Quality Equipment',
      'icon': 'assets/images/feature3.png',
      'desc': 'Used for diagnosis and treatment.',
    },
    {
      'title': 'Friendly Staff',
      'icon': 'assets/images/feature4.png',
      'desc': 'Caring staff makes environment healthy.',
    },
  ];

  final List<Map<String, dynamic>> _news = [
    {
      'title': 'Specialist Orthopedic & Robotic Centre',
      'date': '22 Jan 2020',
      'image': 'assets/images/news1.jpg',
    },
    {
      'title': 'Inauguration of Crystal OPD Wing',
      'date': '24 Jan 2020',
      'image': 'assets/images/news2.jpg',
    },
    {
      'title': 'Celebrating 55th Anniversary',
      'date': '18 Feb 2020',
      'image': 'assets/images/news3.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userRole == 'user') {
        Provider.of<DoctorProvider>(context, listen: false).fetchDoctors();
      } else if (auth.userId != null) {
        if (auth.userRole == 'doctor') {
          Provider.of<DoctorProvider>(
            context,
            listen: false,
          ).fetchCurrentDoctor(auth.userId!);
        }
        Provider.of<AppointmentProvider>(
          context,
          listen: false,
        ).fetchAppointments(auth.userId!, auth.userRole!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final primaryColor = const Color(0xFF0056b3);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'FindMyDoctor',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context, primaryColor, auth),
      body: auth.userRole == 'user'
          ? _buildUserBody(context, primaryColor)
          : _buildAppointmentBody(context, primaryColor, auth),
    );
  }

  Widget _buildUserBody(BuildContext context, Color primaryColor) {
    final doctorProvider = context.watch<DoctorProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(context, primaryColor),
          _buildFeaturesSection(),
          _buildAboutSection(primaryColor),
          _buildSectionTitle('Departments', showSeeAll: false),
          _buildDepartmentGrid(context),
          _buildEmergencyHotline(),
          _buildSectionTitle('Our Specialists'),
          doctorProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildDoctorCarousel(context),
          _buildSectionTitle('Recent Medical News'),
          _buildNewsSection(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAppointmentBody(
    BuildContext context,
    Color primaryColor,
    AuthProvider auth,
  ) {
    final appointmentProvider = context.watch<AppointmentProvider>();
    final doctorProvider = context.watch<DoctorProvider>();
    final appointments = appointmentProvider.appointments;

    // Doctor specific checks
    if (auth.userRole == 'doctor') {
      final currentDoc = doctorProvider.currentDoctor;

      if (doctorProvider.isLoading && currentDoc == null) {
        return const Center(child: CircularProgressIndicator());
      }

      // Check for Admin Approval
      if (currentDoc?.status == 'pending') {
        return _buildStatusOverlay(
          icon: Icons.hourglass_empty,
          title: 'Approval Pending',
          message:
              'Your account is under review by our administration. Please check back later.',
        );
      }

      // Check for Profile Completeness
      if (!doctorProvider.isProfileComplete(currentDoc)) {
        return _buildStatusOverlay(
          icon: Icons.edit_note,
          title: 'Profile Incomplete',
          message:
              'Please complete your profile details to start seeing patients.',
          buttonText: 'COMPLETE PROFILE',
          onTap: () async {
            if (currentDoc != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDoctorScreen(doctor: currentDoc),
                ),
              );
              doctorProvider.fetchCurrentDoctor(auth.userId!);
            }
          },
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(context, primaryColor),
        _buildSectionTitle(
          auth.userRole == 'admin' ? 'All Appointments' : 'My Patients',
        ),
        Expanded(
          child: appointmentProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : appointments.isEmpty
              ? const Center(child: Text('No appointments found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final item = appointments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          item.userName ?? item.doctorName ?? 'Record',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${item.appointmentDate} at ${item.slotTime}'),
                            if (item.refId != null)
                              Text(
                                'Ref: #${item.refId}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              item.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              color: _getStatusColor(item.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusOverlay({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0056b3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: const Color(0xFF0056b3)),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056b3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'visited':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Widget _buildDrawer(BuildContext context, Color color, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: color),
            accountName: Text(
              auth.userName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(auth.userRole?.toUpperCase() ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF0056b3)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: color),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          if (auth.userRole == 'user')
            ListTile(
              leading: Icon(Icons.calendar_today, color: color),
              title: const Text('My Appointments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentsScreen(),
                  ),
                );
              },
            ),
          ListTile(
            leading: Icon(Icons.info_outline, color: color),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.contact_support_outlined, color: color),
            title: const Text('Contact Support'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactScreen()),
              );
            },
          ),
          if (auth.userRole == 'admin')
            ListTile(
              leading: Icon(Icons.verified_user, color: color),
              title: const Text('Doctor Approvals'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminApprovalScreen(),
                  ),
                );
              },
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              auth.logout();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Opacity(
              opacity: 0.5,
              child: Image.asset('assets/images/logo.png', height: 40),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, Color color) {
    final auth = context.read<AuthProvider>();
    final doctorProvider = context.read<DoctorProvider>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${auth.userName}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find Medical Excellence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          if (auth.userRole == 'user')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => doctorProvider.setSearchQuery(value),
                decoration: const InputDecoration(
                  hintText: 'Search doctors or specialties...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF0056b3)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = true}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
          if (showSeeAll)
            TextButton(onPressed: () {}, child: const Text('See All')),
        ],
      ),
    );
  }

  Widget _buildDepartmentGrid(BuildContext context) {
    final doctorProvider = context.watch<DoctorProvider>();
    final depts = doctorProvider.departments;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: depts.length,
        itemBuilder: (context, index) {
          final dept = depts[index];
          final isSelected = doctorProvider.selectedDept == dept;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(dept),
              onSelected: (bool selected) {
                doctorProvider.setSelectedDept(dept);
              },
              selectedColor: const Color(0xFF0056b3).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF0056b3),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0056b3) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCarousel(BuildContext context) {
    final doctors = context.watch<DoctorProvider>().doctors;

    if (doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No doctors match your search')),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doc = doctors[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailsScreen(doctor: doc),
                ),
              );
            },
            child: Container(
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        doc.photoUrl ?? 'assets/doctor_pics/default.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          doc.dept ?? 'Specialist',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${doc.fee}',
                              style: const TextStyle(
                                color: Color(0xFF0056b3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'Available',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(feature['icon'], height: 40),
                const SizedBox(height: 12),
                Text(
                  feature['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0056b3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['desc'],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutSection(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to our clinic',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Shri Vasantrao Naik Govt. Medical College, Yavatmal. Leading the way in medical excellence.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'LEARN MORE',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/welcome.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyHotline() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.emergency, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text(
            'EMERGENCY HOTLINE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '(+91)-830-848-2128',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We provide 24/7 customer support',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Container(
      height: 250,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _news.length,
        itemBuilder: (context, index) {
          final news = _news[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.asset(
                    news['image'],
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical News',
                        style: TextStyle(
                          color: Color(0xFF0056b3),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
