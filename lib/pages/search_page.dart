import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/song.dart';
import 'song_page.dart';

class SearchPage extends StatefulWidget {
  final bool isPlaylistSearch;
  final Function(Song)? onSongSelected;

  const SearchPage({
    super.key, 
    this.isPlaylistSearch = false,
    this.onSongSelected,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
    });
    
    try {
      const apiUrl = 'https://api.audius.co/v1/tracks/search';
      final url = Uri.parse('$apiUrl?query=$query&app_name=spatiplay');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final results = (data['data'] as List)
              .map((t) => Song.fromAudiusJson(t as Map<String, dynamic>))
              .toList();
              
          setState(() {
            _searchResults = results;
          });
        } else {
          setState(() {
            _searchResults = [];
            _error = 'No results found';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch songs: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSongSelection(Song song) {
    if (widget.isPlaylistSearch && widget.onSongSelected != null) {
      widget.onSongSelected!(song);
      Navigator.pop(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SongPage(song: song)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Songs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onSubmitted: _searchSongs,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchSongs(_searchController.text),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final song = _searchResults[index];
                    return ListTile(
                      leading: song.imageUrl.isNotEmpty
                          ? Hero(
                              tag: 'song_image_${song.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  song.imageUrl,
                                  width: 50, 
                                  height: 50, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                                ),
                              ),
                            )
                          : const Icon(Icons.music_note),
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: IconButton(
                        icon: Icon(widget.isPlaylistSearch ? Icons.add : Icons.play_arrow),
                        onPressed: () => _handleSongSelection(song),
                      ),
                      onTap: () => _handleSongSelection(song),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 