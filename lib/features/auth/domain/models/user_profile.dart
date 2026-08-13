enum PhoneNumberPrivacy {
  everyone, // الجميع
  mutual,   // المتابعون المتبادلون
  nobody,   // لا أحد (إخفاء تام)
}

class UserProfile {
  final String id;
  String name;
  String username;
  String email;
  final String phone;
  String nativeLanguage;
  String nativeFlag;
  String targetLanguage;
  String targetFlag;
  String avatarUrl;
  String bio;
  int followersCount;
  int followingCount;
  bool isFollowing;
  PhoneNumberPrivacy phonePrivacy;

  UserProfile({
    required this.id,
    required this.name,
    this.email = '',
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

  // تحويل البيانات إلى خريطة (JSON) لحفظها في قاعدة البيانات أو التخزين المحلي
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'nativeLanguage': nativeLanguage,
      'nativeFlag': nativeFlag,
      'targetLanguage': targetLanguage,
      'targetFlag': targetFlag,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isFollowing': isFollowing,
      'phonePrivacy': phonePrivacy.index,
    };
  }

  // بناء كائن UserProfile من البيانات القادمة من السيرفر أو قاعدة البيانات (JSON)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawPrivacy = json['phonePrivacy'];
    final phonePrivacyIndex = rawPrivacy is int
        ? rawPrivacy
        : int.tryParse(rawPrivacy?.toString() ?? '') ?? PhoneNumberPrivacy.nobody.index;

    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      nativeLanguage: json['nativeLanguage']?.toString() ?? 'Arabic',
      nativeFlag: json['nativeFlag']?.toString() ?? '🇾🇪',
      targetLanguage: json['targetLanguage']?.toString() ?? 'Turkish',
      targetFlag: json['targetFlag']?.toString() ?? '🇹🇷',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
      phonePrivacy: PhoneNumberPrivacy.values[
        phonePrivacyIndex.clamp(0, PhoneNumberPrivacy.values.length - 1).toInt()
      ],
    );
  }

  // إنشاء نسخة معدلة من الكائن
  UserProfile copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
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
      email: email ?? this.email,
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