class UserModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String dob;
  final String address;

  const UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.dob,
    required this.address,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? userId}) {
    return UserModel(
      userId: userId ?? map['userId'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      dob: map['dob'] ?? '',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'dob': dob,
      'address': address,
    };
  }

  UserModel copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? dob,
    String? address,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, firstName: $firstName, lastName: $lastName, phone: $phone, email: $email, dob: $dob, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.userId == userId &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.phone == phone &&
        other.email == email &&
        other.dob == dob &&
        other.address == address;
  }

  @override
  int get hashCode {
    return Object.hash(userId, firstName, lastName, phone, email, dob, address);
  }
}
