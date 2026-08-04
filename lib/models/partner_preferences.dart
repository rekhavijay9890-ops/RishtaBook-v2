/// What a user is looking for in a match - stored as a `preferences` map
/// on their own `users/{uid}` doc (self-write, same rules as the rest of
/// the profile). Empty lists mean "no restriction / any" for that
/// criterion - MatchmakingService treats an empty list as an automatic
/// pass rather than a filter that excludes everyone.
class PartnerPreferences {
  final int ageMin;
  final int ageMax;
  final int heightMinCm;
  final int heightMaxCm;
  final List<String> religions;
  final List<String> maritalStatuses;
  final List<String> educations;
  final List<String> states;
  final String manglik; // 'any' | 'no' | 'yes'

  const PartnerPreferences({
    required this.ageMin,
    required this.ageMax,
    required this.heightMinCm,
    required this.heightMaxCm,
    required this.religions,
    required this.maritalStatuses,
    required this.educations,
    required this.states,
    required this.manglik,
  });

  factory PartnerPreferences.defaults() => const PartnerPreferences(
        ageMin: 21,
        ageMax: 45,
        heightMinCm: 140,
        heightMaxCm: 200,
        religions: [],
        maritalStatuses: [],
        educations: [],
        states: [],
        manglik: 'any',
      );

  factory PartnerPreferences.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return PartnerPreferences.defaults();
    final d = PartnerPreferences.defaults();
    return PartnerPreferences(
      ageMin: (data['ageMin'] as num?)?.toInt() ?? d.ageMin,
      ageMax: (data['ageMax'] as num?)?.toInt() ?? d.ageMax,
      heightMinCm: (data['heightMinCm'] as num?)?.toInt() ?? d.heightMinCm,
      heightMaxCm: (data['heightMaxCm'] as num?)?.toInt() ?? d.heightMaxCm,
      religions: List<String>.from(data['religions'] ?? const []),
      maritalStatuses: List<String>.from(data['maritalStatuses'] ?? const []),
      educations: List<String>.from(data['educations'] ?? const []),
      states: List<String>.from(data['states'] ?? const []),
      manglik: data['manglik'] ?? d.manglik,
    );
  }

  Map<String, dynamic> toMap() => {
        'ageMin': ageMin,
        'ageMax': ageMax,
        'heightMinCm': heightMinCm,
        'heightMaxCm': heightMaxCm,
        'religions': religions,
        'maritalStatuses': maritalStatuses,
        'educations': educations,
        'states': states,
        'manglik': manglik,
      };

  PartnerPreferences copyWith({
    int? ageMin,
    int? ageMax,
    int? heightMinCm,
    int? heightMaxCm,
    List<String>? religions,
    List<String>? maritalStatuses,
    List<String>? educations,
    List<String>? states,
    String? manglik,
  }) {
    return PartnerPreferences(
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      heightMinCm: heightMinCm ?? this.heightMinCm,
      heightMaxCm: heightMaxCm ?? this.heightMaxCm,
      religions: religions ?? this.religions,
      maritalStatuses: maritalStatuses ?? this.maritalStatuses,
      educations: educations ?? this.educations,
      states: states ?? this.states,
      manglik: manglik ?? this.manglik,
    );
  }
}
