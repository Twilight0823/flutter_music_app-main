import 'package:flutter/material.dart';
import 'package:music_app/components/my_drawer.dart';
import 'package:music_app/components/mini_player.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../components/playlist_card.dart';
import 'playlist_detail_page.dart';
import 'import_playlist_page.dart';
import 'search_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    
    try {
      final provider = Provider.of<PlaylistProvider>(context, listen: false);
      await provider.loadUserPlaylists();
    } catch (e) {
      if (mounted) {
        _showError('Failed to load playlists: $e');
      }
    }
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
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlaylistDetailPage()),
                    );
                  }
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
    ).then((_) => _loadUserPlaylists());
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: _navigateToSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search songs...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Playlists view
          Expanded(
            child: _buildPlaylistsView(),
          ),
        ],
      ),
      
      bottomNavigationBar: const MiniPlayer(),
    );
  }
  
  Widget _buildPlaylistsView() {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        if (playlistProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (playlistProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  playlistProvider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUserPlaylists,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final userPlaylists = playlistProvider.userPlaylists;
        
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
}