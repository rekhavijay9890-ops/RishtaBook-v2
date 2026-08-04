import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed wrapper around a `users/{uid}` Firestore document.
class UserProfile {
  final String uid;
  final String fullName;
  final String dob;
  final String gender;
  final String mobile;
  final String religion;
  final String category;
  final String caste;
  final String gotra;
  final String village;
  final String district;
  final String state;
  final String occupation;
  final String brothers;
  final String sisters;
  final String familyDetails;
  final String requirements;
  final String email;
  final String verificationStatus;
  final bool isVerified;
  final String rashi;
  final String nakshatra;
  final String manglik;
  final int credits;
  final List<String> photoUrls;
  final int? heightCm;
  final String maritalStatus;
  final String education;
  final String motherTongue;
  final String incomeBand;
  final bool photosPrivate;
  final List<String> blockedUids;
  final DateTime? boostedUntil;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.mobile,
    required this.religion,
    required this.category,
    required this.caste,
    required this.gotra,
    required this.village,
    required this.district,
    required this.state,
    required this.occupation,
    required this.brothers,
    required this.sisters,
    required this.familyDetails,
    required this.requirements,
    required this.email,
    required this.verificationStatus,
    required this.isVerified,
    this.rashi = '',
    this.nakshatra = '',
    this.manglik = 'unknown',
    this.credits = 0,
    this.photoUrls = const [],
    this.heightCm,
    this.maritalStatus = '',
    this.education = '',
    this.motherTongue = '',
    this.incomeBand = '',
    this.photosPrivate = false,
    this.blockedUids = const [],
    this.boostedUntil,
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
      caste: data['caste'] ?? '',
      gotra: data['gotra'] ?? '',
      village: data['village'] ?? '--',
      district: data['district'] ?? '--',
      state: data['state'] ?? '--',
      occupation: data['occupation'] ?? 'N/A',
      brothers: data['brothers'] ?? '',
      sisters: data['sisters'] ?? '',
      familyDetails: data['familyDetails'] ?? 'N/A',
      requirements: data['requirements'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
      verificationStatus: data['verificationStatus'] ?? 'none',
      isVerified: data['isVerified'] ?? false,
      rashi: data['rashi'] ?? '',
      nakshatra: data['nakshatra'] ?? '',
      manglik: data['manglik'] ?? 'unknown',
      credits: (data['credits'] is int) ? data['credits'] as int : (data['credits'] as num?)?.toInt() ?? 0,
      photoUrls: List<String>.from(data['photoUrls'] ?? const []),
      heightCm: (data['heightCm'] as num?)?.toInt(),
      maritalStatus: data['maritalStatus'] ?? '',
      education: data['education'] ?? '',
      motherTongue: data['motherTongue'] ?? '',
      incomeBand: data['incomeBand'] ?? '',
      photosPrivate: data['photosPrivate'] == true,
      blockedUids: List<String>.from(data['blockedUids'] ?? const []),
      boostedUntil: (data['boostedUntil'] as Timestamp?)?.toDate(),
    );
  }

  bool get isBoosted => boostedUntil != null && boostedUntil!.isAfter(DateTime.now());

  String? get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  bool get hasKundaliDetails => rashi.isNotEmpty && nakshatra.isNotEmpty;

  String get location =>
      [village, district, state].where((s) => s.isNotEmpty && s != '--').join(', ');

  bool get isFemale => gender.toLowerCase().contains('female') || gender.toLowerCase().contains('stri');
  bool get isMale   => gender.toLowerCase().contains('male') || gender.toLowerCase().contains('purush');

  /// Parses `dob` (stored as dd/mm/yyyy, see BasicDetailsScreen's date
  /// picker) into a whole number of years. Null if unparseable/unset -
  /// callers should treat that as "unknown," not zero.
  int? get age {
    final parts = dob.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final birth = DateTime(year, month, day);
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
    return years;
  }

  /// "5'6"" from heightCm, or empty if not set.
  String get heightDisplay {
    if (heightCm == null) return '';
    final totalInches = (heightCm! / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }
}
