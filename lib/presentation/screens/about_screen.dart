import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/doctor_model.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/doctor_provider.dart';
import 'edit_doctor_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).fetchDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0056b3);
    final auth = context.watch<AuthProvider>();
    final doctorProvider = context.watch<DoctorProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: doctorProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/banner-bg1.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'About Find My Doctor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Our Vision & Mission',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Shri Vasantrao Naik Govt. Medical College, Yavatmal was started by Government of Maharashtra in 1989. It is situated in a cozy non-polluted hilly area of Vidarbha, dedicated to providing medical excellence and accessible healthcare to all.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Meet Our Specialists',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: doctorProvider.doctors.length,
                          itemBuilder: (context, index) {
                            return _buildDoctorCard(
                              context,
                              doctorProvider.doctors[index],
                              primaryColor,
                              auth,
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset('assets/images/welcome.png'),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDoctorCard(
    BuildContext context,
    DoctorModel doc,
    Color color,
    AuthProvider auth,
  ) {
    bool canEdit =
        auth.userRole == 'admin' ||
        (auth.userRole == 'doctor' && auth.userId == doc.id.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(
              doc.photoUrl ?? 'assets/doctor_pics/default.png',
            ),
          ),
        ),
        title: Text(
          doc.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              doc.dept ?? 'Specialist',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (doc.qualifications != null)
              Text(
                doc.qualifications!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: canEdit
            ? Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: color),
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDoctorScreen(doctor: doc),
                      ),
                    );
                    if (updated == true) {
                      if (context.mounted) {
                        Provider.of<DoctorProvider>(
                          context,
                          listen: false,
                        ).fetchDoctors();
                      }
                    }
                  },
                ),
              )
            : Icon(Icons.chevron_right, color: Colors.grey[300]),
      ),
    );
  }
}
