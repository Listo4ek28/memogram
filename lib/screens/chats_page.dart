import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'admin_page.dart';
import '../widgets/avatar_widget.dart';

class ChatsPage extends StatefulWidget {
  final int userId;
  final String username;
  
  const ChatsPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _recommendedUsers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String _searchQuery = '';
  String? _userAvatarBase64;
  Color _myMessageColor = const Color(0xFF202040);

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
    _loadMyMessageColor();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAvatar() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_user_profile.php?user_id=${widget.userId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _userAvatarBase64 = data['user']['avatar'];
        });
      }
    } catch (e) {
      debugPrint('Error loading avatar: $e');
    }
  }

  Future<void> _loadMyMessageColor() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getString('my_message_color');
    if (c != null) {
      setState(() => _myMessageColor = Color(int.parse(c)));
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadChats(),
      _loadFriends(),
      _loadRecommendedUsers(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadChats() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_chats_list.php?user_id=${widget.userId}'),
      );
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _chats = List<Map<String, dynamic>>.from(data['chats'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_friends.php?user_id=${widget.userId}'),
      );
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _friends = List<Map<String, dynamic>>.from(data['friends'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
  }

  Future<void> _loadRecommendedUsers() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_recommended_users.php?user_id=${widget.userId}'),
      );
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _recommendedUsers = List<Map<String, dynamic>>.from(data['users'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading recommended users: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });
    
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/search_users.php?q=${Uri.encodeComponent(query)}&user_id=${widget.userId}'),
      );
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data['users'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  Future<void> _sendFriendRequest(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/add_friend.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'friend_id': userId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to send request'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startChat(int otherUserId, String otherUsername) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          userId: widget.userId,
          username: widget.username,
          chatId: otherUserId,
          chatName: otherUsername,
          isGroup: false,
        ),
      ),
    ).then((_) => _loadData());
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'now';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade800,
              ),
              onChanged: _searchUsers,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin (all memes)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPage()),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    userId: widget.userId,
                    username: widget.username,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: AppAvatar(
                base64Image: _userAvatarBase64,
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _isSearching
                  ? _searchResults.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No users found'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: AppAvatar(
                                base64Image: user['avatar'],
                                radius: 20,
                              ),
                              title: Text(user['display_name']),
                              subtitle: Text('@${user['username']}'),
                              onTap: () => _startChat(user['id'], user['display_name']),
                            );
                          },
                        )
                  : ListView(
                      children: [
                        if (_chats.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Recent Chats',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ..._chats.map((chat) => ListTile(
                            leading: AppAvatar(
                              base64Image: chat['avatar'],
                              radius: 20,
                            ),
                            title: Text(chat['display_name'] ?? 'User'),
                            subtitle: Text(
                              chat['last_message'] ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(chat['last_message_time']),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                if ((chat['unread_count'] ?? 0) > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${chat['unread_count']}',
                                      style: const TextStyle(fontSize: 11, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _startChat(chat['chat_id'], chat['display_name'] ?? 'User'),
                          )),
                          const Divider(),
                        ],
                        
                        if (_friends.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Friends',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ..._friends.map((friend) => ListTile(
                            leading: AppAvatar(
                              base64Image: friend['avatar'],
                              radius: 20,
                            ),
                            title: Text(friend['display_name']),
                            subtitle: Text('@${friend['username']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.message, color: Colors.blue),
                              onPressed: () => _startChat(friend['id'], friend['display_name']),
                              tooltip: 'Send message',
                            ),
                            onTap: () => _startChat(friend['id'], friend['display_name']),
                          )),
                          const Divider(),
                        ],
                        
                        if (_recommendedUsers.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Recommended for you',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ..._recommendedUsers.take(5).map((user) => ListTile(
                            leading: AppAvatar(
                              base64Image: user['avatar'],
                              radius: 20,
                            ),
                            title: Text(user['display_name']),
                            subtitle: Text('@${user['username']}'),
                            trailing: OutlinedButton(
                              onPressed: () => _sendFriendRequest(user['id']),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.green.shade400),
                                foregroundColor: Colors.green.shade400,
                              ),
                              child: const Text('Follow'),
                            ),
                          )),
                        ],
                        
                        if (_chats.isEmpty && _friends.isEmpty && _recommendedUsers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No chats yet'),
                                  SizedBox(height: 8),
                                  Text('Search for users to start messaging!'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}