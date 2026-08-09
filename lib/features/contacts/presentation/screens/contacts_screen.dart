import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class ContactsScreen extends StatelessWidget {
  final AppController controller;

  ContactsScreen({super.key, required this.controller});

  final List<ContactItem> contactsList = [
    ContactItem(
      id: 'c1',
      name: 'Ayla Yılmaz',
      phone: '+90 532 111 2233',
      nativeLanguage: 'Turkish',
      flag: '🇹🇷',
      isRegistered: true,
      isOnline: true,
    ),
    ContactItem(
      id: 'c2',
      name: 'Dr. Tariq Hassan',
      phone: '+967 770 998 877',
      nativeLanguage: 'Arabic',
      flag: '🇾🇪',
      isRegistered: true,
      isOnline: false,
    ),
    ContactItem(
      id: 'c3',
      name: 'Sophie Laurent',
      phone: '+33 612 345 678',
      nativeLanguage: 'French',
      flag: '🇫🇷',
      isRegistered: true,
      isOnline: true,
    ),
    ContactItem(
      id: 'c4',
      name: 'John Miller',
      phone: '+1 415 555 0199',
      nativeLanguage: 'English',
      flag: '🇺🇸',
      isRegistered: false,
      isOnline: false,
    ),
    ContactItem(
      id: 'c5',
      name: 'Carlos Rodriguez',
      phone: '+34 600 123 456',
      nativeLanguage: 'Spanish',
      flag: '🇪🇸',
      isRegistered: false,
      isOnline: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contacts synced with LingooCall network!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts or phone numbers...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: contactsList.length,
              separatorBuilder: (ctx, idx) => Divider(
                height: 1,
                indent: 72,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              itemBuilder: (context, index) {
                final c = contactsList[index];
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          c.name.isNotEmpty ? c.name.substring(0, 1) : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Text(
                          c.flag,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      // تغليف الاسم بـ Expanded يمنع خطأ Overflows عند زيادة طول النص
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (c.isRegistered) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      // تغليف نص الهاتف واللغة بـ Expanded لحل مشكلة 3.5 Pixels Overflow
                      Expanded(
                        child: Text(
                          '${c.phone} • Speaks ${c.nativeLanguage}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: c.isRegistered
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                controller.openChat(c);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      controller: controller,
                                      contact: c,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.videocam_outlined,
                                color: AppColors.accent,
                              ),
                              onPressed: () => controller.startCall(c),
                            ),
                          ],
                        )
                      : OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invitation sent to ${c.name}'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: const Text(
                            'Invite',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}