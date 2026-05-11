import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'linking.dart';
import 'communities_page.dart';
import '../widgets/avatar_widget.dart';

class FeedPage extends StatefulWidget {
  final int userId;
  final String username;
  
  const FeedPage({super.key, required this.userId, required this.username});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<Map<String, dynamic>> _memes = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  late MentionLinkifier _linkifier;
  Color _myMessageColor = const Color(0xFF202040);

  @override
  void initState() {
    super.initState();
    _loadMyMessageColor();
    _linkifier = MentionLinkifier(userId: widget.userId, username: widget.username, context: context);
    _loadFeed();
  }

  Future<void> _loadMyMessageColor() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getString('my_message_color');
    if (c != null) setState(() => _myMessageColor = Color(int.parse(c)));
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
          content: Text(hasUserReacted ? '❤️ Reaction removed' : '❤️ You liked this!'), backgroundColor: Colors.green));
      }
    } catch (e) { debugPrint('Error toggling reaction: $e'); }
  }

  void _openImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(imageUrl: 'https://listo4ek.tech/$imageUrl'),
      ),
    );
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://listo4ek.tech/get_feed.php?user_id=${widget.userId}'));
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        final memes = List<Map<String, dynamic>>.from(data['memes']);
        for (var meme in memes) {
          try {
            final rc = await http.get(Uri.parse('https://listo4ek.tech/check_reaction.php?user_id=${widget.userId}&meme_id=${meme['id']}'));
            if (rc.statusCode == 200) meme['has_user_reacted'] = jsonDecode(rc.body)['has_reacted'] ?? false;
            else meme['has_user_reacted'] = false;
          } catch (_) { meme['has_user_reacted'] = false; }
          meme['comments_count'] = meme['comments_count'] ?? 0;
          meme['comments_total'] = meme['comments_count'] ?? 0;
          meme['comments'] = [];
          meme['comments_loaded'] = false;
        }
        setState(() { _memes.clear(); _memes.addAll(memes); });
      }
    } catch (e) { debugPrint('Error loading feed: $e'); }
    finally { if (mounted) setState(() => _isLoading = false); }
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
                  radius: 20, backgroundColor: _myMessageColor,
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

  bool _canEditPost(String? createdAt) {
    if (createdAt == null) return false;
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(created).inDays < 7;
    } catch (_) { return false; }
  }

  void _editPost(Map<String, dynamic> meme) {
    final TextEditingController textController = TextEditingController(text: meme['meme_text'] ?? '');
    String? selectedImageBase64;
    bool hasExistingImage = meme['meme_image'] != null && meme['meme_image'].toString().isNotEmpty;
    bool removeImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Edit Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Область фото
            GestureDetector(
              onTap: () async {
                if (!removeImage) {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setSheetState(() {
                      selectedImageBase64 = base64Encode(bytes);
                      removeImage = false;
                    });
                  }
                }
              },
              child: Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade600)),
                child: (selectedImageBase64 != null)
                    ? Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(selectedImageBase64!), width: double.infinity, fit: BoxFit.cover)),
                        Positioned(top: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setSheetState(() { selectedImageBase64 = null; })))),
                      ])
                    : (hasExistingImage && !removeImage)
                        ? Stack(children: [
                            // ИСПРАВЛЕНО: проверяем, не начинается ли URL уже с https://
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                meme['meme_image'].toString().startsWith('http') 
                                    ? meme['meme_image'].toString() 
                                    : 'https://listo4ek.tech/${meme['meme_image']}',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(height: 200, color: Colors.grey.shade800, child: const Center(child: CircularProgressIndicator()));
                                },
                                errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade800, child: const Center(child: Icon(Icons.broken_image))),
                              ),
                            ),
                            Positioned(top: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setSheetState(() { removeImage = true; })))),
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
                  Navigator.pop(context);
                  final postResponse = await http.post(
                    Uri.parse('https://listo4ek.tech/update_post.php'),
                    body: jsonEncode({
                      'post_id': meme['id'],
                      'user_id': widget.userId,
                      'text': textController.text,
                      'image': selectedImageBase64,
                      'remove_image': removeImage,
                    }),
                    headers: {'Content-Type': 'application/json'},
                  );
                  final data = jsonDecode(postResponse.body);
                  if (data['success'] == true && mounted) {
                    setState(() {
                      final index = _memes.indexWhere((m) => m['id'] == meme['id']);
                      if (index != -1) {
                        _memes[index]['meme_text'] = textController.text;
                        _memes[index]['meme_image'] = data['post']['meme_image'];
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated!'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to update')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _myMessageColor, foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ]),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  void _showPostMenu(Map<String, dynamic> meme) {
    final isOwn = meme['user_id'] == widget.userId;
    final isFav = meme['is_favorite'] == true;
    final canEdit = isOwn && _canEditPost(meme['created_at']);

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
          ListTile(leading: Icon(Icons.favorite_border, color: meme['has_user_reacted'] == true ? Colors.red : Colors.grey),
            title: Text(meme['has_user_reacted'] == true ? 'Remove Like' : 'Like this Post'),
            onTap: () { Navigator.pop(context); _toggleReaction(meme['id'], meme['has_user_reacted'] == true); }),
          const Divider(),
          if (canEdit)
            ListTile(leading: const Icon(Icons.edit, color: Colors.blue), title: const Text('Edit Post'),
              onTap: () { Navigator.pop(context); _editPost(meme); }),
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

  void _trackView(int memeId) async {
    try { await http.get(Uri.parse('https://listo4ek.tech/track_view.php?user_id=${widget.userId}&meme_id=$memeId')); } catch (_) {}
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    try { final d = DateTime.parse(dt); final diff = DateTime.now().difference(d);
      if (diff.inDays > 0) return '${diff.inDays}d'; if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m'; return 'now'; } catch (_) { return ''; }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n/1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n/1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Future<void> _createPost() async {
    final TextEditingController textController = TextEditingController();
    String? selectedCommunity;
    String? selectedImageBase64;
    
    final response = await http.get(Uri.parse('https://listo4ek.tech/get_user_communities.php?user_id=${widget.userId}'));
    final data = jsonDecode(response.body);
    final communities = data['communities'] ?? [];
    if (!mounted) return;
    
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
            DropdownButtonFormField<String>(
              value: selectedCommunity, decoration: const InputDecoration(labelText: 'Community (optional)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('No community (public post)')),
                ...communities.map((c) => DropdownMenuItem<String>(value: c['id'].toString(), child: Text(c['name']))),
              ],
              onChanged: (v) => setSheetState(() => selectedCommunity = v),
            ),
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
                      'community_id': selectedCommunity != null ? int.parse(selectedCommunity!) : null,
                      'text': textController.text,
                      'image': selectedImageBase64,
                    }),
                    headers: {'Content-Type': 'application/json'},
                  );
                  if (jsonDecode(postResponse.body)['success'] == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created!'), backgroundColor: Colors.green));
                    _loadFeed();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonDecode(postResponse.body)['error'] ?? 'Failed')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _myMessageColor, foregroundColor: Colors.white),
                child: const Text('Post'),
              ),
            ]),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
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
    final hasUserReacted = meme['has_user_reacted'] == true;
    final community = meme['community_name'] ?? 'Public';
    final communityId = meme['community_id'];
    final username = '@${meme['username']}';
    final text = meme['meme_text'];
    final reactions = meme['reactions'] ?? 0;
    final views = meme['views_count'] ?? 0;
    final commentsCount = meme['comments_count'] ?? 0;
    final time = _formatDate(meme['created_at']);
    final avatarBase64 = meme['user_avatar'];
    final avatarWidth = screenWidth * 1 / 7;
    final double cardWidth = screenWidth * 5 / 7;

    Widget postCard = Container(
      constraints: BoxConstraints(maxWidth: cardWidth),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          GestureDetector(
            onTap: () { if (communityId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityFeedPage(userId: widget.userId, username: widget.username, communityId: communityId, communityName: community))); },
            child: Text('##$community', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue, decoration: TextDecoration.underline)),
          ),
          const SizedBox(width: 6),
          _linkifier.buildRichText(username),
        ]),
        if (hasImage) ...[const SizedBox(height: 6), _buildPostImage(meme['meme_image'])],
        if (text != null && text.toString().isNotEmpty)
          Padding(padding: EdgeInsets.only(top: hasImage ? 6 : 4, bottom: 4), child: _linkifier.buildRichText(text.toString())),
        const SizedBox(height: 4),
        Row(children: [
          GestureDetector(onTap: () => _toggleReaction(meme['id'], hasUserReacted), child: Row(children: [
            Icon(hasUserReacted ? Icons.favorite : Icons.favorite_border, size: 16, color: hasUserReacted ? Colors.red : Colors.grey),
            const SizedBox(width: 2), Text(_formatNumber(reactions), style: TextStyle(fontSize: 11, color: hasUserReacted ? Colors.red : Colors.grey)),
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
      appBar: AppBar(title: const Text('Feed'), centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _createPost, tooltip: 'Create post')]),
      body: RefreshIndicator(onRefresh: _loadFeed,
        child: _isLoading ? const Center(child: CircularProgressIndicator())
            : _memes.isEmpty ? const Center(child: Text('No posts yet'))
                : ListView.builder(padding: const EdgeInsets.all(8), itemCount: _memes.length, itemBuilder: (_, i) => _buildPostItem(_memes[i]))),
    );
  }
}

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
          child: Center(child: Image.network(widget.imageUrl, fit: BoxFit.contain, loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }))),
      )),
    );
  }

  void _clampOffset() {
    final size = MediaQuery.of(context).size;
    final maxX = (size.width * (_scale - 1)) / 2, maxY = (size.height * (_scale - 1)) / 2;
    _offset = _scale <= 1.0 ? Offset.zero : Offset(_offset.dx.clamp(-maxX, maxX), _offset.dy.clamp(-maxY, maxY));
  }
}