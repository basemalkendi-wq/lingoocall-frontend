import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';

class UserProfileScreen extends StatefulWidget {
  final AppController controller;

  const UserProfileScreen({super.key, required this.controller});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _bioController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.controller.currentUser.bio);
    _nameController = TextEditingController(text: widget.controller.currentUser.name);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.controller.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.username.isNotEmpty ? user.username : user.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded),
            onPressed: () async {
              setState(() {
                if (_isEditing) {
                  widget.controller.updateProfile(
                    name: _nameController.text.trim(),
                    bio: _bioController.text.trim(),
                  );
                }
                _isEditing = !_isEditing;
              });

              if (!_isEditing && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: user.avatarUrl.isEmpty
                            ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('جاري فتح المعرض لتغيير الصورة الشخصية...')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('المنشورات', '0'),
                        _buildStatColumn('المتابِعون', '${user.followersCount}'),
                        _buildStatColumn('المتابَعون', '${user.followingCount}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isEditing
                      ? TextField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                        )
                      : Text(
                          user.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    user.username.isNotEmpty ? user.username : '@${user.email.split('@')[0]}',
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _isEditing
                      ? TextField(
                          controller: _bioController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'السيرة الذاتية (Bio)...'),
                        )
                      : Text(
                          user.bio.isNotEmpty ? user.bio : 'لم يبدأ رحلته بعد.. اضغط تعديل لإضافة السيرة الذاتية ✨',
                          style: TextStyle(
                            fontSize: 14,
                            color: user.bio.isNotEmpty ? (isDark ? Colors.grey[200] : Colors.grey[800]) : Colors.grey,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grid_on_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد منشورات حتى الآن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'عندما تقوم بمشاركة منشوراتك أو تحديثاتك، ستظهر هنا.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
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
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}