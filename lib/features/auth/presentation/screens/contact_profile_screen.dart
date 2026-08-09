import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/features/call/presentation/screens/video_call_screen.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class ContactProfileScreen extends StatefulWidget {
  final AppController controller;
  final ContactItem contact;

  const ContactProfileScreen({
    super.key,
    required this.controller,
    required this.contact,
  });

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  bool _isChatLocked = false;
  bool _isMuted = false;
  bool _isFavorite = false;
  String _disappearingTime = 'إيقاف';
  bool _isAdvancedPrivacyOn = false;

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0B141B) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF111B21) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. الشريط العلوي مع الصورة واسم جهة الاتصال
          SliverAppBar(
            pinned: true,
            backgroundColor: cardColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'share') _showToast('مشاركة جهة الاتصال');
                  if (val == 'edit') _showToast('تعديل جهة الاتصال');
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'share', child: Text('مشاركة')),
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                ],
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // 2. كارت معلومات الملف الشخصي والأزرار السريعة
                Container(
                  color: cardColor,
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      // صورة البروفايل أو الحرف الأول
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF3C3122),
                        child: Text(
                          widget.contact.name.isNotEmpty
                              ? widget.contact.name.substring(0, 1).toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE5AA42),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // الاسم
                      Text(
                        widget.contact.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // الرقم
                      Text(
                        widget.contact.phone.isNotEmpty
                            ? widget.contact.phone
                            : '+967 733 998 181',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // الأزرار السريعة الثلاثة (مكالمة صوتية، فيديو، بحث)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.phone_outlined,
                            label: 'مكالمة صوتية',
                            onTap: () {
                              widget.controller.startCall(widget.contact, isVideo: false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoCallScreen(controller: widget.controller),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 24),
                          _buildQuickActionButton(
                            icon: Icons.videocam_outlined,
                            label: 'فيديو',
                            onTap: () {
                              widget.controller.startCall(widget.contact, isVideo: true);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoCallScreen(controller: widget.controller),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 24),
                          _buildQuickActionButton(
                            icon: Icons.search_rounded,
                            label: 'بحث',
                            onTap: () {
                              Navigator.pop(context, 'search');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. كارت الحالة والتخصيص
                Container(
                  color: cardColor,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.style_outlined, color: Colors.grey),
                        title: const Text('إضافة إلى القوائم'),
                        onTap: () => _showToast('إضافة إلى القوائم'),
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey),
                        title: const Text('اشرف'),
                        subtitle: const Text('5 الف رصيد... قراءة المزيد'),
                        onTap: () => _showToast('عرض التفاصيل الكاملة'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 4. قسم الوسائط والروابط والمستندات المتبادلة
                Container(
                  color: cardColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'وسائط وروابط ومستندات',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '421',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                ),
                                Icon(Icons.chevron_left_rounded, color: Colors.grey[500]),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: 5,
                          itemBuilder: (ctx, idx) {
                            return Container(
                              width: 90,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://picsum.photos/300?random=${idx + 10}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 5. قسم الإعدادات والتخزين والخصوصية
                Container(
                  color: cardColor,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.folder_open_outlined, color: Colors.grey),
                        title: const Text('إدارة مساحة التخزين'),
                        subtitle: const Text('78,0 م.ب'),
                        onTap: () => _showToast('فتح إدارة التخزين لهذا الحساب'),
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: Icon(
                          _isMuted ? Icons.notifications_off_outlined : Icons.notifications_none_outlined,
                          color: Colors.grey,
                        ),
                        title: const Text('الإشعارات'),
                        subtitle: Text(_isMuted ? 'مكتومة' : 'مفعلة'),
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          _showToast(_isMuted ? 'تم كتم التنبيهات' : 'تم تفعيل التنبيهات');
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.photo_outlined, color: Colors.grey),
                        title: const Text('عرض الوسائط'),
                        onTap: () => _showToast('إعدادات عرض الوسائط في المعرض'),
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                        title: const Text('التشفير'),
                        subtitle: const Text('الرسائل والمكالمات مشفرة تماماً بين الطرفين. اضغط للتحقق.'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('رمز الأمان للتشفير'),
                              content: const Text('الرسائل والمكالمات في هذه المحادثة مشفرة بنهاية لنهاية (End-to-End Encrypted).'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('تم'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.timer_outlined, color: Colors.grey),
                        title: const Text('الرسائل ذاتية الاختفاء'),
                        subtitle: Text(_disappearingTime),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: const Text('الرسائل ذاتية الاختفاء'),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () {
                                    setState(() => _disappearingTime = '24 ساعة');
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('24 ساعة'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () {
                                    setState(() => _disappearingTime = '7 أيام');
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('7 أيام'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () {
                                    setState(() => _disappearingTime = 'إيقاف');
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('إيقاف'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      // زر قفل الدردشة المحدث
                      SwitchListTile(
                        secondary: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                        title: const Text('قفل الدردشة'),
                        subtitle: const Text('تمكّن من قفل هذه الدردشة وإخفائها على هذا الجهاز.'),
                        value: _isChatLocked,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _isChatLocked = val);
                          _showToast(val ? 'تم قفل الدردشة بالبصمة/الرمز' : 'تم إلغاء قفل الدردشة');
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.security_outlined, color: Colors.grey),
                        title: const Text('الخصوصية المتقدمة للدردشة'),
                        subtitle: Text(_isAdvancedPrivacyOn ? 'مفعلة' : 'إيقاف التشغيل'),
                        onTap: () {
                          setState(() => _isAdvancedPrivacyOn = !_isAdvancedPrivacyOn);
                          _showToast(_isAdvancedPrivacyOn ? 'تم تفعيل الخصوصية المتقدمة' : 'تم الإيقاف');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 6. قسم المجموعات المشتركة
                Container(
                  color: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'مجموعة مشتركة واحدة',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                          child: const Icon(Icons.group_add_outlined, color: Colors.white),
                        ),
                        title: Text('إنشاء مجموعة مع ${widget.contact.name}'),
                        onTap: () => _showToast('إنشاء مجموعة مشتركة جديدة'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                          child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
                        ),
                        title: const Text('الإضافة إلى المجموعات'),
                        subtitle: const Text('إضافة جهة الاتصال هذه إلى المجموعات التي انضممت إليها.'),
                        onTap: () => _showToast('إضافة لجهة اتصال في مجموعة أخرى'),
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1F2937),
                          child: Text(
                            'VZ',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: const Text('فيزار | رجالي'),
                        subtitle: const Text('ام، خاله، Max, AbdAlkarim/you'),
                        onTap: () => _showToast('فتح مجموعة فيزار | رجالي'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 7. قسم الأفعال والإجراءات المباشرة (مفضلة، مسح، حظر، إبلاغ)
                Container(
                  color: cardColor,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.red : Colors.grey,
                        ),
                        title: Text(_isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'),
                        onTap: () {
                          setState(() => _isFavorite = !_isFavorite);
                          _showToast(_isFavorite ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة');
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey),
                        title: const Text('مسح محتوى الدردشة'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('مسح محتوى الدردشة؟'),
                              content: const Text('سيتم مسح جميع الرسائل المتبادلة محلياً.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    widget.controller.getMessagesForContact(widget.contact.id).clear();
                                    Navigator.pop(ctx);
                                    _showToast('تم مسح المحتوى بالكامل');
                                  },
                                  child: const Text('مسح', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.block_rounded, color: Colors.red),
                        title: Text(
                          'حظر ${widget.contact.name}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('حظر ${widget.contact.name}؟'),
                              content: const Text('لن تتمكن جهة الاتصال هذه من الاتصال بك أو إرسال الرسائل.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                    _showToast('تم الحظر بنجاح');
                                  },
                                  child: const Text('حظر', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: const Icon(Icons.thumb_down_alt_outlined, color: Colors.red),
                        title: Text(
                          'الإبلاغ عن ${widget.contact.name}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          _showToast('تم إرسال البلاغ إلى الفريق التقني');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}