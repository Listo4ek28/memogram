import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Импортируем MainNavigationPage
import '../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _errorMessage;
  bool _isLoading = false;
  bool _showSuccessMessage = false;
  
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  
  bool _usernameHasFocus = false;
  bool _passwordHasFocus = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
    _usernameFocus.addListener(() {
      setState(() => _usernameHasFocus = _usernameFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordHasFocus = _passwordFocus.hasFocus);
    });
  }

  String _t(String key) {
    return AppLocalizations.of(context)?.translate(key) ?? key;
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getInt('user_id');
    final savedUsername = prefs.getString('username');
    final savedAccentColor = prefs.getString('accent_color');
    
    if (savedUserId != null && savedUsername != null) {
      if (mounted) {
        final accentColor = savedAccentColor != null 
            ? Color(int.parse(savedAccentColor)) 
            : const Color(0xFFFF0040);
            
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationPage(
              userId: savedUserId,
              username: savedUsername,
              accentColor: accentColor,
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveLoginData(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('username', username);
  }

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = _t('fill_fields'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSuccessMessage = false;
    });

    final url = 'https://listo4ek.tech/${_isLogin ? 'login.php' : 'register.php'}';
    final body = _isLogin 
        ? {'username': _usernameController.text, 'password': _passwordController.text}
        : {
            'username': _usernameController.text, 
            'email': '${_usernameController.text}@meme.com', 
            'password': _passwordController.text
          };
    
    try {
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );
      
      final data = jsonDecode(response.body);
      
      if (mounted) {
        if (data['success'] == true) {
          if (_isLogin) {
            await _saveLoginData(data['user_id'], data['display_name'] ?? data['username']);
            
            // Получаем акцентный цвет из настроек
            final prefs = await SharedPreferences.getInstance();
            final savedAccentColor = prefs.getString('accent_color');
            final accentColor = savedAccentColor != null 
                ? Color(int.parse(savedAccentColor)) 
                : const Color(0xFFFF0040);
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigationPage(
                  userId: data['user_id'], 
                  username: data['display_name'] ?? data['username'],
                  accentColor: accentColor,
                ),
              ),
            );
          } else {
            setState(() {
              _showSuccessMessage = true;
              _isLogin = true;
              _isLoading = false;
            });
            _usernameController.clear();
            _passwordController.clear();
            
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _showSuccessMessage = false);
              }
            });
          }
        } else {
          setState(() => _errorMessage = data['error'] ?? _t('username_exists'));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _t('connection_error'));
      }
    } finally {
      if (mounted && _isLoading && !_isLogin) {
        setState(() => _isLoading = false);
      }
      if (mounted && _isLoading && _isLogin) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? _t('login_title') : _t('register_title')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey.shade800,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                Text(
                  'MEMOGRAM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'exchange memes. receive chaos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Поле ввода username
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _usernameHasFocus ? Colors.white : Colors.transparent,
                      width: _usernameHasFocus ? 1.5 : 0,
                    ),
                  ),
                  child: TextField(
                    cursorColor: Colors.white,
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    decoration: InputDecoration(
                      labelText: null,
                      hintText: (!_usernameHasFocus && _usernameController.text.isEmpty) ? _t('username') : null,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '@',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      enabled: !_isLoading,
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    onTap: () {
                      if (_usernameController.text.isNotEmpty) {
                        _usernameController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле ввода password
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _passwordHasFocus ? Colors.white : Colors.transparent,
                      width: _passwordHasFocus ? 1.5 : 0,
                    ),
                  ),
                  child: TextField(
                    cursorColor: Colors.white,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    decoration: InputDecoration(
                      labelText: null,
                      hintText: (!_passwordHasFocus && _passwordController.text.isEmpty) ? _t('password') : null,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      enabled: !_isLoading,
                    ),
                    obscureText: true,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    onTap: () {
                      if (_passwordController.text.isNotEmpty) {
                        _passwordController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Кнопка Submit
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade900,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLogin ? _t('login') : _t('register'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                if (_showSuccessMessage)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _t('registration_success'),
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade700)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _t('or'),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade700)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                            _showSuccessMessage = false;
                            _usernameController.clear();
                            _passwordController.clear();
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                    foregroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    _isLogin 
                        ? _t('create_account')
                        : _t('back_to_login'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}