enum PhoneNumberPrivacy {
  everyone, // الجميع
  mutual,   // المتابعون المتبادلون
  nobody,   // لا أحد (إخفاء تام)
}

class UserProfile {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String nativeLanguage;
  final String nativeFlag;
  final String targetLanguage;
  final String targetFlag;
  final String avatarUrl;
  final String bio;
  int followersCount;
  int followingCount;
  bool isFollowing;
  PhoneNumberPrivacy phonePrivacy;

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.nativeLanguage,
    required this.nativeFlag,
    required this.targetLanguage,
    required this.targetFlag,
    required this.avatarUrl,
    this.username = '',
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.phonePrivacy = PhoneNumberPrivacy.nobody,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    String? nativeLanguage,
    String? nativeFlag,
    String? targetLanguage,
    String? targetFlag,
    String? avatarUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    PhoneNumberPrivacy? phonePrivacy,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      nativeFlag: nativeFlag ?? this.nativeFlag,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      targetFlag: targetFlag ?? this.targetFlag,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      phonePrivacy: phonePrivacy ?? this.phonePrivacy,
    );
  }
}