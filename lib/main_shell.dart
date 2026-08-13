import 'package:flutter/material.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/services/socket_service.dart';
import 'package:lingoocall/features/call/presentation/screens/video_call_screen.dart';
import 'package:lingoocall/features/call/presentation/widgets/incoming_call_dialog.dart';
import 'package:lingoocall/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';
import 'package:lingoocall/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:lingoocall/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:lingoocall/features/settings/presentation/widgets/navigation_drawer.dart';

class MainShell extends StatefulWidget {
  final AppController controller;

  const MainShell({super.key, required this.controller});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _setupIncomingCallListener();
  }

  void _setupIncomingCallListener() {
    SocketService().listenToIncomingCall((data) {
      if (!mounted) return;

      final String callerId = data['from'];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => IncomingCallDialog(
          callerName: callerId,
          callerAvatar: '',
          onAccept: () {
            Navigator.pop(dialogContext);

            // إعداد جهة الاتصال وتفعيل وضع المكالمة مع إضافة isRegistered
            final contact = ContactItem(
              id: callerId,
              name: callerId,
              phone: '',
              nativeLanguage: 'Turkish',
              flag: '🇹🇷',
              isRegistered: true,
              isOnline: true,
            );

            widget.controller.startCall(contact);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoCallScreen(controller: widget.controller),
              ),
            );
          },
          onReject: () {
            Navigator.pop(dialogContext);
            SocketService().rejectCall(to: callerId);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.controller.appLocale.languageCode == 'ar';
    final String chatsLabel = isAr ? 'المحادثات' : 'Chats';
    final String contactsLabel = isAr ? 'جهات الاتصال' : 'Contacts';
    final String profileLabel = isAr ? 'الملف الشخصي' : 'Profile';

    // استبدال شاشة الإعدادات بشاشة الملف الشخصي (Instagram Style)
    final List<Widget> screens = [
      ChatListScreen(controller: widget.controller, scaffoldKey: _scaffoldKey),
      ContactsScreen(controller: widget.controller),
      UserProfileScreen(controller: widget.controller),
    ];

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: AppNavigationDrawer(controller: widget.controller),
          body: IndexedStack(
            index: widget.controller.selectedBottomTab,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: widget.controller.selectedBottomTab,
            onTap: (index) => widget.controller.setBottomTab(index),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                activeIcon: const Icon(Icons.chat_bubble_rounded),
                label: chatsLabel,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.contacts_outlined),
                activeIcon: const Icon(Icons.contacts_rounded),
                label: contactsLabel,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: profileLabel,
              ),
            ],
          ),
        );
      },
    );
  }
}