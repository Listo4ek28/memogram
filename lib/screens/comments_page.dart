import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'linking.dart';
import 'showprofile_page.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/image_viewer.dart';

class CommentsPage extends StatefulWidget {
  final int userId;
  final String username;
  final Map<String, dynamic> post;

  const CommentsPage({
    super.key,
    required this.userId,
    required this.username,
    required this.post,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  int _totalComments = 0;
  bool _hasMore = true;
  
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  late MentionLinkifier _linkifier;
  Color _accentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadAccentColor();
    _linkifier = MentionLinkifier(
      userId: widget.userId,
      username: widget.username,
      context: context,
    );
    
    // Анимация для появления страницы справа
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    _loadComments();
    
    // Добавляем слушатель для бесконечной загрузки
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreComments();
      }
    });
  }

  Future<void> _loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getString('accent_color');
    if (savedColor != null && mounted) {
      setState(() {
        _accentColor = Color(int.parse(savedColor));
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    _currentOffset = 0;
    _hasMore = true;
    
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_comments.php?meme_id=${widget.post['id']}&limit=20&offset=0'),
      );
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data['comments']);
          _totalComments = data['total'];
          _currentOffset = _comments.length;
          _hasMore = _comments.length < _totalComments;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_comments.php?meme_id=${widget.post['id']}&limit=20&offset=$_currentOffset'),
      );
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && mounted) {
        setState(() {
          final newComments = List<Map<String, dynamic>>.from(data['comments']);
          _comments.addAll(newComments);
          _currentOffset += newComments.length;
          _hasMore = _currentOffset < _totalComments;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more comments: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isSending = true);
    
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/add_comment.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'meme_id': widget.post['id'],
          'comment_text': text,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && mounted) {
        // Добавляем новый комментарий в начало списка (сверху)
        final newComment = data['comment'];
        setState(() {
          _comments.insert(0, newComment);
          _totalComments++;
          _commentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to add comment'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/delete_comment.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'comment_id': commentId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && mounted) {
        setState(() {
          _comments.removeWhere((c) => c['id'] == commentId);
          _totalComments--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to delete'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCommentMenu(Map<String, dynamic> comment) {
    final isOwn = comment['user_id'] == widget.userId;
    
    if (!isOwn) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete comment', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showConfirmDeleteDialog(comment['id']);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showConfirmDeleteDialog(int commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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

  void _openImageViewer(String imageUrl) {
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://listo4ek.tech/$imageUrl';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(imageUrl: fullUrl),
      ),
    );
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
    } catch (_) {
      return '';
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildPostItem() {
    final post = widget.post;
    final screenWidth = MediaQuery.of(context).size.width;
    final hasImage = post['meme_image'] != null && post['meme_image'].toString().isNotEmpty;
    final hasUserReacted = post['has_user_reacted'] == true;
    final community = post['community_name'];
    final communityId = post['community_id'];
    final username = '@${post['username']}';
    final text = post['meme_text'];
    final reactions = post['reactions'] ?? 0;
    final views = post['views_count'] ?? 0;
    final commentsCount = _totalComments;
    final time = _formatDate(post['created_at']);
    final avatarBase64 = post['user_avatar'];
    final avatarWidth = screenWidth * 1 / 7;
    final double cardWidth = screenWidth * 5 / 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: avatarWidth,
            child: GestureDetector(
              onTap: () => _openUserProfile(post['user_id']),
              child: Center(
                child: AppAvatar(base64Image: avatarBase64, radius: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (community != null && community.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          // Можно добавить переход в сообщество
                        },
                        child: Text(
                          '##$community',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    if (community != null && community.isNotEmpty) const SizedBox(width: 6),
                    _linkifier.buildRichText(username),
                  ],
                ),
                if (hasImage) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openImageViewer(post['meme_image']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post['meme_image'].startsWith('http')
                            ? post['meme_image']
                            : 'https://listo4ek.tech/${post['meme_image']}',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey.shade800,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                ],
                if (text != null && text.toString().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: hasImage ? 8 : 0, bottom: 8),
                    child: _linkifier.buildRichText(text.toString()),
                  ),
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasUserReacted ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: hasUserReacted ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatNumber(reactions),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUserReacted ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          _formatNumber(commentsCount),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    const SizedBox(width: 8),
                    Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text('$views', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final isOwn = comment['user_id'] == widget.userId;
    final username = '@${comment['username']}';
    final text = comment['comment_text'];
    final time = _formatDate(comment['created_at']);
    final avatarBase64 = comment['avatar'];

    return GestureDetector(
      onLongPress: () => _showCommentMenu(comment),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openUserProfile(comment['user_id']),
              child: AppAvatar(base64Image: avatarBase64, radius: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                      if (isOwn) ...[
                        const Spacer(),
                        Icon(Icons.check_circle, size: 12, color: _accentColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _linkifier.buildRichText(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _animationController.reverse().then((_) {
              Navigator.pop(context);
            });
          },
        ),
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Пост сверху
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
              ),
              child: _buildPostItem(),
            ),
            // Список комментариев
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No comments yet'),
                              SizedBox(height: 8),
                              Text('Be the first to comment!'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _comments.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildCommentItem(_comments[index]);
                          },
                        ),
            ),
            // Поле ввода комментария
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade800)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      enabled: !_isSending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _isSending ? Colors.grey : _accentColor,
                    child: IconButton(
                      onPressed: _isSending ? null : _addComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}