import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/features/auth/domain/models/user_profile.dart';
import 'package:lingoocall/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class PublicProfileScreen extends StatefulWidget {
  final AppController controller;
  final UserProfile userProfile;

  const PublicProfileScreen({
    super.key,
    required this.controller,
    required this.userProfile,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late UserProfile profile;

  @override
  void initState() {
    super.initState();
    profile = widget.userProfile;
  }

  bool _canSeePhoneNumber() {
    if (profile.phonePrivacy == PhoneNumberPrivacy.everyone) return true;
    if (profile.phonePrivacy == PhoneNumberPrivacy.mutual && profile.isFollowing) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.username.isNotEmpty ? profile.username : profile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الجزء العلوي (الصورة الشخصية والإحصائيات)
            Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.3),
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? NetworkImage(profile.avatarUrl)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('المكالمات', '128'),
                      _buildStatColumn('المتابِعون', '${profile.followersCount}'),
                      _buildStatColumn('المتابَعون', '${profile.followingCount}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. الاسم، اليوزر، والبيو (Bio)
            Text(
              profile.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (profile.username.isNotEmpty)
              Text(
                profile.username,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              profile.bio.isNotEmpty ? profile.bio : 'لا يوجد وصف محدد',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),

            // 3. عرض رقم الهاتف فقط إذا سمحت إعدادات الخصوصية
            if (_canSeePhoneNumber()) ...[
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    profile.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 16),

            // 4. أزرار المتابعة والمراسلة المباشرة
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: profile.isFollowing
                          ? (isDark ? Colors.white12 : Colors.grey[300])
                          : AppColors.primary,
                      foregroundColor: profile.isFollowing
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        profile.isFollowing = !profile.isFollowing;
                        if (profile.isFollowing) {
                          profile.followersCount++;
                        } else {
                          profile.followersCount--;
                        }
                      });
                    },
                    child: Text(
                      profile.isFollowing ? 'تتابعُه' : 'متابعة',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text(
                      'مراسلة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final contact = ContactItem(
                        id: profile.id,
                        name: profile.name,
                        phone: profile.phone,
                        nativeLanguage: profile.nativeLanguage,
                        flag: profile.nativeFlag,
                        isRegistered: true,
                        isOnline: true,
                      );
                      widget.controller.openChat(contact);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            controller: widget.controller,
                            contact: contact,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}