import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'profile_page.dart';
import 'showprofile_page.dart';
import 'dart:ui' as ui;
import 'linking.dart';
import '../widgets/avatar_widget.dart';

class ChatPage extends StatefulWidget {
  final int userId;
  final String username;
  final int chatId;
  final String chatName;
  final bool isGroup;

  const ChatPage({
    super.key,
    required this.userId,
    required this.username,
    required this.chatId,
    required this.chatName,
    this.isGroup = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isSending = false;
  bool _isPolling = false;
  String? _selectedImageBase64;
  Color? _myMessageColor;
  int _lastMessageId = 0;
  Timer? _pollingTimer;
  
  // Для отслеживания статуса страницы
  bool _isPageActive = true;

  final Map<int, String> _userNamesCache = {};
  final Map<int, String> _userAvatarsCache = {};

  late MentionLinkifier _linkifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _linkifier = MentionLinkifier(userId: widget.userId, username: widget.username, context: context);
    _loadMyMessageColor();
    _loadMessages().then((_) {
      _scrollToBottom();
      _startPolling();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Приложение вернулось на передний план
      _isPageActive = true;
      _loadMessages();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      // Приложение ушло в фон
      _isPageActive = false;
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_pollingTimer != null) return;
    // Опрос каждые 2 секунды
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isPageActive && mounted) {
        _checkNewMessages();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkNewMessages() async {
    if (_isPolling || !mounted) return;
    
    _isPolling = true;
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/check_new_messages.php?user_id=${widget.userId}&chat_id=${widget.chatId}&last_message_id=$_lastMessageId'),
      ).timeout(const Duration(seconds: 5));
      
      if (!mounted) return;
      
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['has_new'] == true) {
        final newMessages = List<Map<String, dynamic>>.from(data['messages']);
        if (newMessages.isNotEmpty) {
          setState(() {
            // Добавляем только те сообщения, которых ещё нет
            for (var msg in newMessages) {
              final exists = _messages.any((m) => m['message_id'] == msg['message_id']);
              if (!exists) {
                _messages.add(msg);
              }
            }
            // Сортируем по времени
            _messages.sort((a, b) {
              final aTime = a['created_at'] ?? '';
              final bTime = b['created_at'] ?? '';
              return aTime.compareTo(bTime);
            });
            // Обновляем last_message_id
            if (_messages.isNotEmpty) {
              _lastMessageId = _messages.last['message_id'];
            }
          });
          
          // Загружаем имена пользователей для новых сообщений
          for (var msg in newMessages) {
            final fromUser = msg['from_user'] as int;
            if (!_userNamesCache.containsKey(fromUser)) {
              _getUserName(fromUser);
            }
          }
          
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    } finally {
      if (mounted) {
        _isPolling = false;
      }
    }
  }

  Future<void> _loadMyMessageColor() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getString('my_message_color');
    setState(() => _myMessageColor = c != null ? Color(int.parse(c)) : const Color(0xFF202040));
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse('https://listo4ek.tech/get_chat_messages.php?user_id=${widget.userId}&chat_id=${widget.chatId}'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true && mounted) {
        final loaded = <Map<String, dynamic>>[];
        for (var item in data['messages']) {
          if (item is Map) loaded.add(Map<String, dynamic>.from(item));
        }
        setState(() {
          _messages.clear();
          _messages.addAll(loaded);
          if (_messages.isNotEmpty) {
            _lastMessageId = _messages.last['message_id'];
          }
        });
        for (var msg in _messages) {
          final from = msg['from_user'] as int;
          if (!_userNamesCache.containsKey(from)) await _getUserName(from);
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getUserName(int userId) async {
    if (_userNamesCache.containsKey(userId)) return _userNamesCache[userId]!;
    try {
      final resp = await http.get(Uri.parse('https://listo4ek.tech/get_user_profile.php?user_id=$userId'));
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        final name = data['user']['display_name'] ?? data['user']['username'];
        _userNamesCache[userId] = name;
        final av = data['user']['avatar'];
        if (av != null && av.isNotEmpty) _userAvatarsCache[userId] = av;
        if (mounted) setState(() {});
        return name;
      }
    } catch (_) {}
    return 'User $userId';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowProfilePage(
          userId: widget.userId,
          profileUserId: widget.chatId,
          currentUsername: widget.username,
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    if (_messageController.text.isEmpty && _selectedImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something or select an image')),
      );
      return;
    }
    _isSending = true;
    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        Uri.parse('https://listo4ek.tech/send_chat_message.php'),
        body: jsonEncode({
          'user_id': widget.userId,
          'chat_id': widget.chatId,
          'message_text': _messageController.text,
          'message_image': _selectedImageBase64,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true && mounted) {
        final newId = data['message']['id'] is int
            ? data['message']['id']
            : int.parse(data['message']['id'].toString());
        final newMessage = {
          'type': 'sent',
          'text': data['message']['text'],
          'image': data['message']['image'],
          'message_id': newId,
          'from_user': widget.userId,
          'display_name': widget.username,
          'time': _getCurrentTime(),
          'created_at': DateTime.now().toIso8601String(),
        };
        setState(() {
          _messages.add(newMessage);
          _lastMessageId = newId;
          _messageController.clear();
          _selectedImageBase64 = null;
        });
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to send message')),
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error. Please try again.')),
        );
      }
    } finally {
      _isSending = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _openImageViewer(String imagePath) {
    // Формируем правильный URL (как в feed_page.dart)
    final imageUrl = imagePath.startsWith('http') 
        ? imagePath 
        : 'https://listo4ek.tech/$imagePath';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return const SizedBox.shrink();
    final imageUrl = imagePath.startsWith('http') 
        ? imagePath 
        : 'https://listo4ek.tech/$imagePath';
    return GestureDetector(
      onTap: () => _openImageViewer(imagePath!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: MediaQuery.of(context).size.width * 2 / 3,
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

  Widget _buildImagePreview(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(base64Image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, fit: BoxFit.cover, width: 100, height: 100),
      );
    } catch (_) {
      return Container(
        width: 100, height: 100, color: Colors.grey.shade800,
        child: const Icon(Icons.error, size: 40, color: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
        if (result != null && result.files.first.bytes != null) {
          setState(() => _selectedImageBase64 = base64Encode(result.files.first.bytes!));
        }
      } else {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() => _selectedImageBase64 = base64Encode(bytes));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showMessageMenu(Map<String, dynamic> msg) {
    final isOwn = msg['type'] == 'sent';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwn)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg['message_id']);
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title: const Text('Report', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _showReportMenu(msg['message_id']);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      final response = await http.post(
        Uri.parse('https://listo4ek.tech/delete_message.php'),
        body: jsonEncode({'user_id': widget.userId, 'message_id': messageId}),
        headers: {'Content-Type': 'application/json'},
      );
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && mounted) {
        setState(() {
          _messages.removeWhere((m) => m['message_id'] == messageId);
          if (_messages.isNotEmpty) {
            _lastMessageId = _messages.last['message_id'];
          } else {
            _lastMessageId = 0;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to delete message')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error')),
        );
      }
    }
  }

  void _showReportMenu(int messageId) {
    final reasons = {
      'spam': '📢 Spam',
      'advertising': '📱 Advertising',
      'nsfw': '🔞 NSFW Content',
      'harassment': '😤 Harassment',
      'other': '⚠️ Other Violations',
    };
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Report this message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ...reasons.entries.map((e) => ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title: Text(e.value),
              onTap: () {
                Navigator.pop(context);
                _submitReport(messageId, e.key);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(int messageId, String reason) async {
    try {
      await http.post(
        Uri.parse('https://listo4ek.tech/report_meme.php'),
        body: jsonEncode({'message_id': messageId, 'user_id': widget.userId, 'reason': reason}),
        headers: {'Content-Type': 'application/json'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error reporting: $e');
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isSent = msg['type'] == 'sent';
    final fromUserId = msg['from_user'] as int;
    final displayName = _userNamesCache[fromUserId] ?? (msg['display_name'] ?? 'User $fromUserId');
    final text = msg['text'];
    final image = msg['image'];
    final time = msg['time'] ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final hasImage = image != null && image.toString().isNotEmpty;

    double cardMaxWidth = screenWidth * 2 / 3;

    Widget messageCard = Container(
      width: hasImage ? cardMaxWidth : null,
      constraints: hasImage ? null : BoxConstraints(maxWidth: cardMaxWidth),
      margin: EdgeInsets.only(
        left: isSent ? screenWidth - cardMaxWidth - 8 : 8,
        right: isSent ? 8 : screenWidth - cardMaxWidth - 8,
      ),
      decoration: BoxDecoration(
        color: isSent ? (_myMessageColor ?? Colors.blue.shade700) : Colors.grey.shade800,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isSent ? 12 : 2),
          bottomRight: Radius.circular(isSent ? 2 : 12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) _buildImageWidget(image.toString()),
          if (text != null && text.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: _linkifier.buildRichText(text.toString()),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, (text != null && text.isNotEmpty) ? 0 : 4, 8, 4),
            child: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ),
        ],
      ),
    );

    return GestureDetector(
      onLongPress: () => _showMessageMenu(msg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: messageCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroup ? widget.chatName : 'Chat with ${widget.chatName}'),
        centerTitle: false,
        actions: [
          if (!widget.isGroup)
            GestureDetector(
              onTap: _openUserProfile,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AppAvatar(
                  base64Image: _userAvatarsCache[widget.chatId],
                  radius: 18,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing...'), duration: Duration(seconds: 1)),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('No messages yet', style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text('Send a message to start the conversation!', 
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildMessageItem(_messages[i]),
                      ),
          ),
          if (_selectedImageBase64 != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              height: 100,
              child: Stack(
                children: [
                  _buildImagePreview(_selectedImageBase64),
                  Positioned(
                    top: 4, right: 4,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black.withOpacity(0.7),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.white),
                        onPressed: () => setState(() => _selectedImageBase64 = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _pickImage, 
                  icon: const Icon(Icons.image), 
                  tooltip: 'Attach image',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _isLoading ? Colors.grey : (_myMessageColor ?? Colors.blue.shade700),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white),
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white), 
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onScaleStart: (d) { _previousScale = _scale; _previousOffset = _offset; },
          onScaleUpdate: (d) {
            setState(() {
              _scale = (_previousScale * d.scale).clamp(1.0, 5.0);
              if (_scale > 1.0) _offset = _previousOffset + d.focalPointDelta;
              else _offset = Offset.zero;
              _clampOffset();
            });
          },
          onDoubleTap: () {
            setState(() {
              if (_scale > 1.0) { _scale = 1.0; _offset = Offset.zero; }
              else { _scale = 3.0; _offset = Offset.zero; }
              _clampOffset();
            });
          },
          child: Transform(
            transform: Matrix4.identity()..translate(_offset.dx, _offset.dy)..scale(_scale),
            child: Center(
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clampOffset() {
    final size = MediaQuery.of(context).size;
    final maxX = (size.width * (_scale - 1)) / 2;
    final maxY = (size.height * (_scale - 1)) / 2;
    if (_scale <= 1.0) _offset = Offset.zero;
    else _offset = Offset(_offset.dx.clamp(-maxX, maxX), _offset.dy.clamp(-maxY, maxY));
  }
}