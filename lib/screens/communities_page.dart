import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'linking.dart';
import '../widgets/avatar_widget.dart';

class CommunitiesPage extends StatefulWidget {
  final int userId;
  final String username;

  const CommunitiesPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _myCommunities = [];
  List<Map<String, dynamic>> _recommendedCommunities = [];
  List<Map<String, dynamic>> _filteredCommunities = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadMyCommunities();
    await _loadRecommendedCommunities();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMyCommunities() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_user_communities.php?user_id=${widget.userId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _myCommunities = List<Map<String, dynamic>>.from(data['communities']);
          _filteredCommunities = List.from(_myCommunities);
        });
      }
    } catch (e) {
      debugPrint('Error loading my communities: $e');
    }
  }

  Future<void> _loadRecommendedCommunities() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_recommended_communities.php?user_id=${widget.userId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _recommendedCommunities = List<Map<String, dynamic>>.from(data['communities']);
        });
      }
    } catch (e) {
      debugPrint('Error loading recommended communities: $e');
    }
  }

  Future<void> _joinCommunity(int communityId) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/join_community.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'community_id': communityId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined community!'), backgroundColor: Colors.green),
        );
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to join community')),
        );
      }
    } catch (e) {
      debugPrint('Error joining community: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error. Please try again.')),
        );
      }
    }
  }

  Future<void> _leaveCommunity(int communityId) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/leave_community.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'community_id': communityId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left community'), backgroundColor: Colors.orange),
        );
        await _loadData();
      }
    } catch (e) {
      debugPrint('Error leaving community: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error. Please try again.')),
        );
      }
    }
  }

  void _filterCommunities(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCommunities = List.from(_myCommunities);
      } else {
        _filteredCommunities = _myCommunities.where((c) {
          final name = c['name'].toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _openCommunityFeed(Map<String, dynamic> community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityFeedPage(
          userId: widget.userId,
          username: widget.username,
          communityId: community['id'],
          communityName: community['name'],
        ),
      ),
    );
  }

  void _showCreateCommunitySheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final ImagePicker picker = ImagePicker();
    String? avatarBase64;
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Community',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    try {
                      if (kIsWeb) {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.first.bytes != null) {
                          setSheetState(() {
                            avatarBase64 = base64Encode(result.files.first.bytes!);
                          });
                        }
                      } else {
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setSheetState(() {
                            avatarBase64 = base64Encode(bytes);
                          });
                        }
                      }
                    } catch (e) {
                      debugPrint('Error picking avatar: $e');
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: avatarBase64 != null
                        ? MemoryImage(base64Decode(avatarBase64!))
                        : const AssetImage('assets/default.png'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Community name',
                    hintText: 'my_community',
                    prefixText: '##',
                    prefixStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  enabled: !isCreating,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What is this community about?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                  enabled: !isCreating,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: isCreating ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isCreating
                          ? null
                          : () async {
                              final rawName = nameController.text.trim();
                              final name = rawName.startsWith('##') ? rawName.substring(2) : rawName;
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a name')),
                                );
                                return;
                              }
                              setSheetState(() => isCreating = true);
                              try {
                                final response = await http.post(
                                  Uri.parse('https://listo4ek.tech/create_community.php'),
                                  body: jsonEncode({
                                    'user_id': widget.userId,
                                    'name': name,
                                    'description': descController.text.trim(),
                                    'avatar': avatarBase64,
                                  }),
                                  headers: {'Content-Type': 'application/json'},
                                );
                                final data = jsonDecode(response.body);
                                if (data['success'] == true) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Community created!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(data['error'] ?? 'Failed to create')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Connection error')),
                                );
                              } finally {
                                if (mounted) setSheetState(() => isCreating = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editCommunity(Map<String, dynamic> community) {
    final TextEditingController nameController = TextEditingController(text: community['name']);
    final TextEditingController descController = TextEditingController(text: community['description'] ?? '');
    final ImagePicker picker = ImagePicker();
    String? avatarBase64 = community['avatar'];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Community', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    try {
                      if (kIsWeb) {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.first.bytes != null) {
                          setSheetState(() => avatarBase64 = base64Encode(result.files.first.bytes!));
                        }
                      } else {
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setSheetState(() => avatarBase64 = base64Encode(bytes));
                        }
                      }
                    } catch (e) {
                      debugPrint('Error picking avatar: $e');
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: avatarBase64 != null && avatarBase64!.isNotEmpty
                            ? MemoryImage(base64Decode(avatarBase64!))
                            : const AssetImage('assets/default.png'),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: CircleAvatar(
                          radius: 14, backgroundColor: Colors.blue,
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Community name',
                    prefixText: '##',
                    prefixStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  enabled: !isSaving,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this community about?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3, enabled: !isSaving,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final rawName = nameController.text.trim();
                        final name = rawName.startsWith('##') ? rawName.substring(2) : rawName;
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                          return;
                        }
                        setSheetState(() => isSaving = true);
                        try {
                          final response = await http.post(
                            Uri.parse('https://listo4ek.tech/update_community.php'),
                            body: jsonEncode({
                              'community_id': community['id'], 'name': name,
                              'description': descController.text.trim(), 'avatar': avatarBase64,
                            }),
                            headers: {'Content-Type': 'application/json'},
                          );
                          final data = jsonDecode(response.body);
                          if (data['success'] == true) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Community updated!'), backgroundColor: Colors.green),
                            );
                            _loadData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to update')));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
                        } finally {
                          if (mounted) setSheetState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteCommunity(Map<String, dynamic> community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Community'),
        content: Text('Are you sure you want to delete "${community['name']}" and all its memes? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteCommunity(community['id']); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommunity(int communityId) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/delete_community.php'),
        body: jsonEncode({'community_id': communityId, 'user_id': widget.userId}),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Community deleted'), backgroundColor: Colors.green));
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to delete')));
      }
    } catch (e) {
      debugPrint('Error deleting community: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.add), tooltip: 'Create community', onPressed: _showCreateCommunitySheet)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search communities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _filterCommunities(''); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true, fillColor: Colors.grey.shade800,
              ),
              onChanged: _filterCommunities,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  if (_filteredCommunities.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.all(16), child: Text('My Communities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    ..._filteredCommunities.map((community) => ListTile(
                      leading: AppAvatar(
                        base64Image: community['avatar'],
                        radius: 20,
                      ),
                      title: Text(community['name']),
                      subtitle: Text(community['description'] ?? 'No description'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (community['created_by'] == widget.userId) ...[
                            IconButton(icon: const Icon(Icons.edit, size: 18), color: Colors.grey, tooltip: 'Edit community', onPressed: () => _editCommunity(community)),
                            IconButton(icon: const Icon(Icons.delete, size: 18), color: Colors.red.shade400, tooltip: 'Delete community', onPressed: () => _confirmDeleteCommunity(community)),
                          ],
                          OutlinedButton(
                            onPressed: () => _leaveCommunity(community['id']),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade400), foregroundColor: Colors.red.shade400),
                            child: const Text('Leave'),
                          ),
                        ],
                      ),
                      onTap: () => _openCommunityFeed(community),
                    )),
                    const Divider(),
                  ],
                  if (_recommendedCommunities.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.all(16), child: Text('Recommended', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    ..._recommendedCommunities.map((community) => ListTile(
                      leading: AppAvatar(
                        base64Image: community['avatar'],
                        radius: 20,
                      ),
                      title: Text(community['name']),
                      subtitle: Text(community['description'] ?? 'No description'),
                      trailing: OutlinedButton(
                        onPressed: () => _joinCommunity(community['id']),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.green.shade400), foregroundColor: Colors.green.shade400),
                        child: const Text('Join'),
                      ),
                      onTap: () => _openCommunityFeed(community),
                    )),
                  ],
                  if (_filteredCommunities.isEmpty && _searchQuery.isNotEmpty)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No communities found'))),
                  if (_myCommunities.isEmpty && _recommendedCommunities.isEmpty)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: Column(children: [
                      Icon(Icons.group_off, size: 64, color: Colors.grey), SizedBox(height: 16),
                      Text('No communities available'), SizedBox(height: 8), Text('Create one or join existing!'),
                    ]))),
                ],
              ),
            ),
    );
  }
}

