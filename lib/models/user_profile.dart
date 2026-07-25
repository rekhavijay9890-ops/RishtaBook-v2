/// Typed wrapper around a `users/{uid}` Firestore document.
class UserProfile {
  final String uid;
  final String fullName;
  final String dob;
  final String gender;
  final String mobile;
  final String religion;
  final String category;
  final String village;
  final String district;
  final String state;
  final String occupation;
  final String familyDetails;
  final String requirements;
  final String email;

  /// none | pending | approved | rejected
  final String verificationStatus;
  final bool isVerified;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.mobile,
    required this.religion,
    required this.category,
    required this.village,
    required this.district,
    required this.state,
    required this.occupation,
    required this.familyDetails,
    required this.requirements,
    required this.email,
    required this.verificationStatus,
    required this.isVerified,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      fullName: data['fullName'] ?? 'Naam nahi likha',
      dob: data['age'] ?? '--',
      gender: data['gender'] ?? '',
      mobile: data['mobile'] ?? '',
      religion: data['religion'] ?? '--',
      category: data['category'] ?? 'N/A',
      village: data['village'] ?? '--',
      district: data['district'] ?? '--',
      state: data['state'] ?? '--',
      occupation: data['occupation'] ?? 'N/A',
      familyDetails: data['familyDetails'] ?? 'N/A',
      requirements: data['requirements'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
      verificationStatus: data['verificationStatus'] ?? 'none',
      isVerified: data['isVerified'] ?? false,
    );
  }

  String get location =>
      [village, district, state].where((s) => s.isNotEmpty && s != '--').join(', ');

  bool get isFemale => gender.toLowerCase() == 'female';
  bool get isMale => gender.toLowerCase() == 'male';
}
