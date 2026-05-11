import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
    String jsonString = await _loadLocalizedStrings();
    Map<String, dynamic> jsonMap = {
      'ru': {
        'app_title': 'Memogram',
        'login_title': 'Вход',
        'register_title': 'Создать аккаунт',
        'username': 'Имя пользователя',
        'password': 'Пароль',
        'login': 'Войти',
        'register': 'Зарегистрироваться',
        'or': 'или',
        'create_account': 'Создать аккаунт',
        'back_to_login': 'Назад ко входу',
        'registration_success': 'Регистрация успешна! Пожалуйста, войдите.',
        'fill_fields': 'Заполните все поля',
        'connection_error': 'Ошибка подключения. Проверьте интернет.',
        'username_exists': 'Имя пользователя или email уже существует',
        'invalid_credentials': 'Неверное имя пользователя или пароль',
        
        // Chat page
        'meme_chat': 'Мем чат',
        'filter_messages': 'Фильтр сообщений',
        'all_messages': 'Все сообщения',
        'my_memes': 'Мои мемы',
        'favorites': 'Избранное',
        'liked_messages': 'Понравившиеся',
        'saved_memes': 'Сохранённые мемы',
        'memes_you_reacted': 'Мемы с вашей реакцией',
        'write_meme': 'Напишите мем...',
        'attach_image': 'Прикрепить изображение',
        'send': 'Отправить',
        'please_write_or_select': 'Напишите что-нибудь или выберите изображение',
        'failed_to_load': 'Не удалось загрузить сообщения',
        'failed_to_send': 'Не удалось отправить мем',
        'no_messages': 'Нет сообщений',
        'send_meme_to_start': 'Отправьте мем, чтобы начать общение!',
        'reaction_removed': '❤️ Реакция удалена',
        'you_liked': '❤️ Вам понравился этот мем!',
        'already_reacted': 'Вы уже поставили реакцию',
        'added_to_favorites': 'Добавлено в избранное ⭐',
        'message_removed': 'Сообщение удалено из чата',
        'report_submitted': 'Жалоба отправлена',
        'failed_to_report': 'Не удалось отправить жалобу',
        'save_to_favorites': 'Сохранить в избранное',
        'saved_to_favorites': 'Сохранено в избранное',
        'like_this_meme': 'Лайкнуть этот мем',
        'remove_like': 'Убрать лайк',
        'double_tap_works': 'Двойной тап тоже работает',
        'delete_from_chat': 'Удалить из чата',
        'report': 'Пожаловаться',
        'spam': 'Спам',
        'advertising': 'Реклама',
        'nsfw': 'NSFW контент',
        'harassment': 'Домогательства',
        'other': 'Другое',
        'you': 'Вы',
        
        // Profile page
        'profile': 'Профиль',
        'edit_profile': 'Редактировать профиль',
        'memes_viewed': 'Просмотрено мемов',
        'member_since': 'На сайте с',
        'settings': 'Настройки',
        'logout': 'Выйти',
        'about_memogram': 'О Memogram...',
        'settings_coming': 'Настройки скоро появятся!',
        
        // Edit profile page
        'edit_profile_title': 'Редактирование профиля',
        'save': 'Сохранить',
        'display_name': 'Отображаемое имя',
        'your_display_name': 'Ваше отображаемое имя',
        'username_hint': 'username',
        'only_letters_numbers': 'Только буквы, цифры и подчёркивание',
        'email': 'Email',
        'will_be_used_for_login': 'Будет использоваться для входа',
        'bio': 'О себе',
        'tell_about_yourself': 'Расскажите о себе...',
        'account_information': 'Информация об аккаунте',
        'joined': 'Присоединился',
        'display_name_cannot_be_empty': 'Отображаемое имя не может быть пустым',
        'username_cannot_be_empty': 'Имя пользователя не может быть пустым',
        'email_cannot_be_empty': 'Email не может быть пустым',
        'enter_valid_email': 'Введите корректный email адрес',
        'profile_updated': 'Профиль обновлён успешно!',
        'failed_to_update': 'Не удалось обновить профиль',
        
        // Settings page
        'settings_title': 'Настройки',
        'accent_color': 'Акцентный цвет',
        'my_messages_color': 'Цвет моих сообщений',
        'language': 'Язык',
        'theme': 'Тема',
        'system_default': 'Системная',
        'light': 'Светлая',
        'dark': 'Тёмная',
        'current': 'Текущий',
        'choose_accent_color': 'Выберите акцентный цвет',
        'choose_messages_color': 'Выберите цвет моих сообщений',
        'choose_language': 'Выберите язык',
        'choose_theme': 'Выберите тему',
        'accent_color_changed': 'Акцентный цвет изменён на',
        'messages_color_changed': 'Цвет сообщений изменён на',
        'language_changed': 'Язык изменён',
        'theme_changed': 'Тема изменена на',
        'settings_apply_restart': 'Изменения темы и цветов применятся после перезапуска',
      },
      'en': {
        'app_title': 'Memogram',
        'login_title': 'Login',
        'register_title': 'Create Account',
        'username': 'Username',
        'password': 'Password',
        'login': 'Login',
        'register': 'Register',
        'or': 'or',
        'create_account': 'Create Account',
        'back_to_login': 'Back to Login',
        'registration_success': 'Registration successful! Please login.',
        'fill_fields': 'Please fill in all fields',
        'connection_error': 'Connection error. Please check your internet.',
        'username_exists': 'Username or email already exists',
        'invalid_credentials': 'Invalid username or password',
        
        // Chat page
        'meme_chat': 'Meme Chat',
        'filter_messages': 'Filter Messages',
        'all_messages': 'All Messages',
        'my_memes': 'My Memes',
        'favorites': 'Favorites',
        'liked_messages': 'Liked Messages',
        'saved_memes': 'Saved memes',
        'memes_you_reacted': 'Memes you reacted to',
        'write_meme': 'Write a meme...',
        'attach_image': 'Attach image',
        'send': 'Send',
        'please_write_or_select': 'Please write something or select an image',
        'failed_to_load': 'Failed to load messages',
        'failed_to_send': 'Failed to send meme',
        'no_messages': 'No messages yet',
        'send_meme_to_start': 'Send a meme to start the conversation!',
        'reaction_removed': '❤️ Reaction removed',
        'you_liked': '❤️ You liked this meme!',
        'already_reacted': 'You already reacted to this meme',
        'added_to_favorites': 'Added to favorites ⭐',
        'message_removed': 'Message removed from chat',
        'report_submitted': 'Report submitted successfully',
        'failed_to_report': 'Failed to submit report',
        'save_to_favorites': 'Save to Favorites',
        'saved_to_favorites': 'Saved to Favorites',
        'like_this_meme': 'Like this Meme',
        'remove_like': 'Remove Like',
        'double_tap_works': 'Double tap or tap reaction also works',
        'delete_from_chat': 'Delete from Chat',
        'report': 'Report',
        'spam': 'Spam',
        'advertising': 'Advertising',
        'nsfw': 'NSFW Content',
        'harassment': 'Harassment',
        'other': 'Other Violations',
        'you': 'You',
        
        // Profile page
        'profile': 'Profile',
        'edit_profile': 'Edit Profile',
        'memes_viewed': 'Memes viewed',
        'member_since': 'Member since',
        'settings': 'Settings',
        'logout': 'Logout',
        'about_memogram': 'About Memogram...',
        'settings_coming': 'Settings coming soon!',
        
        // Edit profile page
        'edit_profile_title': 'Edit Profile',
        'save': 'Save',
        'display_name': 'Display Name',
        'your_display_name': 'Your display name',
        'username_hint': 'username',
        'only_letters_numbers': 'Only letters, numbers and underscore',
        'email': 'Email',
        'will_be_used_for_login': 'Will be used for login',
        'bio': 'Bio',
        'tell_about_yourself': 'Tell something about yourself...',
        'account_information': 'Account Information',
        'joined': 'Joined',
        'display_name_cannot_be_empty': 'Display name cannot be empty',
        'username_cannot_be_empty': 'Username cannot be empty',
        'email_cannot_be_empty': 'Email cannot be empty',
        'enter_valid_email': 'Please enter a valid email address',
        'profile_updated': 'Profile updated successfully!',
        'failed_to_update': 'Failed to update profile',
        
        // Settings page
        'settings_title': 'Settings',
        'accent_color': 'Accent Color',
        'my_messages_color': 'My Messages Color',
        'language': 'Language',
        'theme': 'Theme',
        'system_default': 'System Default',
        'light': 'Light',
        'dark': 'Dark',
        'current': 'Current',
        'choose_accent_color': 'Choose Accent Color',
        'choose_messages_color': 'Choose My Messages Color',
        'choose_language': 'Choose Language',
        'choose_theme': 'Choose Theme',
        'accent_color_changed': 'Accent color changed to',
        'messages_color_changed': 'My messages color changed to',
        'language_changed': 'Language changed to',
        'theme_changed': 'Theme changed to',
        'settings_apply_restart': 'Theme, accent color and messages color changes will be applied after restart',
      }
    };
    
    _localizedStrings = jsonMap[locale.languageCode] as Map<String, String>;
    return true;
  }

  Future<String> _loadLocalizedStrings() async {
    return '';
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ru', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}