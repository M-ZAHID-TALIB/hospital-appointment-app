class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? gender;
  final String? contact;
  final String? age;
  final String? address;
  final String? city;
  final String? status;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.gender,
    this.contact,
    this.age,
    this.address,
    this.city,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      gender: json['gender'],
      contact: json['contact'],
      age: json['age'],
      address: json['address'],
      city: json['city'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'gender': gender,
      'contact': contact,
      'age': age,
      'address': address,
      'city': city,
      'status': status,
    };
  }
}
