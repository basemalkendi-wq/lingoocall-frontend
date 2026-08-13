class AppConstants {
  static const String appName = 'LingooCall';
  static const String tagLine = 'Break Language Barriers in Real-Time';
  static const String backendBaseUrl = 'https://lingoocall-backend.onrender.com';
  
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'AR', 'name': 'Arabic', 'flag': '🇾🇪', 'native': 'العربية'},
    {'code': 'TR', 'name': 'Turkish', 'flag': '🇹🇷', 'native': 'Türkçe'},
    {'code': 'EN', 'name': 'English', 'flag': '🇺🇸', 'native': 'English'},
    {'code': 'ES', 'name': 'Spanish', 'flag': '🇪🇸', 'native': 'Español'},
    {'code': 'FR', 'name': 'French', 'flag': '🇫🇷', 'native': 'Français'},
    {'code': 'DE', 'name': 'German', 'flag': '🇩🇪', 'native': 'Deutsch'},
    {'code': 'ZH', 'name': 'Chinese', 'flag': '🇨🇳', 'native': '中文'},
  ];

  static const List<Map<String, String>> countryCodes = [
    {'code': '+967', 'name': 'Yemen', 'flag': '🇾🇪'},
    {'code': '+90', 'name': 'Turkey', 'flag': '🇹🇷'},
    {'code': '+1', 'name': 'USA / Canada', 'flag': '🇺🇸'},
    {'code': '+966', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'code': '+971', 'name': 'UAE', 'flag': '🇦🇪'},
    {'code': '+44', 'name': 'UK', 'flag': '🇬🇧'},
    {'code': '+49', 'name': 'Germany', 'flag': '🇩🇪'},
  ];
}