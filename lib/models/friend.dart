class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.sport,
    required this.gamesPlayed,
    this.avatarInitials = '',
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String username;
  final String sport;
  final int gamesPlayed;
  final String avatarInitials;
  final String? phone;
  final String? avatarUrl;
}
