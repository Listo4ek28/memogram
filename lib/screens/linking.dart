import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_page.dart';
import 'community_page.dart';
import 'showprofile_page.dart';

/// Парсит текст и находит упоминания @username и ##community
/// Возвращает RichText с кликабельными спанами
class MentionLinkifier {
  final int userId;
  final String username;
  final BuildContext context;
  final bool highlightCurrentUser;

  MentionLinkifier({
    required this.userId,
    required this.username,
    required this.context,
    this.highlightCurrentUser = true,
  });

  /// Преобразует обычный текст в RichText с кликабельными упоминаниями
  Widget buildRichText(String text, {TextStyle? style}) {
    if (text.isEmpty) return const SizedBox.shrink();

    final defaultStyle = style ?? const TextStyle(fontSize: 14, color: Colors.white);
    final spans = <TextSpan>[];
    // Ищем @username или ##community
    final regex = RegExp(r'(@\w+|##\w+)');
    final matches = regex.allMatches(text);

    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      final mention = match.group(0)!;
      if (mention.startsWith('@')) {
        // Убираем @ для поиска в БД (username хранится без @)
        final mentionedUsername = mention.substring(1);
        final isCurrentUser = mentionedUsername == username;
        spans.add(TextSpan(
          text: mention,
          style: TextStyle(
            color: (isCurrentUser && !highlightCurrentUser) 
                ? Colors.grey.shade400 
                : Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openUserProfile(mentionedUsername),
        ));
      } else if (mention.startsWith('##')) {
        final communityName = mention.substring(2);
        spans.add(TextSpan(
          text: mention,
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openCommunity(communityName),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: defaultStyle, children: spans),
    );
  }

  void _openUserProfile(String mentionedUsername) async {
    try {
      debugPrint('🔍 Searching for user: "$mentionedUsername"');
      
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/search_users.php?q=$mentionedUsername&user_id=$userId'),
      );
      
      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['users'] != null && data['users'].isNotEmpty) {
        debugPrint('✅ Found ${data['users'].length} users');
        
        // Ищем точное совпадение по username
        final user = data['users'].firstWhere(
          (u) => u['username'] == mentionedUsername,
          orElse: () {
            debugPrint('⚠️ No exact match for "$mentionedUsername", using first: ${data['users'][0]['username']}');
            return data['users'][0];
          },
        );
        
        debugPrint('👉 Opening profile for user: ${user['username']} (ID: ${user['id']})');
        
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowProfilePage(
              userId: userId,
              profileUserId: user['id'],
              currentUsername: username,
            ),
          ),
        );
      } else {
        debugPrint('❌ No users found for "$mentionedUsername"');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User @$mentionedUsername not found')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening user profile: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding user: $e')),
      );
    }
  }

  void _openCommunity(String communityName) async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/search_communities.php?q=${Uri.encodeComponent(communityName)}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['communities'].isNotEmpty) {
        final community = data['communities'].firstWhere(
          (c) => c['name'] == communityName || c['name'] == '##$communityName',
          orElse: () => data['communities'][0],
        );
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPage(
              userId: userId,
              username: username,
              communityId: community['id'],
              communityName: community['name'],
            ),
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Community $communityName not found')),
        );
      }
    } catch (e) {
      debugPrint('Error opening community: $e');
    }
  }

  /// Автодополнение — возвращает список подсказок для @ или ##
  static Future<List<String>> getSuggestions(String prefix, int currentUserId) async {
    if (prefix.isEmpty) return [];
    
    if (prefix.startsWith('@')) {
      final query = prefix.substring(1);
      if (query.isEmpty) return [];
      try {
        final response = await http.get(
          Uri.parse('https://listo4ek.tech/search_users.php?q=$query&user_id=$currentUserId'),
        );
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['users'] != null) {
          return (data['users'] as List)
              .map((u) => '@${u['username']}')
              .toList();
        }
      } catch (e) {
        debugPrint('Error getting suggestions: $e');
      }
    } else if (prefix.startsWith('##')) {
      final query = prefix.substring(2);
      if (query.isEmpty) return [];
      try {
        final response = await http.get(
          Uri.parse('https://listo4ek.tech/search_communities.php?q=$query'),
        );
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['communities'] != null) {
          return (data['communities'] as List)
              .map((c) => '##${c['name']}')
              .toList();
        }
      } catch (e) {
        debugPrint('Error getting community suggestions: $e');
      }
    }
    return [];
  }
}