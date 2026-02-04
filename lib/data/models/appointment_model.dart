class AppointmentModel {
  final int id;
  final String? refId;
  final int? doctorId;
  final String? doctorName;
  final int? userId;
  final String? userName;
  final String appointmentDate;
  final String slotTime;
  final String status;

  AppointmentModel({
    required this.id,
    this.refId,
    this.doctorId,
    this.doctorName,
    this.userId,
    this.userName,
    required this.appointmentDate,
    required this.slotTime,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      refId: json['ref_id'],
      doctorId: json['doctor_id'],
      doctorName:
          json['doctor_name'] ??
          (json['doctors'] != null ? json['doctors']['name'] : null),
      userId: json['user_id'],
      userName:
          json['user_name'] ??
          (json['hospital_users'] != null
              ? json['hospital_users']['name']
              : null),
      appointmentDate: json['appointment_date'] ?? json['date'] ?? '',
      slotTime: json['slot_time'] ?? json['slot'] ?? '',
      status: json['status'] ?? 'Active',
    );
  }
}
