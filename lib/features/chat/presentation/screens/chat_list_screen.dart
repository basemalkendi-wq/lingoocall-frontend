import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/constants/app_constants.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/localization/app_localizations.dart';
import 'package:lingoocall/features/auth/domain/models/user_profile.dart';
import 'package:lingoocall/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';
import 'package:lingoocall/features/contacts/presentation/screens/public_profile_screen.dart';

class ChatListScreen extends StatefulWidget {
  final AppController controller;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ChatListScreen({
    super.key,
    required this.controller,
    required this.scaffoldKey,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- نافذة عائمة لمراسلة رقم غير محفوظ مباشرة ---
  void _showDirectChatDialog() {
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_chat_unread_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('محادثة رقم غير محفوظ', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل رقم الهاتف المباشر مع مفتاح الدولة لبدء المحادثة فوراً:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '+967 770000000',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context);
                _openChatWithNumber(phone);
              }
            },
            child: const Text(
              'بدء المحادثة',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- فتح شاشة المحادثة فقط إذا كان الهدف مستخدماً مسجلاً فعلياً ---
  Future<void> _openChatWithNumber(String phone) async {
    final resolvedContact = await widget.controller.resolveRegisteredChatTarget(
      phone,
    );
    if (resolvedContact == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن بدء محادثة مع هذا الرقم لأنه غير مسجل في النظام.',
          ),
        ),
      );
      return;
    }

    widget.controller.openChat(resolvedContact);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          controller: widget.controller,
          contact: resolvedContact,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context);

    // قائمة المحادثات الحقيقية من الـ controller
    final List<ContactItem> activeConversations = widget.controller.activeChats;

    // تصفية القائمة بناءً على البحث بالاسم أو برقم الهاتف
    final filteredConversations = activeConversations.where((chat) {
      final query = _searchQuery.toLowerCase().trim();
      return chat.name.toLowerCase().contains(query) ||
          chat.phone.toLowerCase().contains(query);
    }).toList();

    // فحص ما إذا كان المدخل بداخل البحث عبارة عن رقم هاتف غير محفوظ
    final bool isQueryPhoneNumber =
        _isSearching &&
        _searchQuery.trim().isNotEmpty &&
        RegExp(r'^[+0-9\s-]+$').hasMatch(_searchQuery.trim());

    // فحص ما إذا كان المدخل بداخل البحث عبارة عن اسم مستخدم (@username أو نص اسم)
    final bool isQueryUsername =
        _isSearching &&
        _searchQuery.trim().isNotEmpty &&
        (_searchQuery.trim().startsWith('@') ||
            (_searchQuery.trim().length > 2 &&
                !RegExp(r'^[+0-9\s-]+$').hasMatch(_searchQuery.trim())));

    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'بحث باسم، @يوزر، أو رقم هاتف...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text(
                AppConstants.appName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : AppColors.darkBackground,
            ),
            onPressed: () {
              widget.controller.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط معلومات الترجمة التلقائية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tr.translate('autoTranslatingBanner')} ${widget.controller.currentUser.nativeLanguage} ${widget.controller.currentUser.nativeFlag}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isQueryUsername || isQueryPhoneNumber)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(
                      Icons.block_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'لا يمكن بدء المحادثة إلا مع مستخدم مسجل ومعتمد في LingooCall.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

          // عرض قائمة المحادثات النشطة أو الواجهة الفارغة
          Expanded(
            child:
                filteredConversations.isEmpty &&
                    !isQueryPhoneNumber &&
                    !isQueryUsername
                ? _buildEmptyState(context, tr, isDark)
                : ListView.separated(
                    itemCount: filteredConversations.length,
                    separatorBuilder: (ctx, idx) => Divider(
                      height: 1,
                      indent: 76,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredConversations[index];
                      final msgs = widget.controller.getMessagesForContact(
                        item.id,
                      );
                      final lastMsg = msgs.isNotEmpty ? msgs.last : null;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.accent.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (item.isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBackground
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '12:45 PM',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastMsg != null
                                    ? lastMsg.originalText
                                    : tr.translate('tapToStartChat'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'AI ${item.flag}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      lastMsg != null
                                          ? lastMsg.translatedText
                                          : tr.translate(
                                              'realTimeAiVoiceMessaging',
                                            ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          widget.controller.openChat(item);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                controller: widget.controller,
                                contact: item,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDirectChatDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(
          tr.translate('newCallChatFab'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ودجت الواجهة الفارغة متعددة اللغات الديناميكية
  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations tr,
    bool isDark,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr.translate('noChatsTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr.translate('noChatsSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showDirectChatDialog,
              icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
              label: Text(
                tr.translate('startNewChatButton'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
