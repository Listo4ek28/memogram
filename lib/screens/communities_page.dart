import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'community_page.dart';
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
  
  // Основные данные
  List<Map<String, dynamic>> _myCommunities = [];
  List<Map<String, dynamic>> _recommendedCommunities = [];
  List<Map<String, dynamic>> _filteredCommunities = [];
  
  // Кэшированные данные (показываем сразу)
  List<Map<String, dynamic>> _cachedMyCommunities = [];
  List<Map<String, dynamic>> _cachedRecommendedCommunities = [];
  
  bool _isFirstLoad = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Статусы подписки и количество участников (кэш)
  Map<int, bool> _membershipCache = {};
  Map<int, int> _membersCountCache = {};
  
  Color _accentColor = Colors.blue;
  
  // Флаг для отслеживания фонового обновления из main.dart
  bool _pendingBackgroundUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadAccentColor();
    _loadCachedData();
    _loadData(background: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Если есть отложенное обновление, выполняем его
    if (_pendingBackgroundUpdate) {
      _pendingBackgroundUpdate = false;
      _loadData(background: true);
    }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Загрузка кэшированных данных из SharedPreferences
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final cachedMy = prefs.getString('cached_my_communities');
      final cachedRecommended = prefs.getString('cached_recommended_communities');
      final cachedMembership = prefs.getString('cached_membership');
      final cachedMembersCount = prefs.getString('cached_members_count');
      
      if (cachedMy != null) {
        final List<dynamic> decoded = jsonDecode(cachedMy);
        setState(() {
          _cachedMyCommunities = List<Map<String, dynamic>>.from(decoded);
          _myCommunities = List.from(_cachedMyCommunities);
          if (!_isSearching) {
            _filteredCommunities = List.from(_myCommunities);
          }
        });
      }
      
      if (cachedRecommended != null) {
        final List<dynamic> decoded = jsonDecode(cachedRecommended);
        setState(() {
          _cachedRecommendedCommunities = List<Map<String, dynamic>>.from(decoded);
          _recommendedCommunities = List.from(_cachedRecommendedCommunities);
        });
      }
      
      if (cachedMembership != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedMembership);
        final Map<int, bool> restored = {};
        decoded.forEach((key, value) {
          restored[int.parse(key)] = value as bool;
        });
        setState(() {
          _membershipCache = restored;
        });
      }
      
      if (cachedMembersCount != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedMembersCount);
        final Map<int, int> restored = {};
        decoded.forEach((key, value) {
          restored[int.parse(key)] = value as int;
        });
        setState(() {
          _membersCountCache = restored;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  // Сохранение данных в кэш
  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('cached_my_communities', jsonEncode(_myCommunities));
    await prefs.setString('cached_recommended_communities', jsonEncode(_recommendedCommunities));
    
    final membershipMap = <String, bool>{};
    _membershipCache.forEach((key, value) {
      membershipMap[key.toString()] = value;
    });
    await prefs.setString('cached_membership', jsonEncode(membershipMap));
    
    final membersCountMap = <String, int>{};
    _membersCountCache.forEach((key, value) {
      membersCountMap[key.toString()] = value;
    });
    await prefs.setString('cached_members_count', jsonEncode(membersCountMap));
  }

  // Основная загрузка данных с сервера
  Future<void> _loadData({bool background = false}) async {
    if (_isFirstLoad) {
      setState(() => _isFirstLoad = false);
    }
    
    if (!background) {
      setState(() => _isRefreshing = true);
    }
    
    try {
      debugPrint('Loading communities data, background: $background');
      
      // Загружаем мои сообщества
      final myResponse = await http.get(
        Uri.parse('https://listo4ek.tech/get_user_communities.php?user_id=${widget.userId}'),
      );
      final myData = jsonDecode(myResponse.body);
      
      // Загружаем рекомендуемые сообщества
      final recResponse = await http.get(
        Uri.parse('https://listo4ek.tech/get_recommended_communities.php?user_id=${widget.userId}'),
      );
      final recData = jsonDecode(recResponse.body);
      
      if (myData['success'] == true && recData['success'] == true && mounted) {
        final newMyCommunities = List<Map<String, dynamic>>.from(myData['communities']);
        final newRecommendedCommunities = List<Map<String, dynamic>>.from(recData['communities']);
        
        // Обновляем статусы подписки и количество участников
        final allCommunities = [...newMyCommunities, ...newRecommendedCommunities];
        final uniqueIds = allCommunities.map((c) => c['id'] as int).toSet();
        
        for (final id in uniqueIds) {
          await _updateCommunityData(id);
        }
        
        setState(() {
          _myCommunities = newMyCommunities;
          _recommendedCommunities = newRecommendedCommunities;
          if (!_isSearching) {
            _filteredCommunities = List.from(_myCommunities);
          }
          _cachedMyCommunities = List.from(_myCommunities);
          _cachedRecommendedCommunities = List.from(_recommendedCommunities);
        });
        
        await _saveToCache();
        
        if (!background && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Communities updated'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _updateCommunityData(int communityId) async {
    try {
      // Обновляем статус подписки
      final membershipResponse = await http.get(
        Uri.parse('https://listo4ek.tech/check_membership.php?user_id=${widget.userId}&community_id=$communityId'),
      );
      final membershipData = jsonDecode(membershipResponse.body);
      if (membershipData['success'] == true && mounted) {
        _membershipCache[communityId] = membershipData['is_member'] ?? false;
      }
      
      // Обновляем количество участников
      final infoResponse = await http.get(
        Uri.parse('https://listo4ek.tech/get_community_info.php?community_id=$communityId'),
      );
      final infoData = jsonDecode(infoResponse.body);
      if (infoData['success'] == true && infoData['community'] != null && mounted) {
        _membersCountCache[communityId] = infoData['community']['members_count'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error updating community data: $e');
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
        // Находим сообщество в рекомендуемых
        final communityIndex = _recommendedCommunities.indexWhere((c) => c['id'] == communityId);
        if (communityIndex != -1) {
          final community = _recommendedCommunities[communityIndex];
          setState(() {
            // Удаляем из рекомендуемых
            _recommendedCommunities.removeAt(communityIndex);
            // Добавляем в мои сообщества
            _myCommunities.insert(0, community);
            if (!_isSearching) {
              _filteredCommunities = List.from(_myCommunities);
            }
            _membershipCache[communityId] = true;
            _membersCountCache[communityId] = (_membersCountCache[communityId] ?? 0) + 1;
          });
          await _saveToCache();
        } else {
          // Просто обновляем статус
          setState(() {
            _membershipCache[communityId] = true;
            _membersCountCache[communityId] = (_membersCountCache[communityId] ?? 0) + 1;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined community!'), backgroundColor: Colors.green),
        );
      } else {
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
        // Находим сообщество в моих сообществах
        final communityIndex = _myCommunities.indexWhere((c) => c['id'] == communityId);
        if (communityIndex != -1) {
          final community = _myCommunities[communityIndex];
          setState(() {
            // Удаляем из моих сообществ
            _myCommunities.removeAt(communityIndex);
            // Добавляем в рекомендуемые
            _recommendedCommunities.insert(0, community);
            if (!_isSearching) {
              _filteredCommunities = List.from(_myCommunities);
            }
            _membershipCache[communityId] = false;
            _membersCountCache[communityId] = (_membersCountCache[communityId] ?? 0) - 1;
            if (_membersCountCache[communityId]! < 0) _membersCountCache[communityId] = 0;
          });
          await _saveToCache();
        } else {
          setState(() {
            _membershipCache[communityId] = false;
            _membersCountCache[communityId] = (_membersCountCache[communityId] ?? 0) - 1;
            if (_membersCountCache[communityId]! < 0) _membersCountCache[communityId] = 0;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left community'), backgroundColor: Colors.orange),
        );
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
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredCommunities = List.from(_myCommunities);
      } else {
        final allCommunities = [..._myCommunities, ..._recommendedCommunities];
        final unique = allCommunities.toSet().toList();
        _filteredCommunities = unique.where((c) {
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
        builder: (context) => CommunityPage(
          userId: widget.userId,
          username: widget.username,
          communityId: community['id'],
          communityName: community['name'],
        ),
      ),
    ).then((_) {
      // При возвращении из сообщества обновляем данные в фоне
      _loadData(background: true);
    });
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
                                  _loadData(background: true);
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

  String _truncateName(String name, int maxLength) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength)}...';
  }

  // Публичный метод для обновления из main.dart
  void refreshData() {
    debugPrint('refreshData called from main.dart');
    if (mounted) {
      _loadData(background: true);
    } else {
      _pendingBackgroundUpdate = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCommunities = _isSearching ? _filteredCommunities : _myCommunities;
    final showRecommended = !_isSearching && _recommendedCommunities.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        centerTitle: false,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create community',
            onPressed: _showCreateCommunitySheet,
          ),
        ],
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
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCommunities('');
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
              onChanged: _filterCommunities,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(background: false),
        child: CustomScrollView(
          slivers: [
            if (displayCommunities.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'My Communities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final community = displayCommunities[index];
                      final memberCount = _membersCountCache[community['id']] ?? community['members_count'] ?? 0;
                      final name = community['name'];
                      final truncatedName = _truncateName(name, 18);
                      final isMember = _membershipCache[community['id']] ?? true;
                      
                      return GestureDetector(
                        onTap: () => _openCommunityFeed(community),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade600,
                                        width: 1,
                                      ),
                                    ),
                                    child: AppAvatar(
                                      base64Image: community['avatar'],
                                      radius: 33,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '##$truncatedName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$memberCount members',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _leaveCommunity(community['id']),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: _accentColor),
                                      foregroundColor: _accentColor,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      minimumSize: const Size(double.infinity, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text('Subscribed', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: displayCommunities.length,
                  ),
                ),
              ),
            ],
            if (showRecommended) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Recommended for You',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final community = _recommendedCommunities[index];
                      final memberCount = _membersCountCache[community['id']] ?? community['members_count'] ?? 0;
                      final name = community['name'];
                      final truncatedName = _truncateName(name, 18);
                      final isMember = _membershipCache[community['id']] ?? false;
                      
                      return GestureDetector(
                        onTap: () => _openCommunityFeed(community),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade600,
                                        width: 1,
                                      ),
                                    ),
                                    child: AppAvatar(
                                      base64Image: community['avatar'],
                                      radius: 33,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '##$truncatedName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$memberCount members',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _joinCommunity(community['id']),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: _accentColor),
                                      foregroundColor: _accentColor,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      minimumSize: const Size(double.infinity, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text('Subscribe', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _recommendedCommunities.length,
                  ),
                ),
              ),
            ],
            if (displayCommunities.isEmpty && !_isSearching && _recommendedCommunities.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No communities available'),
                      SizedBox(height: 8),
                      Text('Create one or join existing!'),
                    ],
                  ),
                ),
              ),
            if (_isSearching && _filteredCommunities.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No communities found'),
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