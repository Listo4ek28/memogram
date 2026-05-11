import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> _memes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMemes();
  }

  Future<void> _loadAllMemes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://listo4ek.tech/get_all_memes.php'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _memes = List<Map<String, dynamic>>.from(data['memes']);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading all memes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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

  // Простое отображение картинки без сложных правил
  Widget _buildSimpleImage(String base64Image) {
    try {
      Uint8List bytes = base64Decode(base64Image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 250,
          fit: BoxFit.contain,
        ),
      );
    } catch (_) {
      return const Icon(Icons.broken_image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Memes (Admin)'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memes.isEmpty
              ? const Center(child: Text('No memes found'))
              : RefreshIndicator(
                  onRefresh: _loadAllMemes,
                  child: ListView.builder(
                    itemCount: _memes.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (_, index) {
                      final meme = _memes[index];
                      return Card(
                        color: Colors.grey.shade900,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${meme['username']} (${meme['display_name']})',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (meme['meme_text'] != null && meme['meme_text'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(meme['meme_text']),
                                ),
                              if (meme['meme_image'] != null && meme['meme_image'].toString().isNotEmpty)
                                _buildSimpleImage(meme['meme_image']),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.favorite, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${meme['reactions'] ?? 0}'),
                                  const Spacer(),
                                  Text(_formatDate(meme['created_at']),
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}