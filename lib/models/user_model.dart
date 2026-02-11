class User {
  final String id;
  final String name;
  final String avatarUrl;
  final String nationality;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.nationality = 'KR 🇰🇷', // Default for clean migration
  });
}
