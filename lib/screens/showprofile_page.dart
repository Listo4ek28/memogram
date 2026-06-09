import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart' as chat;
import 'edit_profile_page.dart';
import 'community_page.dart';
import 'linking.dart';
import 'comments_page.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/image_viewer.dart' as image_viewer;

class ShowProfilePage extends StatefulWidget {
  final int userId;
  final int profileUserId;
  final String currentUsername;

  const ShowProfilePage({
    super.key,
    required this.userId,
    required this.profileUserId,
    required this.currentUsername,
  });

  @override
  State<ShowProfilePage> createState() => _ShowProfilePageState();
}

class _ShowProfilePageState extends State<ShowProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reposts = [];
  
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isCheckingFollow = true;
  
  int _followersCount = 0;
  int _followingCount = 0;
  
  Color _accentColor = Colors.blue;
  late MentionLinkifier _linkifier;
  late MentionLinkifier _bioLinkifier;

  @override
  void initState() {
    super.initState();
    _loadAccentColor();
    // Стандартный linkifier для постов
    _linkifier = MentionLinkifier(
      userId: widget.userId,
      username: widget.currentUsername,
      context: context,
    );
    // Отдельный linkifier для bio, который НЕ выделяет @username текущего пользователя
    _bioLinkifier = MentionLinkifier(
      userId: widget.userId,
      username: widget.currentUsername,
      context: context,
      highlightCurrentUser: false,
    );
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _checkFollowStatus();
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

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_user_profile.php?user_id=${widget.profileUserId}'),
      );
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && mounted) {
        setState(() {
          _userData = data['user'];
        });
        
        await _loadUserPosts();
        await _loadFollowStats();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_user_posts.php?user_id=${widget.profileUserId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        final posts = List<Map<String, dynamic>>.from(data['posts']);
        for (var post in posts) {
          try {
            final rc = await http.get(Uri.parse('https://listo4ek.tech/check_reaction.php?user_id=${widget.userId}&meme_id=${post['id']}'));
            if (rc.statusCode == 200) {
              post['has_user_reacted'] = jsonDecode(rc.body)['has_reacted'] ?? false;
            } else {
              post['has_user_reacted'] = false;
            }
          } catch (_) { post['has_user_reacted'] = false; }
          post['comments_count'] = post['comments_count'] ?? 0;
        }
        setState(() {
          _posts = posts;
        });
      }
    } catch (e) {
      debugPrint('Error loading user posts: $e');
    }
  }

  Future<void> _loadFollowStats() async {
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_user_stats.php?user_id=${widget.profileUserId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _followersCount = data['followers_count'] ?? 0;
          _followingCount = data['following_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading follow stats: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    if (widget.userId == widget.profileUserId) {
      setState(() => _isCheckingFollow = false);
      return;
    }
    setState(() => _isCheckingFollow = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/check_follow.php?user_id=${widget.userId}&follow_id=${widget.profileUserId}'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _isFollowing = data['is_following'] ?? false;
          _isCheckingFollow = false;
        });
      } else {
        setState(() => _isCheckingFollow = false);
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      setState(() => _isCheckingFollow = false);
    }
  }

  Future<void> _toggleFollow() async {
    final action = _isFollowing ? 'unfollow' : 'follow';
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/toggle_follow.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'follow_id': widget.profileUserId,
          'action': action,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          if (_isFollowing) {
            _followersCount++;
          } else {
            _followersCount--;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Subscribed!' : 'Unsubscribed'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
      );
    }
  }

  void _openChat() {
    final chatName = _userData?['display_name'] ?? _userData?['username'] ?? 'User';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => chat.ChatPage(
          userId: widget.userId,
          username: widget.currentUsername,
          chatId: widget.profileUserId,
          chatName: chatName,
          isGroup: false,
        ),
      ),
    );
  }

  void _editProfile() async {
    if (_userData != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(
            userId: widget.userId,
            userData: _userData!,
          ),
        ),
      );
      if (result != null && mounted) {
        setState(() {
          _userData = result;
        });
      }
    }
  }

  void _openImageViewer(String imageUrl) {
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://listo4ek.tech/$imageUrl';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => image_viewer.ImageViewer(imageUrl: fullUrl),
      ),
    );
  }

  void _openCommunityFeed(int communityId, String communityName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityPage(
          userId: widget.userId,
          username: widget.currentUsername,
          communityId: communityId,
          communityName: communityName,
        ),
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
          currentUsername: widget.currentUsername,
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
          for (var post in _posts) {
            if (post['id'] == memeId) {
              post['reactions'] = (post['reactions'] ?? 0) + (hasUserReacted ? -1 : 1);
              post['has_user_reacted'] = !hasUserReacted;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasUserReacted ? '❤️ Reaction removed' : '❤️ You liked this!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) { debugPrint('Error toggling reaction: $e'); }
  }

  void _showCommentsPage(Map<String, dynamic> post) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CommentsPage(
          userId: widget.userId,
          username: widget.currentUsername,
          post: post,
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
      _loadUserPosts();
    });
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    try {
      final d = DateTime.parse(dt);
      final diff = DateTime.now().difference(d);
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
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = widget.userId == widget.profileUserId;
    final displayName = _userData?['display_name'] ?? _userData?['username'] ?? 'User';
    final username = _userData?['username'] ?? '';
    final bio = _userData?['bio'] ?? '';
    final avatar = _userData?['avatar'];
    final memesViewed = _userData?['memes_viewed'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accentColor,
                              width: 2,
                            ),
                          ),
                          child: AppAvatar(
                            base64Image: avatar,
                            radius: 48,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                _formatNumber(_posts.length),
                                'Posts',
                              ),
                              _buildStatColumn(
                                _formatNumber(_followersCount),
                                'Followers',
                              ),
                              _buildStatColumn(
                                _formatNumber(memesViewed),
                                'Views',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _bioLinkifier.buildRichText(bio),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isOwnProfile ? _editProfile : (_isCheckingFollow ? null : _toggleFollow),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOwnProfile
                                  ? _accentColor
                                  : (_isFollowing ? Colors.grey.shade800 : _accentColor),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isCheckingFollow && !isOwnProfile
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isOwnProfile
                                        ? 'Edit Profile'
                                        : (_isFollowing ? 'Subscribed' : 'Subscribe'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isOwnProfile ? null : _openChat,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Message',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    color: Colors.grey.shade900,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _accentColor,
                      labelColor: _accentColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Reposts'),
                      ],
                    ),
                  ),
                  
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 350,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _posts.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No posts yet',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  final post = _posts[index];
                                  return _buildPostItem(post);
                                },
                              ),
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.repeat,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reposts yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
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

  Widget _buildPostItem(Map<String, dynamic> post) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasImage = post['meme_image'] != null && post['meme_image'].toString().isNotEmpty;
    final hasUserReacted = post['has_user_reacted'] == true;
    final community = post['community_name'];
    final communityId = post['community_id'];
    final text = post['meme_text'];
    final reactions = post['reactions'] ?? 0;
    final views = post['views_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final time = _formatDate(post['created_at']);
    final avatarBase64 = post['user_avatar'];
    final avatarWidth = screenWidth * 1 / 7;
    final double cardWidth = screenWidth * 5 / 7;

    Widget postCard = Container(
      constraints: BoxConstraints(maxWidth: cardWidth),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Показываем сообщество только если оно есть (без @username, т.к. это страница пользователя)
          if (community != null && community.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (communityId != null) {
                  _openCommunityFeed(communityId, community);
                }
              },
              child: Text(
                '##$community',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          if (hasImage) ...[
            const SizedBox(height: 6),
            _buildPostImage(post['meme_image']),
          ],
          if (text != null && text.toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: hasImage ? 6 : 4, bottom: 4),
              child: _linkifier.buildRichText(text.toString()),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleReaction(post['id'], hasUserReacted),
                child: Row(
                  children: [
                    Icon(
                      hasUserReacted ? Icons.favorite : Icons.favorite_border,
                      size: 16,
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
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showCommentsPage(post),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      _formatNumber(commentsCount),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(width: 8),
              Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 2),
              Text('$views', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
          Flexible(child: postCard),
          SizedBox(width: screenWidth * (1 - 1/7 - 5/7)),
        ],
      ),
    );
  }

  Widget _buildPostImage(String imagePath) {
    final imageUrl = imagePath.startsWith('http') 
        ? imagePath 
        : 'https://listo4ek.tech/$imagePath';
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
            return Container(
              height: 200,
              color: Colors.grey.shade800,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: Colors.grey.shade800,
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}