class ContactItem {
  final String id;
  final String name;
  final String phone;
  final String nativeLanguage;
  final String flag;
  final bool isRegistered;
  final bool isOnline;

  ContactItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.nativeLanguage,
    required this.flag,
    required this.isRegistered,
    required this.isOnline,
  });
}