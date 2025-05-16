import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import '../services/audio_service.dart';
import '../components/mini_player.dart';
import 'song_page.dart';
import 'search_page.dart';

class PlaylistDetailPage extends StatefulWidget {
  const PlaylistDetailPage({super.key});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _loadPlaylistData();
  }
  
  void _loadPlaylistData() {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    _nameController.text = playlistProvider.currentPlaylist!.name;
  }
  
  void _sharePlaylist() async {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    final playlist = provider.currentPlaylist;
    
    // Generate shareable link in spatiplay.com format to match the import page requirements
    final shareLink = 'https://spatiplay.com/playlist/${playlist!.id}';
    final shareText = 'Check out my playlist "${playlist.name}" on Spatiplay! $shareLink';
    
    // Show bottom sheet with share options
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share "${playlist.name}"',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Display the share link in a container that looks selectable
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy, size: 20),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareLink));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard')),
                        );
                      }
                    },
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Option to copy full message with text
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist info copied to clipboard')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share, 
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share with Message',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Help text explaining import process
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Text(
                'Anyone with this link can import your playlist using the "Import Playlist" feature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _nameController.text = Provider.of<PlaylistProvider>(context, listen: false)
            .currentPlaylist!.name;
      }
    });
  }
  
  Future<void> _deletePlaylist() async {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    final playlist = provider.currentPlaylist;
    
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmDelete) {
      try {
        await provider.deletePlaylist(playlist!.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist deleted successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete playlist: $e')),
          );
        }
      }
    }
  }
  
  void _navigateToSongPage(Song song) {
    final audioService = Provider.of<AudioService>(context, listen: false);
    audioService.playSong(song);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongPage(song: song)),
    );
  }
  
  void _removeSongFromPlaylist(Song song) {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);

    provider.removeFromPlaylist(song.id);
    
    provider.updateCurrentPlaylist().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${song.title}" from playlist'),
          action: SnackBarAction(
            label: 'Undo',
            backgroundColor: const Color.fromARGB(218, 255, 255, 255),
            onPressed: () {
              provider.addToPlaylist(song);
              provider.updateCurrentPlaylist();
            },
          ),
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove song: $e')),
      );
    });
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    final playlist = provider.currentPlaylist;
    if (playlist == null) return;

    try {
      // Use the appropriate provider method
      await provider.updatePlaylist(
        playlist.id,
        name: name,
      );
      
      setState(() {
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist name updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update playlist: $e')),
      );
    }
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          isPlaylistSearch: true,
          onSongSelected: (song) {
            final provider = Provider.of<PlaylistProvider>(context, listen: false);
            final playlist = provider.currentPlaylist;
            if (playlist != null) {
              // Use provider method directly
              provider.addSongToPlaylist(playlist.id, song).catchError((e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add song: $e')),
                  );
                }
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final playlist = playlistProvider.currentPlaylist;
        if (playlist == null) {
          return const Scaffold(
            body: Center(
              child: Text('No playlist selected'),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: _isEditing 
              ? TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Playlist name',
                  ),
                )
              : Text(playlist.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _sharePlaylist,
                tooltip: 'Share playlist',
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveChanges,
                  tooltip: 'Save',
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _toggleEditMode,
                  tooltip: 'Edit name',
                ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deletePlaylist,
                tooltip: 'Delete playlist',
              ),
            ],
          ),
          body: Column(
            children: [
              // Playlist header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
                child: Row(
                  children: [
                    // Playlist artwork or placeholder
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: playlist.songs.isNotEmpty && playlist.songs.first.imageUrl.isNotEmpty
                              ? NetworkImage(playlist.songs.first.imageUrl)
                              : const AssetImage('assets/images/default_playlist.png') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Playlist info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PLAYLIST',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            playlist.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${playlist.songs.length} song${playlist.songs.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Songs list
              Expanded(
                child: playlist.songs.isEmpty 
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No songs in this playlist',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Search for songs and add them to your playlist',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: playlist.songs.length,
                      onReorder: (oldIndex, newIndex) {
                        // Use provider method for reordering
                        playlistProvider.reorderSongs(oldIndex, newIndex);
                        
                        // Update database
                        playlistProvider.updateCurrentPlaylist();
                      },
                      itemBuilder: (context, index) {
                        final song = playlist.songs[index];
                        
                        // Check if this song is currently playing
                        final audioService = Provider.of<AudioService>(context);
                        final isPlayingThisSong = audioService.currentSong?.id == song.id && 
                                                audioService.isPlaying;
                        
                        return Dismissible(
                          key: Key('song_${song.id}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _removeSongFromPlaylist(song),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: song.imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(song.imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              ),
                              child: song.imageUrl.isEmpty
                                ? Icon(
                                    Icons.music_note,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : isPlayingThisSong
                                  ? Container(
                                      color: Colors.black.withOpacity(0.5),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                fontWeight: isPlayingThisSong ? FontWeight.bold : null,
                                color: isPlayingThisSong 
                                  ? Theme.of(context).colorScheme.primary 
                                  : null,
                              ),
                            ),
                            subtitle: Text(song.artist),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                            onTap: () => _navigateToSongPage(song),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _navigateToSearch,
            child: const Icon(Icons.add),
          ),
          // Add the mini player
          bottomNavigationBar: const MiniPlayer(),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}