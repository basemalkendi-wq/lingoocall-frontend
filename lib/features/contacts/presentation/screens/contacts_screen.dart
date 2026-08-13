import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/features/call/presentation/screens/video_call_screen.dart';
import 'package:lingoocall/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class ContactsScreen extends StatefulWidget {
  final AppController controller;

  const ContactsScreen({super.key, required this.controller});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshContacts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() async {
    await widget.controller.syncRegisteredContacts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts synced with LingooCall network!')),
      );
    }
  }

  void _openChat(ContactItem contact) {
    widget.controller.openChat(contact);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(controller: widget.controller, contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleContacts = widget.controller.registeredContacts.where((contact) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return contact.name.toLowerCase().contains(query) || contact.phone.toLowerCase().contains(query);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Contacts'),
        actions: [
          IconButton(
            icon: widget.controller.isContactsSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: widget.controller.isContactsSyncing ? null : _refreshContacts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshContacts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search registered contacts...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: isDark ? AppColors.darkSurface : Colors.white,
                ),
              ),
            ),
            Expanded(
              child: widget.controller.registeredContacts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No registered contacts were found on this device yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: visibleContacts.length,
                      separatorBuilder: (ctx, idx) => Divider(
                        height: 1,
                        indent: 72,
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                      itemBuilder: (context, index) {
                        final contact = visibleContacts[index];
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  contact.name.isNotEmpty ? contact.name.substring(0, 1).toUpperCase() : '?',
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
                                child: Text(contact.flag, style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                              if (contact.isOnline) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${contact.phone} • Speaks ${contact.nativeLanguage}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: AppColors.primary,
                                ),
                                onPressed: () => _openChat(contact),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.videocam_outlined,
                                  color: AppColors.accent,
                                ),
                                onPressed: () {
                                  widget.controller.startCall(contact);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideoCallScreen(controller: widget.controller),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => _openChat(contact),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}