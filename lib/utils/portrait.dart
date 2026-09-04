import '../models/user_profile.dart';

/// Real uploaded photo when present; otherwise a stable generated portrait
/// so cards never look like empty initials circles.
class Portrait {
  Portrait._();

  static String urlFor(UserProfile p) {
    final existing = p.primaryPhotoUrl;
    if (existing != null && existing.isNotEmpty) return existing;
    return generated(p.uid, female: p.isFemale);
  }

  static String generated(String seed, {required bool female}) {
    final style = female ? 'lorelei' : 'adventurer';
    return 'https://api.dicebear.com/9.x/$style/png?seed=${Uri.encodeComponent(seed)}&size=256&backgroundColor=b6a3e8,f1e9fb,c4b5e8';
  }
}