// Страница ленты сообщества
class CommunityFeedPage extends StatefulWidget {
  final int userId;
  final String username;
  final int communityId;
  final String communityName;

  const CommunityFeedPage({super.key, required this.userId, required this.username, required this.communityId, required this.communityName});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  List<Map<String, dynamic>> _memes = [];
  bool _isLoading = true;
  late MentionLinkifier _linkifier;

  @override
  void initState() {
    super.initState();
    _linkifier = MentionLinkifier(userId: widget.userId, username: widget.username, context: context);
    _loadCommunityMemes();
  }

  Future<void> _loadCommunityMemes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://listo4ek.tech/get_community_memes.php?community_id=${widget.communityId}'));
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        final memes = List<Map<String, dynamic>>.from(data['memes']);
        for (var meme in memes) {
          try {
            final reactionCheck = await http.get(Uri.parse('https://listo4ek.tech/check_reaction.php?user_id=${widget.userId}&meme_id=${meme['id']}'));
            if (reactionCheck.statusCode == 200) {
              meme['has_user_reacted'] = jsonDecode(reactionCheck.body)['has_reacted'] ?? false;
            } else {
              meme['has_user_reacted'] = false;
            }
          } catch (_) { meme['has_user_reacted'] = false; }
          meme['comments_count'] = 0;
          meme['comments'] = [];
          meme['comments_loaded'] = false;
          meme['comments_total'] = 0;
        }
        setState(() { _memes = memes; _isLoading = false; });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading community memes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReaction(int memeId, bool hasUserReacted) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/toggle_reaction.php'),
        body: jsonEncode({'message_id': memeId, 'user_id': widget.userId, 'action': hasUserReacted ? 'remove' : 'add'}),
        headers: {'Content-Type': 'application/json'},
      );
      if (jsonDecode(response.body)['success'] == true && mounted) {
        setState(() {
          for (var m in _memes) {
            if (m['id'] == memeId) {
              m['reactions'] = (m['reactions'] ?? 0) + (hasUserReacted ? -1 : 1);
              m['has_user_reacted'] = !hasUserReacted;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hasUserReacted ? '❤️ Reaction removed' : '❤️ You liked this!'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
      }
    } catch (e) { debugPrint('Error toggling reaction: $e'); }
  }

  void _showPostMenu(Map<String, dynamic> meme) {
    final isOwn = meme['user_id'] == widget.userId;
    final isFav = meme['is_favorite'] == true;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!isFav)
            ListTile(leading: const Icon(Icons.bookmark_border, color: Colors.orange), title: const Text('Save to Favorites'),
              onTap: () { Navigator.pop(context); _addToFavorites(meme['id']); }),
          if (isFav)
            const ListTile(leading: Icon(Icons.bookmark, color: Colors.orange), title: Text('Saved to Favorites'), enabled: false),
          const Divider(),
          ListTile(
            leading: Icon(Icons.favorite_border, color: meme['has_user_reacted'] == true ? Colors.red : Colors.grey),
            title: Text(meme['has_user_reacted'] == true ? 'Remove Like' : 'Like this Post'),
            onTap: () { Navigator.pop(context); _toggleReaction(meme['id'], meme['has_user_reacted'] == true); },
          ),
          const Divider(),
          if (isOwn)
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(context); _deletePost(meme['id']); }),
          ListTile(leading: const Icon(Icons.flag, color: Colors.orange), title: const Text('Report', style: TextStyle(color: Colors.orange)),
            onTap: () { Navigator.pop(context); _showReportMenu(meme['id']); }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Future<void> _addToFavorites(int memeId) async {
    try {
      final resp = await http.post(Uri.parse('https://listo4ek.tech/add_favorite.php'),
        body: jsonEncode({'user_id': widget.userId, 'message_id': memeId}), headers: {'Content-Type': 'application/json'});
      if (jsonDecode(resp.body)['success'] == true && mounted) {
        setState(() { for (var m in _memes) { if (m['id'] == memeId) m['is_favorite'] = true; } });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to favorites ⭐'), backgroundColor: Colors.green));
      }
    } catch (e) { debugPrint('Error adding to favorites: $e'); }
  }

  Future<void> _deletePost(int memeId) async {
    try {
      final resp = await http.post(Uri.parse('https://listo4ek.tech/delete_meme.php'),
        body: jsonEncode({'user_id': widget.userId, 'message_id': memeId}), headers: {'Content-Type': 'application/json'});
      if (jsonDecode(resp.body)['success'] == true && mounted) {
        setState(() { _memes.removeWhere((m) => m['id'] == memeId); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted'), backgroundColor: Colors.green));
      }
    } catch (e) { debugPrint('Error deleting post: $e'); }
  }

  void _showReportMenu(int memeId) {
    final reasons = {'spam': '📢 Spam', 'advertising': '📱 Advertising', 'nsfw': '🔞 NSFW Content', 'harassment': '😤 Harassment', 'other': '⚠️ Other Violations'};
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Report this post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(),
          ...reasons.entries.map((e) => ListTile(leading: const Icon(Icons.flag, color: Colors.orange), title: Text(e.value),
            onTap: () { Navigator.pop(context); _submitReport(memeId, e.key); })),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Future<void> _submitReport(int memeId, String reason) async {
    try {
      await http.post(Uri.parse('https://listo4ek.tech/report_meme.php'),
        body: jsonEncode({'message_id': memeId, 'user_id': widget.userId, 'reason': reason}), headers: {'Content-Type': 'application/json'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted'), backgroundColor: Colors.green));
    } catch (e) { debugPrint('Error reporting: $e'); }
  }

  Future<void> _loadComments(int memeId, {bool loadMore = false}) async {
    final index = _memes.indexWhere((m) => m['id'] == memeId);
    if (index == -1) return;
    final currentComments = List<Map<String, dynamic>>.from(_memes[index]['comments'] ?? []);
    final offset = loadMore ? currentComments.length : 0;
    try {
      final response = await http.get(Uri.parse('https://listo4ek.tech/get_comments.php?meme_id=$memeId&limit=5&offset=$offset'));
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          if (loadMore) {
            _memes[index]['comments'].addAll(List<Map<String, dynamic>>.from(data['comments']));
          } else {
            _memes[index]['comments'] = List<Map<String, dynamic>>.from(data['comments']);
          }
          _memes[index]['comments_total'] = data['total'];
          _memes[index]['comments_count'] = data['total'];
          _memes[index]['comments_loaded'] = true;
        });
      }
    } catch (e) { debugPrint('Error loading comments: $e'); }
  }

  Future<void> _addComment(int memeId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/add_comment.php'),
        body: jsonEncode({'user_id': widget.userId, 'meme_id': memeId, 'comment_text': text}),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        final index = _memes.indexWhere((m) => m['id'] == memeId);
        if (index != -1) {
          setState(() {
            _memes[index]['comments'].add(data['comment']);
            _memes[index]['comments_count'] = (_memes[index]['comments_count'] ?? 0) + 1;
            _memes[index]['comments_total'] = (_memes[index]['comments_total'] ?? 0) + 1;
          });
        }
      }
    } catch (e) { debugPrint('Error adding comment: $e'); }
  }

  void _showCommentsSheet(Map<String, dynamic> meme) {
    final memeId = meme['id'];
    if (meme['comments_loaded'] != true) _loadComments(memeId);
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final m = _memes.firstWhere((m) => m['id'] == memeId);
          final comments = List<Map<String, dynamic>>.from(m['comments'] ?? []);
          final total = m['comments_total'] ?? 0;
          return DraggableScrollableSheet(
            initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
            builder: (context, scrollController) => Column(children: [
              Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ])),
              const Divider(height: 1),
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('No comments yet'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length + (total > comments.length ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i < comments.length) {
                            final c = comments[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(width: 2, height: 36, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                AppAvatar(base64Image: c['avatar'], radius: 12),
                                const SizedBox(width: 8),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['display_name'] ?? c['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(c['comment_text'], style: const TextStyle(fontSize: 13)),
                                ])),
                              ]),
                            );
                          } else {
                            return TextButton(
                              onPressed: () { _loadComments(memeId, loadMore: true); setSheetState(() {}); },
                              child: const Text('— show more —', style: TextStyle(color: Colors.blue)),
                            );
                          }
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(padding: const EdgeInsets.all(8), child: Row(children: [
                Expanded(child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    filled: true, fillColor: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                )),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20, backgroundColor: Colors.blue.shade700,
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        _addComment(memeId, controller.text);
                        controller.clear();
                        setSheetState(() {});
                      }
                    },
                  ),
                ),
              ])),
            ]),
          );
        },
      ),
    );
  }

  void _openImageViewer(String imagePath) {
    final imageUrl = imagePath.startsWith('http') ? imagePath : 'https://listo4ek.tech/$imagePath';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  void _trackView(int memeId) async {
    try { await http.get(Uri.parse('https://listo4ek.tech/track_view.php?user_id=${widget.userId}&meme_id=$memeId')); } catch (_) {}
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    try { final d = DateTime.parse(dt); final diff = DateTime.now().difference(d);
      if (diff.inDays > 0) return '${diff.inDays}d ago'; if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago'; return 'just now'; } catch (_) { return ''; }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n/1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n/1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildPostImage(String imagePath) {
    final imageUrl = imagePath.startsWith('http') ? imagePath : 'https://listo4ek.tech/$imagePath';
    return GestureDetector(
      onTap: () => _openImageViewer(imagePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(height: 200, color: Colors.grey.shade800, child: const Center(child: CircularProgressIndicator()));
          },
          errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade800, child: const Center(child: Icon(Icons.broken_image))),
        ),
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> meme) {
    _trackView(meme['id']);
    final screenWidth = MediaQuery.of(context).size.width;
    final hasImage = meme['meme_image'] != null && meme['meme_image'].toString().isNotEmpty;
    final username = '@${meme['username']}';
    final text = meme['meme_text'];
    final reactions = meme['reactions'] ?? 0;
    final views = meme['views_count'] ?? 0;
    final commentsCount = meme['comments_count'] ?? 0;
    final time = _formatDate(meme['created_at']);
    final avatarBase64 = meme['user_avatar'];
    final avatarWidth = screenWidth * 1 / 7;

    Widget postCard = Container(
      constraints: BoxConstraints(maxWidth: screenWidth * 5 / 7),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _linkifier.buildRichText(username),
        if (hasImage) ...[const SizedBox(height: 6), _buildPostImage(meme['meme_image'])],
        if (text != null && text.toString().isNotEmpty)
          Padding(padding: EdgeInsets.only(top: hasImage ? 6 : 4, bottom: 4), child: _linkifier.buildRichText(text.toString())),
        const SizedBox(height: 4),
        Row(children: [
          GestureDetector(onTap: () => _toggleReaction(meme['id'], meme['has_user_reacted'] == true), child: Row(children: [
            Icon(meme['has_user_reacted'] == true ? Icons.favorite : Icons.favorite_border, size: 16, color: meme['has_user_reacted'] == true ? Colors.red : Colors.grey),
            const SizedBox(width: 2), Text(_formatNumber(reactions), style: TextStyle(fontSize: 11, color: meme['has_user_reacted'] == true ? Colors.red : Colors.grey)),
          ])),
          const SizedBox(width: 16),
          GestureDetector(onTap: () => _showCommentsSheet(meme), child: Row(children: [
            const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 2), Text(_formatNumber(commentsCount), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
          const Spacer(),
          Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(width: 8), Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 2), Text('$views', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ]),
      ]),
    );

    return GestureDetector(
      onLongPress: () => _showPostMenu(meme),
      child: Container(margin: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        SizedBox(width: avatarWidth, child: Center(child: AppAvatar(base64Image: avatarBase64, radius: 20))),
        Flexible(child: postCard),
        SizedBox(width: screenWidth * (1 - 1/7 - 5/7)),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.communityName), centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCommunityMemes, tooltip: 'Refresh')]),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
          : _memes.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey), const SizedBox(height: 16),
                  const Text('No memes in this community yet'), const SizedBox(height: 8),
                  ElevatedButton(onPressed: _loadCommunityMemes, child: const Text('Refresh'))]))
              : RefreshIndicator(onRefresh: _loadCommunityMemes,
                  child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: _memes.length, itemBuilder: (_, i) => _buildPostItem(_memes[i]))),
    );
  }
}

