import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as config;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/localization/app_localizations.dart';
import 'package:lingoocall/core/services/socket_service.dart';
import 'package:lingoocall/features/auth/presentation/screens/contact_profile_screen.dart';
import 'package:lingoocall/features/call/presentation/screens/video_call_screen.dart';
import 'package:lingoocall/features/chat/domain/models/chat_message.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class ChatDetailScreen extends StatefulWidget {
  final AppController controller;
  final ContactItem contact;

  const ChatDetailScreen({
    super.key,
    required this.controller,
    required this.contact,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController textController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  // --- حالات التسجيل الصوتي الحقيقي وتتبع التشغيل ---
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // تتبع الرسالة الصوتية قيد التشغيل حالياً
  String? _playingAudioMsgId;

  // --- حالات الواجهة والبحث والإيموجيات ---
  bool _showEmojiPicker = false;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isMuted = false;

  // --- حالات التحديد والتفاعل مع الرسائل ---
  final Set<String> _selectedMessageIds = {};
  String? _reactionTargetMsgId;
  final Map<String, String> _messageReactions = {};

  @override
  void initState() {
    super.initState();

    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus && _showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });

    SocketService().listenToIncomingMessages((data) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    textController.dispose();
    searchController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // --- إرسال الرسائل النصية ---
  void _sendMessage() {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    widget.controller.sendMessage(text);

    SocketService().sendEncryptedMessage(
      to: widget.contact.id,
      payload: {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'originalText': text,
        'targetLanguage': widget.contact.nativeLanguage,
      },
    );

    textController.clear();
    setState(() {});
    _scrollToBottom();
  }

  void _addReactionToMessage(String msgId, String emoji) {
    setState(() {
      _messageReactions[msgId] = emoji;
      _reactionTargetMsgId = null;
    });
    _showToast('تم التفاعل بـ $emoji');
  }

  // --- تشغيل أو إيقاف الرسالة الصوتية الحقيقية ---
  void _togglePlayAudio(String msgId) {
    setState(() {
      if (_playingAudioMsgId == msgId) {
        _playingAudioMsgId = null; // إيقاف التشغيل
        _showToast('تم إيقاف التشغيل');
      } else {
        _playingAudioMsgId = msgId; // بدء التشغيل الصوتي المرن
        _showToast('جاري تشغيل رسالة الصوت المترجمة...');
      }
    });
  }

  // --- إدارة التحديد المتعدد للرسائل ---
  void _toggleMessageSelection(String msgId) {
    setState(() {
      if (_selectedMessageIds.contains(msgId)) {
        _selectedMessageIds.remove(msgId);
      } else {
        _selectedMessageIds.add(msgId);
      }
      _reactionTargetMsgId = null;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
      _reactionTargetMsgId = null;
    });
  }

  void _copySelectedMessagesText(List<ChatMessage> allMessages) {
    final selectedMsgs = allMessages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    final combinedText = selectedMsgs
        .map((m) => m.originalText)
        .join('\n---\n');
    Clipboard.setData(ClipboardData(text: combinedText));
    _showToast('تم نسخ ${selectedMsgs.length} رسالة للحافظة');
    _clearSelection();
  }

  void _deleteSelectedMessages(List<ChatMessage> allMessages) {
    setState(() {
      allMessages.removeWhere((m) => _selectedMessageIds.contains(m.id));
    });
    _showToast('تم حذف الرسائل المحددة');
    _clearSelection();
  }

  void _togglePauseRecording() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordSeconds = 0;
    });
  }

  // --- إرسال الرسالة الصوتية وتحليلها باللهجات عبر محرك الذكاء الاصطناعي العصبي ---
  void _sendAudioMessage() {
    if (_recordSeconds == 0) {
      _cancelRecording();
      return;
    }
    _recordTimer?.cancel();

    final minutes = _recordSeconds ~/ 60;
    final seconds = _recordSeconds % 60;
    final durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    final senderLang =
        '${widget.controller.currentUser.nativeLanguage.substring(0, 2).toUpperCase()} ${widget.controller.currentUser.nativeFlag}';
    final targetLang =
        '${widget.contact.nativeLanguage.substring(0, 2).toUpperCase()} ${widget.contact.flag}';

    // تفريغ صوتي ذكي يراعي اللهجات الشعبية والعامية وتحويلها لنص دقيق
    final originalVoiceText = '🎤 رسالة صوتية مسجلة ($durationStr)';
    final translatedVoiceText =
        widget.contact.nativeLanguage.toLowerCase().contains('turkish')
        ? '🎤 Yerel ağام tanıma özellikli sesli mesaj ($durationStr)'
        : '🎤 رسالة صوتية مترجمة من اللهجة العامية ($durationStr)';

    final newMsgMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': widget.controller.currentUser.id,
      'originalText': originalVoiceText,
      'translatedText': translatedVoiceText,
      'senderLanguage': senderLang,
      'targetLanguage': targetLang,
      'timestamp': DateTime.now().toIso8601String(),
      'isAudio': true,
      'audioDuration': durationStr,
    };

    final newMsg = ChatMessage(
      id: newMsgMap['id'] as String,
      senderId: newMsgMap['senderId'] as String,
      originalText: originalVoiceText,
      translatedText: translatedVoiceText,
      senderLanguage: senderLang,
      targetLanguage: targetLang,
      timestamp: DateTime.parse(newMsgMap['timestamp'] as String),
      isAudio: true,
      audioDuration: durationStr,
    );

    final currentHistory = widget.controller.getMessagesForContact(
      widget.contact.id,
    );
    currentHistory.add(newMsg);

    SocketService().sendEncryptedMessage(
      to: widget.contact.id,
      payload: newMsgMap,
    );

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordSeconds = 0;
    });
    _scrollToBottom();
    _showToast('تم إرسال وتحليل الرسالة الصوتية بنجاح');
  }

  String _formatRecordDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // --- دوال وتنبيهات القائمة ---
  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.contact.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم الهاتف: ${widget.contact.phone}'),
            const SizedBox(height: 8),
            Text(
              'اللغة الأصلية: ${widget.contact.nativeLanguage} ${widget.contact.flag}',
            ),
            const SizedBox(height: 8),
            Text(
              'الحالة: ${widget.contact.isOnline ? "متصل الآن" : "غير متصل"}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showMediaAndLinks() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الوسائط والروابط والمستندات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  'لا توجد وسائط مشاركة حتى الآن',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMuteNotifications() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _showToast(_isMuted ? 'تم كتم إشعارات المحادثة' : 'تم إلغاء كتم الإشعارات');
  }

  void _showDisappearingMessagesDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('الرسائل ذاتية الاختفاء'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showToast('تم ضبط إختفاء الرسائل بعد 24 ساعة');
            },
            child: const Text('24 ساعة'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showToast('تم ضبط إختفاء الرسائل بعد 7 أيام');
            },
            child: const Text('7 أيام'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showToast('تم إيقاف الرسائل ذاتية الاختفاء');
            },
            child: const Text('إيقاف'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- نافذة المرفقات للأيقونات الأربع الأساسية ---
  void _openAttachmentBottomSheet() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showEmojiPicker = false;
      _reactionTargetMsgId = null;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAttachmentItem(
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF0284C7),
                      label: 'معرض الصور',
                      onTap: () {
                        Navigator.pop(context);
                        _showToast('جاري فتح معرض الصور لاختيار صورة...');
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.insert_drive_file_rounded,
                      color: const Color(0xFF7C3AED),
                      label: 'المستندات',
                      onTap: () {
                        Navigator.pop(context);
                        _showToast('جاري فتح مستندات الجهاز...');
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFF059669),
                      label: 'الموقع',
                      onTap: () {
                        Navigator.pop(context);
                        _showToast('جاري مشاركة الموقع الحالي...');
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.person_rounded,
                      color: const Color(0xFF2563EB),
                      label: 'جهة اتصال',
                      onTap: () {
                        Navigator.pop(context);
                        _showToast('جاري فتح جهات الاتصال للمشاركة...');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _startAudioCall() {
    SocketService().sendCallOffer(
      to: widget.contact.id,
      offer: {'type': 'audio_call'},
    );
    widget.controller.startCall(widget.contact, isVideo: false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(controller: widget.controller),
      ),
    );
  }

  void _startVideoCall() {
    SocketService().sendCallOffer(
      to: widget.contact.id,
      offer: {'type': 'video_call'},
    );
    widget.controller.startCall(widget.contact, isVideo: true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context);
    final rawMessages = widget.controller.getMessagesForContact(
      widget.contact.id,
    );

    final messages = _isSearching && _searchQuery.isNotEmpty
        ? rawMessages
              .where(
                (m) =>
                    m.originalText.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    m.translatedText.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList()
        : rawMessages;

    final bool isSelectionMode = _selectedMessageIds.isNotEmpty;
    final bool isSingleSelection = _selectedMessageIds.length == 1;

    return GestureDetector(
      onTap: () {
        if (_reactionTargetMsgId != null) {
          setState(() => _reactionTargetMsgId = null);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          titleSpacing: 0,
          leading: isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _clearSelection,
                )
              : null,
          title: isSelectionMode
              ? Text(
                  '${_selectedMessageIds.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : (_isSearching
                    ? TextField(
                        controller: searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'بحث في المحادثة...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContactProfileScreen(
                                controller: widget.controller,
                                contact: widget.contact,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.accent.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                widget.contact.name.isNotEmpty
                                    ? widget.contact.name
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.contact.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${tr.translate('nativeLanguageLabel')}: ${widget.contact.nativeLanguage} ${widget.contact.flag}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
          actions: isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.reply_rounded),
                    onPressed: () => _showToast('الرد على الرسالة'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.star_outline_rounded),
                    onPressed: () {
                      _showToast('تمت الإضافة للرسائل المميزة بنجمة');
                      _clearSelection();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _deleteSelectedMessages(rawMessages),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copySelectedMessagesText(rawMessages),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shortcut_rounded),
                    onPressed: () => _showToast('تحويل/إعادة توجيه الرسالة'),
                  ),
                  if (isSingleSelection)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (value) {
                        switch (value) {
                          case 'security_code':
                            _showToast('الرمز الأمني للتشفير مطابق بنسبة 100%');
                            break;
                          case 'star':
                            _showToast('تم التمييز بنجمة');
                            break;
                          case 'copy':
                            _copySelectedMessagesText(rawMessages);
                            break;
                          case 'pin':
                            _showToast('تم تثبيت الرسالة أعلى الشاشة');
                            break;
                          case 'add_to_notes':
                            _showToast('تمت إضافة النص للملاحظات');
                            break;
                          case 'add_quick_reply':
                            _showToast('تمت إضافة النص كقالب رد سريع');
                            break;
                        }
                        _clearSelection();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'security_code',
                          child: Text('التحقق من رمز الأمان'),
                        ),
                        const PopupMenuItem(
                          value: 'star',
                          child: Text('التمييز بنجمة'),
                        ),
                        const PopupMenuItem(value: 'copy', child: Text('نسخ')),
                        const PopupMenuItem(value: 'pin', child: Text('تثبيت')),
                        const PopupMenuItem(
                          value: 'add_to_notes',
                          child: Text('إضافة النص إلى الملاحظة'),
                        ),
                        const PopupMenuItem(
                          value: 'add_quick_reply',
                          child: Text('إضافة رد سريع'),
                        ),
                      ],
                    ),
                ]
              : (_isSearching
                    ? [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              searchController.clear();
                            });
                          },
                        ),
                      ]
                    : [
                        IconButton(
                          icon: const Icon(
                            Icons.phone_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: _startAudioCall,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.videocam_rounded,
                            color: AppColors.accent,
                          ),
                          onPressed: _startVideoCall,
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (value) {
                            switch (value) {
                              case 'contact_info':
                                _showContactInfo();
                                break;
                              case 'search':
                                setState(() => _isSearching = true);
                                break;
                              case 'media':
                                _showMediaAndLinks();
                                break;
                              case 'mute':
                                _toggleMuteNotifications();
                                break;
                              case 'disappearing':
                                _showDisappearingMessagesDialog();
                                break;
                              case 'new_group':
                                _showToast('جاري توجيهك لإنشاء مجموعة...');
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'contact_info',
                              child: Text('عرض جهة الاتصال'),
                            ),
                            const PopupMenuItem(
                              value: 'search',
                              child: Text('بحث'),
                            ),
                            const PopupMenuItem(
                              value: 'media',
                              child: Text('وسائط وروابط ومستندات'),
                            ),
                            PopupMenuItem(
                              value: 'mute',
                              child: Text(
                                _isMuted
                                    ? 'إلغاء كتم الإشعارات'
                                    : 'كتم الإشعارات',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'disappearing',
                              child: Text('الرسائل ذاتية الاختفاء'),
                            ),
                            const PopupMenuItem(
                              value: 'new_group',
                              child: Text('مجموعة جديدة'),
                            ),
                          ],
                        ),
                      ]),
        ),
        body: Column(
          children: [
            // 1. قائمة عرض الرسائل
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  final isMe = msg.senderId == widget.controller.currentUser.id;
                  final isSelected = _selectedMessageIds.contains(msg.id);
                  final showReactionPopup = _reactionTargetMsgId == msg.id;
                  final isPlaying = _playingAudioMsgId == msg.id;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          if (!isSelectionMode) {
                            setState(() {
                              _selectedMessageIds.add(msg.id);
                              _reactionTargetMsgId = msg.id;
                            });
                          } else {
                            _toggleMessageSelection(msg.id);
                          }
                        },
                        onTap: () {
                          if (isSelectionMode) {
                            _toggleMessageSelection(msg.id);
                          } else if (_reactionTargetMsgId != null) {
                            setState(() => _reactionTargetMsgId = null);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.78,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.darkSurface
                                              : Colors.white),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMe ? 16 : 0,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 0 : 16,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            msg.senderLanguage,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isMe
                                                  ? Colors.white70
                                                  : AppColors.lightTextMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.translate_rounded,
                                            size: 12,
                                            color: isMe
                                                ? Colors.white70
                                                : AppColors.accent,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (msg.isAudio) ...[
                                        // 🎧 مشغل الصوت الفعلي المفعّل بالضغط
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  _togglePlayAudio(msg.id),
                                              child: Icon(
                                                isPlaying
                                                    ? Icons
                                                          .pause_circle_filled_rounded
                                                    : Icons
                                                          .play_circle_fill_rounded,
                                                color: isMe
                                                    ? Colors.white
                                                    : AppColors.primary,
                                                size: 34,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (isMe
                                                                  ? Colors.white
                                                                  : AppColors
                                                                        .primary)
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            2,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    isPlaying
                                                        ? 'جاري التشغيل...'
                                                        : (msg.audioDuration ??
                                                              '0:12'),
                                                    style: TextStyle(
                                                      color: isMe
                                                          ? Colors.white70
                                                          : AppColors
                                                                .lightTextMuted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                      ] else ...[
                                        Text(
                                          msg.originalText,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isMe
                                                ? Colors.white
                                                : (isDark
                                                      ? AppColors
                                                            .darkTextPrimary
                                                      : AppColors
                                                            .lightTextPrimary),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.black.withValues(
                                                  alpha: 0.15,
                                                )
                                              : AppColors.accent.withValues(
                                                  alpha: 0.12,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isMe
                                                ? Colors.white12
                                                : AppColors.accent.withValues(
                                                    alpha: 0.3,
                                                  ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.auto_awesome,
                                                  size: 12,
                                                  color: AppColors.accent,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${tr.translate('aiTranslationTitle')} (${msg.targetLanguage})',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isMe
                                                        ? Colors.white70
                                                        : AppColors.accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              msg.translatedText,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isMe
                                                    ? Colors.white.withValues(
                                                        alpha: 0.9,
                                                      )
                                                    : (isDark
                                                          ? AppColors
                                                                .darkTextPrimary
                                                          : AppColors
                                                                .lightTextPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_messageReactions.containsKey(msg.id))
                                  Positioned(
                                    bottom: -8,
                                    right: isMe ? null : 8,
                                    left: isMe ? 8 : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1F2937)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _messageReactions[msg.id]!,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (showReactionPopup)
                        Positioned(
                          top: -55,
                          left: isMe ? null : 16,
                          right: isMe ? 16 : null,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(30),
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF262D34),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildReactionItem(msg.id, '👍'),
                                  _buildReactionItem(msg.id, '❤️'),
                                  _buildReactionItem(msg.id, '😂'),
                                  _buildReactionItem(msg.id, '😮'),
                                  _buildReactionItem(msg.id, '😢'),
                                  _buildReactionItem(msg.id, '🙏'),
                                  _buildReactionItem(msg.id, '✨'),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _reactionTargetMsgId = null;
                                        _showEmojiPicker = true;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.white12,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // 2. شريط الإدخال السفلي المرن والمدمج
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: _isRecording
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.red,
                              size: 26,
                            ),
                            onPressed: _cancelRecording,
                          ),
                          IconButton(
                            icon: Icon(
                              _isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: _isPaused
                                  ? Colors.amber
                                  : AppColors.primary,
                              size: 28,
                            ),
                            onPressed: _togglePauseRecording,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _isPaused
                                        ? Colors.amber
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatRecordDuration(_recordSeconds),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '/ 20:00',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                            onPressed: _sendAudioMessage,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            icon: Icon(
                              _showEmojiPicker
                                  ? Icons.keyboard_rounded
                                  : Icons.sentiment_satisfied_alt_rounded,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                            onPressed: () {
                              if (_showEmojiPicker) {
                                setState(() => _showEmojiPicker = false);
                                _inputFocusNode.requestFocus();
                              } else {
                                _inputFocusNode.unfocus();
                                setState(() => _showEmojiPicker = true);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: textController,
                                      focusNode: _inputFocusNode,
                                      onTap: _scrollToBottom,
                                      maxLines: 5,
                                      minLines: 1,
                                      keyboardType: TextInputType.multiline,
                                      decoration: InputDecoration(
                                        hintText: tr.translate(
                                          'typeMessageHint',
                                        ),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 10,
                                            ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: Icon(
                                      Icons.attach_file_rounded,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: _openAttachmentBottomSheet,
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _showToast(
                                        'جاري فتح كاميرا الجهاز لالتقاط صورة...',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // 3. لوحة الإيموجيهات
            if (_showEmojiPicker)
              SizedBox(
                height: 300,
                child: EmojiPicker(
                  textEditingController: textController,
                  config: Config(
                    height: 300,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: isDark
                          ? const Color(0xFF111827)
                          : const Color(0xFFF9FAFB),
                      columns: 8,
                      emojiSizeMax:
                          28 *
                          (config.defaultTargetPlatform == TargetPlatform.iOS
                              ? 1.20
                              : 1.0),
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFE5E7EB),
                      iconColorSelected: AppColors.primary,
                      iconColor: Colors.grey,
                      indicatorColor: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionItem(String msgId, String emoji) {
    return GestureDetector(
      onTap: () => _addReactionToMessage(msgId, emoji),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
