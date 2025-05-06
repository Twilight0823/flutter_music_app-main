import 'package:flutter/material.dart';
import 'package:music_app/components/my_drawer.dart';
import 'package:music_app/components/mini_player.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../services/audio_service.dart';
import '../components/playlist_card.dart';
import 'song_page.dart';
import 'playlist_detail_page.dart';
import 'import_playlist_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingPlaylists = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Add small delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPlaylists();
    });
  }

  Future<void> _loadUserPlaylists() async {
    if (!mounted) return;
    
    setState(() => _isLoadingPlaylists = true);
    try {
      final provider = Provider.of<PlaylistProvider>(context, listen: false);
      await provider.loadUserPlaylists();
      
      // Debug: Print the number of playlists loaded
      debugPrint('Loaded ${provider.userPlaylists.length} playlists');
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      _showError('Failed to load playlists: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlaylists = false);
      }
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = []; // Clear previous results
    });
    
    try {
      // Simplified URL construction
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
          
          // Navigate to song page if there's only one result
          if (results.length == 1) {
            _navigateToSongPage(results[0]);
          }
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
  
  void _navigateToSongPage(Song song) {
    // Use the AudioService to play the song
    final audioService = Provider.of<AudioService>(context, listen: false);
    
    // Play the song with error handling
    audioService.playSong(song).catchError((error) {
      _showError('Could not play song: $error');
      return null;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongPage(song: song)),
    );
  }
  
  void _navigateToPlaylistDetail(Playlist playlist) {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    playlistProvider.setCurrentPlaylist(playlist);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlaylistDetailPage()),
    );
  }
  
  void _createNewPlaylist() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Create New Playlist'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Playlist Name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final provider = Provider.of<PlaylistProvider>(context, listen: false);
                  await provider.createNewPlaylist(name);
                  Navigator.pop(context);
                  
                  // Refresh playlists after creating a new one
                  if (mounted) {
                    _loadUserPlaylists();
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlaylistDetailPage()),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
  
  void _navigateToImportPlaylist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportPlaylistPage()),
    ).then((_) => _loadUserPlaylists()); // Reload playlists when returning
  }
  
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S P A T I P L A Y'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserPlaylists,
            tooltip: 'Refresh playlists',
          ),
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: _navigateToImportPlaylist,
            tooltip: 'Import playlist',
          ),
          IconButton(
            icon: const Icon(Icons.add), 
            onPressed: _createNewPlaylist, 
            tooltip: 'Create New Playlist',
          )
        ],
      ),
      drawer: const MyDrawer(),
      
      body: Column(
        children: [
          // Search bar
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
          
          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            
          // Show search results or playlists
          Expanded(
            child: _isLoading ? 
              const Center(child: CircularProgressIndicator()) :
              _searchResults.isNotEmpty ?
                _buildSearchResults() :
                _buildPlaylistsView(),
          ),
        ],
      ),
      
      // Add the mini player at the bottom if there's a song playing
      bottomNavigationBar: const MiniPlayer(),
    );
  }
  
  Widget _buildSearchResults() {
    return ListView.builder(
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
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _navigateToSongPage(song),
          ),
          onTap: () => _navigateToSongPage(song),
        );
      },
    );
  }
  
  Widget _buildPlaylistsView() {
    // Use Consumer to rebuild when playlist provider changes
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final userPlaylists = playlistProvider.userPlaylists;
        
        if (_isLoadingPlaylists) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (userPlaylists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.playlist_play, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "You don't have any playlists yet",
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Playlist'),
                  onPressed: _createNewPlaylist,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Import Playlist'),
                  onPressed: _navigateToImportPlaylist,
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Playlists',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${userPlaylists.length} playlists',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: userPlaylists.length,
                  itemBuilder: (context, index) {
                    return PlaylistCard(
                      playlist: userPlaylists[index],
                      onTap: () => _navigateToPlaylistDetail(userPlaylists[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}