// ImageViewer
class ImageViewer extends StatefulWidget {
  final String imageUrl;
  const ImageViewer({super.key, required this.imageUrl});
  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  double _scale = 1.0, _previousScale = 1.0;
  Offset _offset = Offset.zero, _previousOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: Center(child: GestureDetector(
        onScaleStart: (d) { _previousScale = _scale; _previousOffset = _offset; },
        onScaleUpdate: (d) {
          setState(() {
            _scale = (_previousScale * d.scale).clamp(1.0, 5.0);
            if (_scale > 1.0) _offset = _previousOffset + d.focalPointDelta; else _offset = Offset.zero;
            _clampOffset();
          });
        },
        onDoubleTap: () => setState(() {
          if (_scale > 1.0) { _scale = 1.0; _offset = Offset.zero; } else { _scale = 3.0; _offset = Offset.zero; }
          _clampOffset();
        }),
        child: Transform(transform: Matrix4.identity()..translate(_offset.dx, _offset.dy)..scale(_scale),
          child: Center(child: Image.network(widget.imageUrl, fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
          ))),
      )),
    );
  }

  void _clampOffset() {
    final size = MediaQuery.of(context).size;
    final maxX = (size.width * (_scale - 1)) / 2, maxY = (size.height * (_scale - 1)) / 2;
    _offset = _scale <= 1.0 ? Offset.zero : Offset(_offset.dx.clamp(-maxX, maxX), _offset.dy.clamp(-maxY, maxY));
  }
}