import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/feed_page.dart';
import 'screens/communities_page.dart';
import 'screens/chats_page.dart';
import 'screens/login_page.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  // Устанавливаем цвета по умолчанию при первом запуске
  if (!prefs.containsKey('accent_color')) {
    await prefs.setString('accent_color', const Color(0xFF202020).value.toString());
  }
  if (!prefs.containsKey('my_message_color')) {
    await prefs.setString('my_message_color', const Color(0xFF202040).value.toString());
  }
  if (!prefs.containsKey('theme_mode')) {
    await prefs.setString('theme_mode', 'dark');
  }
  if (!prefs.containsKey('language')) {
    await prefs.setString('language', 'ru');
  }
  
  final accentColorStr = prefs.getString('accent_color');
  final themeModeStr = prefs.getString('theme_mode');
  final languageCode = prefs.getString('language') ?? 'ru';
  
  Color accentColor = accentColorStr != null 
      ? Color(int.parse(accentColorStr)) 
      : const Color(0xFF202020);
  
  ThemeMode themeMode = ThemeMode.dark;
  if (themeModeStr == 'light') {
    themeMode = ThemeMode.light;
  } else if (themeModeStr == 'dark') {
    themeMode = ThemeMode.dark;
  } else {
    themeMode = ThemeMode.system;
  }
  
  final savedUserId = prefs.getInt('user_id');
  final savedUsername = prefs.getString('username');
  
  runApp(MemeApp(
    accentColor: accentColor,
    themeMode: themeMode,
    locale: Locale(languageCode),
    initialRoute: savedUserId != null ? 'main' : 'login',
    userId: savedUserId ?? 0,
    username: savedUsername ?? '',
  ));
}

class MemeApp extends StatelessWidget {
  final Color accentColor;
  final ThemeMode themeMode;
  final Locale locale;
  final String initialRoute;
  final int userId;
  final String username;
  
  const MemeApp({
    super.key,
    required this.accentColor,
    required this.themeMode,
    required this.locale,
    required this.initialRoute,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memogram',
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', ''),
        Locale('en', ''),
      ],
      theme: ThemeData.dark().copyWith(
        primaryColor: accentColor,
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          secondary: accentColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: accentColor,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: accentColor),
          ),
        ),
      ),
      themeMode: themeMode,
      home: initialRoute == 'login' 
          ? const LoginPage() 
          : MainNavigationPage(userId: userId, username: username),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final int userId;
  final String username;
  
  const MainNavigationPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 1; // 0 - сообщества, 1 - лента, 2 - чаты
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CommunitiesPage(userId: widget.userId, username: widget.username),
      FeedPage(userId: widget.userId, username: widget.username),
      ChatsPage(userId: widget.userId, username: widget.username), // используем ChatsPage
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Communities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}

// Сборка apk: flutter build apk --release --split-per-abi