import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _reportsTabController;
  
  List<Map<String, dynamic>> _postsReports = [];
  List<Map<String, dynamic>> _messagesReports = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _communities = [];
  List<Map<String, dynamic>> _communityMemes = [];
  
  bool _isLoadingPostsReports = true;
  bool _isLoadingMessagesReports = true;
  bool _isLoadingUsers = true;
  bool _isLoadingCommunities = true;
  bool _isLoadingCommunityMemes = false;
  
  String _searchPostsReports = '';
  String _searchMessagesReports = '';
  String _searchUsers = '';
  String _searchCommunities = '';
  
  Map<String, dynamic>? _selectedCommunity;
  int _adminId = 0;
  Color _accentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadAccentColor();
    _tabController = TabController(length: 3, vsync: this);
    _reportsTabController = TabController(length: 2, vsync: this);
    _loadAdminId();
  }

  Future<void> _loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getString('accent_color');
    if (savedColor != null && mounted) {
      setState(() => _accentColor = Color(int.parse(savedColor)));
    }
  }

  Future<void> _loadAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getInt('user_id') ?? 0;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadPostsReports(),
      _loadMessagesReports(),
      _loadUsers(),
      _loadCommunities(),
    ]);
  }

  // ТОЧНО ТАКОЙ ЖЕ МЕТОД КАК В FeedPage!
  Future<void> _loadPostsReports() async {
    setState(() => _isLoadingPostsReports = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/admin_get_reports.php?user_id=$_adminId&type=posts&search=${Uri.encodeComponent(_searchPostsReports)}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _postsReports = List<Map<String, dynamic>>.from(data['reports']);
          _isLoadingPostsReports = false;
        });
      } else {
        setState(() => _isLoadingPostsReports = false);
      }
    } catch (e) {
      debugPrint('Error loading posts reports: $e');
      setState(() => _isLoadingPostsReports = false);
    }
  }

  // ТОЧНО ТАКОЙ ЖЕ МЕТОД КАК В FeedPage!
  Future<void> _loadMessagesReports() async {
    setState(() => _isLoadingMessagesReports = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/admin_get_reports.php?user_id=$_adminId&type=messages&search=${Uri.encodeComponent(_searchMessagesReports)}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _messagesReports = List<Map<String, dynamic>>.from(data['reports']);
          _isLoadingMessagesReports = false;
        });
      } else {
        setState(() => _isLoadingMessagesReports = false);
      }
    } catch (e) {
      debugPrint('Error loading messages reports: $e');
      setState(() => _isLoadingMessagesReports = false);
    }
  }

  // ТОЧНО ТАКОЙ ЖЕ МЕТОД КАК В FeedPage!
  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/admin_get_users.php?user_id=$_adminId&search=${Uri.encodeComponent(_searchUsers)}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data['users']);
          _isLoadingUsers = false;
        });
      } else {
        setState(() => _isLoadingUsers = false);
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  // ТОЧНО ТАКОЙ ЖЕ МЕТОД КАК В FeedPage!
  Future<void> _loadCommunities() async {
    setState(() => _isLoadingCommunities = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/admin_get_communities.php?user_id=$_adminId&search=${Uri.encodeComponent(_searchCommunities)}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _communities = List<Map<String, dynamic>>.from(data['communities']);
          _isLoadingCommunities = false;
        });
      } else {
        setState(() => _isLoadingCommunities = false);
      }
    } catch (e) {
      debugPrint('Error loading communities: $e');
      setState(() => _isLoadingCommunities = false);
    }
  }

  Future<void> _loadCommunityMemes(int communityId) async {
    setState(() => _isLoadingCommunityMemes = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/admin_get_community_memes.php?user_id=$_adminId&community_id=$communityId'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _communityMemes = List<Map<String, dynamic>>.from(data['memes']);
          _isLoadingCommunityMemes = false;
        });
      } else {
        setState(() => _isLoadingCommunityMemes = false);
      }
    } catch (e) {
      debugPrint('Error loading community memes: $e');
      setState(() => _isLoadingCommunityMemes = false);
    }
  }

  Future<void> _performAction({
    required String action,
    required String targetType,
    required int targetId,
    String? extra,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/admin_actions.php'),
        body: jsonEncode({
          'admin_id': _adminId,
          'action': action,
          'target_type': targetType,
          'target_id': targetId,
          'extra': extra,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );
        await _loadAllData();
        if (_selectedCommunity != null) {
          await _loadCommunityMemes(_selectedCommunity!['id']);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Action failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error performing action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPostReportMenu(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.skip_next, color: Colors.blue),
            title: const Text('Skip Report'),
            onTap: () {
              Navigator.pop(context);
              _performAction(action: 'skip_post_report', targetType: 'report', targetId: report['report_id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Post & Report'),
            onTap: () {
              Navigator.pop(context);
              _performAction(action: 'delete_reported_post', targetType: 'report', targetId: report['report_id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Ban User'),
            onTap: () {
              Navigator.pop(context);
              _performAction(action: 'ban_user', targetType: 'user', targetId: report['user_id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.red),
            title: const Text('Delete User'),
            onTap: () {
              Navigator.pop(context);
              _showConfirmDialog(
                title: 'Delete User',
                message: 'Are you sure? This will delete all user data.',
                onConfirm: () => _performAction(action: 'delete_user', targetType: 'user', targetId: report['user_id']),
              );
            },
          ),
          if (report['community_id'] != null)
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Delete Community'),
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  title: 'Delete Community',
                  message: 'Are you sure? This will delete all community posts.',
                  onConfirm: () => _performAction(action: 'delete_community', targetType: 'community', targetId: report['community_id']),
                );
              },
            ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showMessageReportMenu(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.skip_next, color: Colors.blue),
            title: const Text('Skip Report'),
            onTap: () {
              Navigator.pop(context);
              _performAction(action: 'skip_message_report', targetType: 'report', targetId: report['report_id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Message & Report'),
            onTap: () {
              Navigator.pop(context);
              _performAction(action: 'delete_reported_message', targetType: 'report', targetId: report['report_id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Ban User'),
            onTap: () {
              Navigator.pop(context);
              _performAction(action: 'ban_user', targetType: 'user', targetId: report['user_id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.red),
            title: const Text('Delete User'),
            onTap: () {
              Navigator.pop(context);
              _showConfirmDialog(
                title: 'Delete User',
                message: 'Are you sure? This will delete all user data.',
                onConfirm: () => _performAction(action: 'delete_user', targetType: 'user', targetId: report['user_id']),
              );
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showUserMenu(Map<String, dynamic> user) {
    final isBanned = user['banned'] == 1;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('User Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(),
          if (isBanned)
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Unban User'),
              onTap: () {
                Navigator.pop(context);
                _performAction(action: 'unban_user', targetType: 'user', targetId: user['id']);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Ban User'),
              onTap: () {
                Navigator.pop(context);
                _performAction(action: 'ban_user', targetType: 'user', targetId: user['id']);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete User', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showConfirmDialog(
                title: 'Delete User',
                message: 'Delete @${user['username']}? This cannot be undone.',
                onConfirm: () => _performAction(action: 'delete_user', targetType: 'user', targetId: user['id']),
              );
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showCommunityMenu(Map<String, dynamic> community) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Community Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Delete Community'),
            onTap: () {
              Navigator.pop(context);
              _showConfirmDialog(
                title: 'Delete Community',
                message: 'Delete ##${community['name']}? All posts will be lost.',
                onConfirm: () => _performAction(action: 'delete_community', targetType: 'community', targetId: community['id']),
              );
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showMemeMenu(Map<String, dynamic> meme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Post Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Post'),
            onTap: () {
              Navigator.pop(context);
              _showConfirmDialog(
                title: 'Delete Post',
                message: 'Delete this post?',
                onConfirm: () => _performAction(action: 'delete_post', targetType: 'post', targetId: meme['id']),
              );
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showConfirmDialog({required String title, required String message, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); onConfirm(); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
  }

  void _openCommunityPosts(Map<String, dynamic> community) {
    _selectedCommunity = community;
    _loadCommunityMemes(community['id']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: Text('Posts in ##${community['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _isLoadingCommunityMemes
                      ? const Center(child: CircularProgressIndicator())
                      : _communityMemes.isEmpty
                          ? const Center(child: Text('No posts in this community'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _communityMemes.length,
                              itemBuilder: (_, index) {
                                final meme = _communityMemes[index];
                                return GestureDetector(
                                  onLongPress: () => _showMemeMenu(meme),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('@${meme['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          if (meme['meme_text'] != null && meme['meme_text'].toString().isNotEmpty)
                                            Padding(padding: const EdgeInsets.only(top: 8), child: Text(meme['meme_text'])),
                                          if (meme['meme_image_url'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Image.network(meme['meme_image_url'], height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 150, color: Colors.grey.shade800)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _selectedCommunity = null;
      _communityMemes = [];
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
    } catch (_) {
      return '';
    }
  }

  String _getReasonIcon(String reason) {
    switch (reason) {
      case 'spam': return '📢';
      case 'advertising': return '📱';
      case 'nsfw': return '🔞';
      case 'harassment': return '😤';
      default: return '⚠️';
    }
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Container(
          color: Colors.grey.shade900,
          child: TabBar(
            controller: _reportsTabController,
            indicatorColor: _accentColor,
            labelColor: _accentColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: 'Posts Reports'), Tab(text: 'Messages Reports')],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade800,
            ),
            onChanged: (value) {
              if (_reportsTabController.index == 0) {
                _searchPostsReports = value;
                _loadPostsReports();
              } else {
                _searchMessagesReports = value;
                _loadMessagesReports();
              }
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _reportsTabController,
            children: [
              _isLoadingPostsReports
                  ? const Center(child: CircularProgressIndicator())
                  : _postsReports.isEmpty
                      ? const Center(child: Text('No reports'))
                      : ListView.builder(
                          itemCount: _postsReports.length,
                          itemBuilder: (_, index) {
                            final report = _postsReports[index];
                            return GestureDetector(
                              onLongPress: () => _showPostReportMenu(report),
                              child: Card(
                                margin: const EdgeInsets.all(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('${_getReasonIcon(report['reason'])} ${report['reason']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Spacer(),
                                          Text(_formatDate(report['reported_at']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('@${report['username']}', style: TextStyle(color: _accentColor)),
                                      if (report['community_name'] != null) Text('##${report['community_name']}', style: TextStyle(color: _accentColor.withOpacity(0.7))),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
                                        child: Text(report['meme_text'] ?? '[No text]'),
                                      ),
                                      if (report['meme_image_url'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Image.network(report['meme_image_url'], height: 100, width: double.infinity, fit: BoxFit.cover),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              _isLoadingMessagesReports
                  ? const Center(child: CircularProgressIndicator())
                  : _messagesReports.isEmpty
                      ? const Center(child: Text('No reports'))
                      : ListView.builder(
                          itemCount: _messagesReports.length,
                          itemBuilder: (_, index) {
                            final report = _messagesReports[index];
                            return GestureDetector(
                              onLongPress: () => _showMessageReportMenu(report),
                              child: Card(
                                margin: const EdgeInsets.all(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('${_getReasonIcon(report['reason'])} ${report['reason']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Spacer(),
                                          Text(_formatDate(report['reported_at']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('From: @${report['username']}', style: TextStyle(color: _accentColor)),
                                      Text('To: @${report['receiver_username']}', style: const TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
                                        child: Text(report['message_text'] ?? '[No text]'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade800,
            ),
            onChanged: (value) {
              _searchUsers = value;
              _loadUsers();
            },
          ),
        ),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, index) {
                        final user = _users[index];
                        return GestureDetector(
                          onLongPress: () => _showUserMenu(user),
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('@${user['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      if (user['admin'] == 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                          child: const Text('ADMIN', style: TextStyle(fontSize: 10, color: Colors.white)),
                                        ),
                                      if (user['banned'] == 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                                          child: const Text('BANNED', style: TextStyle(fontSize: 10, color: Colors.white)),
                                        ),
                                    ],
                                  ),
                                  Text(user['display_name'] ?? user['username']),
                                  Text(user['email'] ?? 'No email', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text('Views: ${user['memes_viewed'] ?? 0} • Joined: ${_formatDate(user['created_at'])}', style: const TextStyle(fontSize: 12)),
                                  if (user['bio'] != null && user['bio'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(user['bio'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCommunitiesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search communities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade800,
            ),
            onChanged: (value) {
              _searchCommunities = value;
              _loadCommunities();
            },
          ),
        ),
        Expanded(
          child: _isLoadingCommunities
              ? const Center(child: CircularProgressIndicator())
              : _communities.isEmpty
                  ? const Center(child: Text('No communities found'))
                  : ListView.builder(
                      itemCount: _communities.length,
                      itemBuilder: (_, index) {
                        final community = _communities[index];
                        return GestureDetector(
                          onTap: () => _openCommunityPosts(community),
                          onLongPress: () => _showCommunityMenu(community),
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('##${community['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (community['description'] != null && community['description'].isNotEmpty)
                                    Text(community['description'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text('Created by: @${community['creator_username']}', style: TextStyle(color: _accentColor)),
                                  Text('Members: ${community['members_count'] ?? 0} • Posts: ${community['memes_count'] ?? 0}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Reports'), Tab(text: 'Users'), Tab(text: 'Communities')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReportsTab(), _buildUsersTab(), _buildCommunitiesTab()],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportsTabController.dispose();
    super.dispose();
  }
}