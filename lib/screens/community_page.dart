import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'linking.dart';
import 'showprofile_page.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/image_viewer.dart';
import 'comments_page.dart';

class CommunityPage extends StatefulWidget {
  final int userId;
  final String username;
  final int communityId;
  final String communityName;

  const CommunityPage({
    super.key,
    required this.userId,
    required this.username,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<Map<String, dynamic>> _memes = [];
  Map<String, dynamic>? _communityInfo;
  bool _isLoading = true;
  bool _isJoining = false;
  bool _isMember = false;
  bool _isCreator = false;
  late MentionLinkifier _linkifier;
  final ImagePicker _picker = ImagePicker();
  Color _accentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadAccentColor();
  }

  Future<void> _loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getString('accent_color');
    if (savedColor != null && mounted) {
      setState(() {
        _accentColor = Color(int.parse(savedColor));
        // Инициализируем linkifier после загрузки цвета
        _linkifier = MentionLinkifier(
          userId: widget.userId,
          username: widget.username,
          context: context,
        );
        _loadCommunityData();
      });
    } else {
      _linkifier = MentionLinkifier(
        userId: widget.userId,
        username: widget.username,
        context: context,
      );
      _loadCommunityData();
    }
  }

  Future<void> _loadCommunityData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadCommunityInfo(),
      _loadCommunityMemes(),
      _checkMembership(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadCommunityInfo() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_community_info.php?community_id=${widget.communityId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _communityInfo = data['community'];
          _isCreator = _communityInfo?['created_by'] == widget.userId;
        });
      }
    } catch (e) {
      debugPrint('Error loading community info: $e');
    }
  }

  Future<void> _loadCommunityMemes() async {
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
        setState(() { _memes = memes; });
      }
    } catch (e) {
      debugPrint('Error loading community memes: $e');
    }
  }

  Future<void> _checkMembership() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/check_membership.php?user_id=${widget.userId}&community_id=${widget.communityId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _isMember = data['is_member'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error checking membership: $e');
    }
  }

  Future<void> _joinCommunity() async {
    setState(() => _isJoining = true);
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/join_community.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'community_id': widget.communityId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _isMember = true;
          _isJoining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined community!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to join')),
        );
      }
    } catch (e) {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _leaveCommunity() async {
    setState(() => _isJoining = true);
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/leave_community.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'community_id': widget.communityId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _isMember = false;
          _isJoining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left community'), backgroundColor: Colors.orange),
        );
      } else {
        setState(() => _isJoining = false);
      }
    } catch (e) {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
      );
    }
  }

  void _editCommunity() {
    final TextEditingController nameController = TextEditingController(text: widget.communityName);
    final TextEditingController descController = TextEditingController(text: _communityInfo?['description'] ?? '');
    final ImagePicker picker = ImagePicker();
    String? avatarBase64 = _communityInfo?['avatar'];
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
                    helperText: 'Only letters, numbers, underscore and hyphen',
                  ),
                  enabled: !isSaving,
                  onChanged: (value) {
                    final regex = RegExp(r'^[a-zA-Z0-9_-]*$');
                    if (!regex.hasMatch(value) && value.isNotEmpty) {
                      setSheetState(() {
                        nameController.value = TextEditingValue(
                          text: value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), ''),
                          selection: TextSelection.collapsed(offset: value.length),
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this community about?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                  enabled: !isSaving,
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
                              'community_id': widget.communityId,
                              'name': name,
                              'description': descController.text.trim(),
                              'avatar': avatarBase64,
                            }),
                            headers: {'Content-Type': 'application/json'},
                          );
                          final data = jsonDecode(response.body);
                          if (data['success'] == true) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Community updated!'), backgroundColor: Colors.green),
                            );
                            _loadCommunityData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to update')));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
                        } finally {
                          if (mounted) setSheetState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.white),
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

  void _openUserProfile(int profileUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowProfilePage(
          userId: widget.userId,
          profileUserId: profileUserId,
          currentUsername: widget.username,
        ),
      ),
    );
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

  void _showCommentsPage(Map<String, dynamic> meme) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CommentsPage(
          userId: widget.userId,
          username: widget.username,
          post: meme,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    ).then((_) {
      _loadCommunityData();
    });
  }

  void _openImageViewer(String imagePath) {
    String imageUrl;
    if (imagePath.startsWith('data:image') || imagePath.startsWith('/9j/')) {
      imageUrl = imagePath;
    } else if (imagePath.startsWith('http')) {
      imageUrl = imagePath;
    } else {
      imageUrl = 'https://listo4ek.tech/$imagePath';
    }
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

  Future<void> _createPostInCommunity() async {
    final TextEditingController textController = TextEditingController();
    String? selectedImageBase64;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Create Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setSheetState(() => selectedImageBase64 = base64Encode(bytes));
                }
              },
              child: Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade600)),
                child: selectedImageBase64 != null
                    ? Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(selectedImageBase64!), width: double.infinity, fit: BoxFit.cover)),
                        Positioned(top: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setSheetState(() => selectedImageBase64 = null)))),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey.shade500),
                        const SizedBox(height: 8), Text('Tap to add image', style: TextStyle(color: Colors.grey.shade500)),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: textController, decoration: const InputDecoration(hintText: 'Write something...', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 16),
            Row(children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  if (textController.text.isEmpty && selectedImageBase64 == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write something or add an image')));
                    return;
                  }
                  Navigator.pop(context);
                  final postResponse = await http.post(
                    Uri.parse('https://listo4ek.tech/create_post.php'),
                    body: jsonEncode({
                      'user_id': widget.userId,
                      'community_id': widget.communityId,
                      'text': textController.text,
                      'image': selectedImageBase64,
                    }),
                    headers: {'Content-Type': 'application/json'},
                  );
                  if (jsonDecode(postResponse.body)['success'] == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created!'), backgroundColor: Colors.green));
                    _loadCommunityMemes();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonDecode(postResponse.body)['error'] ?? 'Failed')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.white),
                child: const Text('Post'),
              ),
            ]),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
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
          GestureDetector(onTap: () => _showCommentsPage(meme), child: Row(children: [
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          SizedBox(
            width: avatarWidth,
            child: GestureDetector(
              onTap: () => _openUserProfile(meme['user_id']),
              child: Center(
                child: AppAvatar(base64Image: avatarBase64, radius: 20),
              ),
            ),
          ),
          Flexible(child: postCard),
          SizedBox(width: screenWidth * (1 - 1/7 - 5/7)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _communityInfo;
    final memberCount = info?['members_count'] ?? 0;
    final postCount = _memes.length;
    final description = info?['description'] ?? '';
    final avatar = info?['avatar'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createPostInCommunity,
            tooltip: 'Create post',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommunityData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade600, width: 2),
                          ),
                          child: AppAvatar(
                            base64Image: avatar,
                            radius: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '##${widget.communityName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatColumn(_formatNumber(memberCount), 'members'),
                            const SizedBox(width: 32),
                            _buildStatColumn(_formatNumber(postCount), 'posts'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _linkifier.buildRichText(description),
                        ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _isCreator
                            ? OutlinedButton.icon(
                                onPressed: _editCommunity,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit Community'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _accentColor),
                                  foregroundColor: _accentColor,
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                            : (_isMember
                                ? OutlinedButton(
                                    onPressed: _isJoining ? null : _leaveCommunity,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: _accentColor),
                                      foregroundColor: _accentColor,
                                      minimumSize: const Size(double.infinity, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isJoining
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Subscribed'),
                                  )
                                : ElevatedButton(
                                    onPressed: _isJoining ? null : _joinCommunity,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accentColor,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isJoining
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Join Community'),
                                  )),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],
                  ),
                ),
                if (_memes.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No memes in this community yet'),
                          SizedBox(height: 8),
                          Text('Be the first to post!'),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPostItem(_memes[index]),
                      childCount: _memes.length,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}