class UserModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String dob;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String userRole;

  const UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.dob,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    this.userRole = 'education',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? userId}) {
    return UserModel(
      userId: userId ?? map['userId'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      dob: map['dob'] ?? '',
      addressLine1: map['address_line1'] ?? map['address'] ?? '', // Backward compatibility
      addressLine2: map['address_line2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      zipCode: map['zip_code'] ?? '',
      userRole: map['user_role'] ?? 'education',
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
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'user_role': userRole,
    };
  }

  UserModel copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? dob,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? userRole,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      userRole: userRole ?? this.userRole,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, firstName: $firstName, lastName: $lastName, phone: $phone, email: $email, dob: $dob, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, state: $state, country: $country, zipCode: $zipCode, userRole: $userRole)';
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
        other.addressLine1 == addressLine1 &&
        other.addressLine2 == addressLine2 &&
        other.city == city &&
        other.state == state &&
        other.country == country &&
        other.zipCode == zipCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      firstName,
      lastName,
      phone,
      email,
      dob,
      addressLine1,
      addressLine2,
      city,
      state,
      country,
      zipCode,
    );
  }
}
