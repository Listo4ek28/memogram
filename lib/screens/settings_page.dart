import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Настройки
  Color _accentColor = const Color(0xFF202020); // Dark по умолчанию
  Color _myMessageColor = const Color(0xFF202040); // Night по умолчанию
  String _language = 'ru';
  ThemeMode _themeMode = ThemeMode.dark;
  
  bool _isLoading = true;

  // Доступные языки
  final Map<String, String> _languages = {
    'ru': 'Русский',
    'en': 'English',
  };

  // Доступные акцентные цвета
  final Map<String, Color> _accentColors = {
    'Dark': const Color(0xFF202020),
    'Red Neon': const Color(0xFFFF0040),
    'Black': const Color(0xFF000000),
    'Silver': const Color(0xFFC8C8C8),
    'Night': const Color(0xFF202040),
    'Cherry': const Color(0xFF642032),
  };

  // Доступные цвета для своих сообщений
  final Map<String, Color> _myMessageColors = {
    'Night': const Color(0xFF202040),
    'Red Neon': const Color(0xFFFF0040),
    'Dark': const Color(0xFF202020),
    'Black': const Color(0xFF000000),
    'Silver': const Color(0xFFC8C8C8),
    'Cherry': const Color(0xFF642032),
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Загружаем акцентный цвет
      final savedColor = prefs.getString('accent_color');
      if (savedColor != null) {
        _accentColor = Color(int.parse(savedColor));
      }
      
      // Загружаем цвет своих сообщений
      final savedMyMessageColor = prefs.getString('my_message_color');
      if (savedMyMessageColor != null) {
        _myMessageColor = Color(int.parse(savedMyMessageColor));
      }
      
      // Загружаем язык
      _language = prefs.getString('language') ?? 'ru';
      
      // Загружаем тему
      final themeModeStr = prefs.getString('theme_mode');
      if (themeModeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeModeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      
      _isLoading = false;
    });
  }

  Future<void> _saveAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accent_color', color.value.toString());
    setState(() {
      _accentColor = color;
    });
  }

  Future<void> _saveMyMessageColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_message_color', color.value.toString());
    setState(() {
      _myMessageColor = color;
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _language = language;
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) {
      modeStr = 'light';
    } else if (mode == ThemeMode.dark) {
      modeStr = 'dark';
    }
    await prefs.setString('theme_mode', modeStr);
    setState(() {
      _themeMode = mode;
    });
  }

  void _showAccentColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Accent Color',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ..._accentColors.entries.map((entry) {
              final isSelected = _accentColor == entry.value;
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: entry.value,
                ),
                title: Text(entry.key),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _saveAccentColor(entry.value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Accent color changed to ${entry.key}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMyMessageColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose My Messages Color',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ..._myMessageColors.entries.map((entry) {
              final isSelected = _myMessageColor == entry.value;
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: entry.value,
                ),
                title: Text(entry.key),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _saveMyMessageColor(entry.value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('My messages color changed to ${entry.key}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ..._languages.entries.map((entry) {
              final isSelected = _language == entry.key;
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(entry.value),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await _saveLanguage(entry.key);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${entry.value}. Restarting...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  });
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brightness_medium),
              title: const Text('System Default'),
              trailing: _themeMode == ThemeMode.system
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _saveThemeMode(ThemeMode.system);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme changed to System Default'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_high),
              title: const Text('Light'),
              trailing: _themeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _saveThemeMode(ThemeMode.light);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme changed to Light'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_low),
              title: const Text('Dark'),
              trailing: _themeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _saveThemeMode(ThemeMode.dark);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme changed to Dark'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: _accentColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 16),
                
                // Акцентный цвет
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: _accentColor,
                      child: const Icon(Icons.color_lens, color: Colors.white, size: 20),
                    ),
                    title: const Text('Accent Color'),
                    subtitle: Text('Current: ${_getColorName(_accentColor, _accentColors)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAccentColorPicker,
                  ),
                ),
                
                // Цвет своих сообщений
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: _myMessageColor,
                      child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                    ),
                    title: const Text('My Messages Color'),
                    subtitle: Text('Current: ${_getColorName(_myMessageColor, _myMessageColors)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showMyMessageColorPicker,
                  ),
                ),
                
                // Язык
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    subtitle: Text(_languages[_language] ?? 'Russian'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLanguagePicker,
                  ),
                ),
                
                // Тема
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.brightness_medium),
                    title: const Text('Theme'),
                    subtitle: Text(_getThemeName(_themeMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showThemePicker,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Сообщение о применении настроек
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Theme, accent color and messages color changes will be applied after restart',
                          style: TextStyle(color: Colors.green.shade400, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  String _getColorName(Color color, Map<String, Color> colorMap) {
    for (var entry in colorMap.entries) {
      if (entry.value == color) {
        return entry.key;
      }
    }
    return 'Custom';
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
      default:
        return 'System Default';
    }
  }
}