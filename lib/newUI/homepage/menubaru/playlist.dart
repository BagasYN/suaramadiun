//playlist.dart

//import 'dart:async';
//import 'dart:convert';

import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/playlistvideo.dart';

class PlaylistPage extends StatefulWidget {
  final List<Map<String, dynamic>> playlists;
  final String youtubeApiKey;
  final String youtubeChannelId;
  final bool isLoading;
  final Function(String, String) onPlaylistSelected;

  const PlaylistPage({
    required this.playlists,
    required this.youtubeApiKey,
    required this.youtubeChannelId,
    required this.isLoading,
    required this.onPlaylistSelected,
  });

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  String? selectedPlaylistId;
  String? selectedPlaylistTitle;

  @override
  Widget build(BuildContext context) {
    //final paddingHorizontal = MediaQuery.of(context).size.width * 0.04;
    //final screenHeight = MediaQuery.of(context).size.height;
    //final screenWidth = MediaQuery.of(context).size.width;

    if (selectedPlaylistId != null && selectedPlaylistTitle != null) {
      return PlaylistVideoListPage(
        playlistId: selectedPlaylistId!,
        playlistTitle: selectedPlaylistTitle!,
        youtubeApiKey: widget.youtubeApiKey,
        onBack: () {
          setState(() {
            selectedPlaylistId = null;
            selectedPlaylistTitle = null;
          });
        },
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const SizedBox(height: 20),
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.symmetric(
          //     horizontal: paddingHorizontal * 2,
          //     vertical: 20, // Tambahkan padding vertikal untuk menambah tinggi
          //   ),
          //   decoration: BoxDecoration(
          //     color: Color.fromARGB(255, 33, 72, 122),
          //     borderRadius: BorderRadius.circular(24),
          //     boxShadow: const [
          //       BoxShadow(
          //         color: Color.fromARGB(186, 141, 86, 15),
          //         blurRadius: 4,
          //         offset: Offset(0, 0),
          //       ),
          //     ],
          //   ),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: Padding(
          //           padding: EdgeInsets.only(left: 8.0),
          //           child: Center(
          //             child: Text(
          //               'Playlist',
          //               style: TextStyle(
          //                 color: Colors.white,
          //                 fontSize: screenWidth * 0.06, // font responsif
          //                 fontWeight: FontWeight.w600,
          //               ),
          //               overflow: TextOverflow.ellipsis,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          Expanded(
            child: widget.isLoading
                ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
                : GridView.builder(
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.playlists.length,
              itemBuilder: (context, index) {
                final playlist = widget.playlists[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPlaylistId = playlist['playlistId'];
                      selectedPlaylistTitle = playlist['title'];
                    });
                    widget.onPlaylistSelected(playlist['playlistId'], playlist['title']);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            playlist['thumbnail'],
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            playlist['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${playlist['videoCount']} video',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}