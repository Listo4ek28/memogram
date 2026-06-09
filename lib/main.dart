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
    await prefs.setString('accent_color', const Color(0xFFFF0040).value.toString());
  }
  if (!prefs.containsKey('my_message_color')) {
    await prefs.setString('my_message_color', const Color(0xFF642032).value.toString());
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
      : const Color(0xFFFF0040);
  
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF202020),
          elevation: 0,
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.grey,
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
          : MainNavigationPage(userId: userId, username: username, accentColor: accentColor),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final int userId;
  final String username;
  final Color accentColor;
  
  const MainNavigationPage({
    super.key,
    required this.userId,
    required this.username,
    required this.accentColor,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> with WidgetsBindingObserver {
  int _currentIndex = 1; // 0 - сообщества, 1 - лента, 2 - чаты
  
  late final List<Widget> _pages;
  late final List<GlobalKey> _pageKeys;
  
  // Храним состояния страниц
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pageKeys = [
      GlobalKey(debugLabel: 'communities'),
      GlobalKey(debugLabel: 'feed'),
      GlobalKey(debugLabel: 'chats'),
    ];
    
    _pages = [
      CommunitiesPage(key: _pageKeys[0], userId: widget.userId, username: widget.username),
      FeedPage(key: _pageKeys[1], userId: widget.userId, username: widget.username),
      ChatsPage(key: _pageKeys[2], userId: widget.userId, username: widget.username),
    ];
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // При возвращении приложения обновляем ВСЕ страницы в фоне
      _updateAllPagesInBackground();
    }
  }
  
  void _updateAllPagesInBackground() {
    // Обновляем все страницы с задержкой
    Future.delayed(const Duration(milliseconds: 500), () {
      for (int i = 0; i < _pages.length; i++) {
        _triggerPageUpdate(i);
      }
    });
  }
  
  void _triggerPageUpdate(int index) {
    // Небольшая задержка для гарантии, что виджет отрисован
    Future.delayed(const Duration(milliseconds: 100), () {
      final key = _pageKeys[index];
      final state = key.currentState;
      
      if (state != null) {
        debugPrint('🔄 Updating page at index: $index');
        if (index == 0 && state is CommunitiesPage) {
          (state as dynamic).refreshData();
        } else if (index == 1 && state is FeedPage) {
          (state as dynamic).refreshData();
        } else if (index == 2 && state is ChatsPage) {
          (state as dynamic).refreshData();
        }
      } else {
        debugPrint('⚠️ State is null for index: $index, retrying...');
        // Если state null, пробуем ещё раз через 200 мс
        Future.delayed(const Duration(milliseconds: 200), () {
          _triggerPageUpdate(index);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // При переключении обновляем ТОЛЬКО выбранную страницу
          _triggerPageUpdate(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: widget.accentColor,
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
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}