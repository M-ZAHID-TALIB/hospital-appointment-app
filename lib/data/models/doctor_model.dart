class DoctorModel {
  final int id;
  final String name;
  final String? specialization;
  final String? dept;
  final String? photo;
  final String? photoUrl;
  final int fee;
  final String? qualifications;
  final String? expertise;
  final String? status;
  final String? phone;
  final String? address;
  final String? city;
  final List<DoctorTiming>? timings;

  DoctorModel({
    required this.id,
    required this.name,
    this.specialization,
    this.dept,
    this.photo,
    this.photoUrl,
    required this.fee,
    this.qualifications,
    this.expertise,
    this.status,
    this.phone,
    this.address,
    this.city,
    this.timings,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    var timingsList = json['doctor_timings'] as List?;
    List<DoctorTiming>? doctorTimings = timingsList
        ?.map((i) => DoctorTiming.fromJson(i))
        .toList();

    return DoctorModel(
      id: json['id'],
      name: json['name'] ?? '',
      specialization: json['specialization'],
      dept: json['dept'] ?? json['specialization'],
      photo: json['photo'],
      photoUrl: json['photo_url'],
      fee: json['fee'] ?? 500,
      qualifications: json['qualifications'],
      expertise: json['expertise'],
      status: json['status'],
      phone: json['phone'] ?? json['contact'],
      address: json['address'],
      city: json['city'],
      timings: doctorTimings,
    );
  }
}

class DoctorTiming {
  final int id;
  final String day;
  final String? morningStart;
  final String? morningEnd;
  final String? eveningStart;
  final String? eveningEnd;

  DoctorTiming({
    required this.id,
    required this.day,
    this.morningStart,
    this.morningEnd,
    this.eveningStart,
    this.eveningEnd,
  });

  factory DoctorTiming.fromJson(Map<String, dynamic> json) {
    return DoctorTiming(
      id: json['id'],
      day: json['available_day'] ?? json['day'] ?? '',
      morningStart: json['morning_timing_start'],
      morningEnd: json['morning_timing_end'],
      eveningStart: json['evening_timing_start'],
      eveningEnd: json['evening_timing_end'],
    );
  }
}
