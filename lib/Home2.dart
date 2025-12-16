//Home2.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:lppl_93fm_suara_madiun/newUI/constants/constant.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/bottom_navigation.dart';
import 'package:lppl_93fm_suara_madiun/newUI/radioscreen.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/playlistvideo.dart';
import 'package:lppl_93fm_suara_madiun/newUI/homepage/menubaru/playlist.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const String instagramFeedUrl =
      'https://rss.app/feeds/v1.1/oBYCZ1GV2crnFf21.json';
  static const String kabarWargaUrl =
      'https://kominfo.madiunkota.go.id/api/berita/getKabarWarga';

  final ScrollController _playlistScrollController = ScrollController();
  Timer? _playlistAutoScrollTimer;

  List<Map<String, dynamic>> _instagramPosts = [];
  List<Map<String, dynamic>> _kabarWarga = [];
  List<Map<String, dynamic>> _madiunTodayPosts = [];
  Map<String, dynamic>? _liveStreamData;

  bool _isLoadingPosts = false;
  String profileLink = "";
  int _selectedIndex = 0;

  List<Map<String, dynamic>> playlists = [];
  bool isLoadingPlaylist = true;
  static String youtubeApiKey = "";
  static String youtubeChannelId = "";
  String? selectedPlaylistId;
  String? selectedPlaylistTitle;

  int _currentPage = 1;
  final int _perPage = 8;

  String _selectedNewsFilter = 'All';
  final List<String> _newsFilters = [
    'All',
    'Madiun Today',
    'Kabar Warga',
    'Instagram Post',
  ];

  static const List<String> _dateKeys = [
    'published',
    'pubDate',
    'date',
    'created_at',
    'timestamp',
    'isoDate'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllPosts();
    _fetchDataAndUpdateVariablesFromFirebase();
    _playlistAutoScrollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _autoScrollPlaylists());
  }

  @override
  void dispose() {
    _playlistAutoScrollTimer?.cancel();
    _playlistScrollController.dispose();
    super.dispose();
  }

  void _autoScrollPlaylists() {
    if (_playlistScrollController.hasClients && playlists.isNotEmpty) {
      final maxScroll = _playlistScrollController.position.maxScrollExtent;
      final current = _playlistScrollController.offset;
      const step = 200.0;
      final next = current + step;

      if (next >= maxScroll) {
        _playlistScrollController.animateTo(0,
            duration: const Duration(seconds: 1), curve: Curves.easeInOut);
      } else {
        _playlistScrollController.animateTo(next,
            duration: const Duration(seconds: 1), curve: Curves.easeInOut);
      }
    }
  }

  //api youtube
  Future<Map<String, dynamic>> _fetchDataFromFirebase() async {
    try {
      final res = await http
          .get(Uri.parse('https://live--suara-madiun-default-rtdb.firebaseio.com/.json'));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception('Failed to fetch data from Firebase');
    } catch (e) {
      debugPrint('Error fetching data from Firebase: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> _fetchDataAndUpdateVariablesFromFirebase() async {
    try {
      final data = await _fetchDataFromFirebase();
      final firebaseYoutubeApiKey = data['youtubeApiKey'] as String?;
      final firebaseYoutubeChannelId = data['youtubeChannelId'] as String?;

      if (firebaseYoutubeApiKey != null && firebaseYoutubeChannelId != null) {
        youtubeApiKey = firebaseYoutubeApiKey;
        youtubeChannelId = firebaseYoutubeChannelId;
        await Future.wait([
          _fetchYouTubePlaylists(),
          _fetchLiveStream(),
        ]);
      }
    } catch (e) {
      debugPrint('Error fetching data from Firebase: $e');
    }
  }

  Future<void> _fetchYouTubePlaylists() async {
    if (youtubeApiKey.isEmpty || youtubeChannelId.isEmpty) {
      setState(() => isLoadingPlaylist = false);
      return;
    }

    final List<Map<String, dynamic>> allPlaylists = [];
    String? nextPageToken;
    try {
      do {
        final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlists', {
          'part': 'snippet,contentDetails',
          'channelId': youtubeChannelId,
          'maxResults': '50',
          if (nextPageToken != null) 'pageToken': nextPageToken,
          'key': youtubeApiKey,
        });

        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? <dynamic>[];
          for (final item in items) {
            final sn = item['snippet'] as Map<String, dynamic>? ?? {};
            final cd = item['contentDetails'] as Map<String, dynamic>? ?? {};
            final thumb = (sn['thumbnails'] as Map<String, dynamic>?)?['medium']
            as Map<String, dynamic>?;
            allPlaylists.add({
              'title': sn['title'] ?? '',
              'thumbnail': thumb?['url'] ?? '',
              'videoCount': cd['itemCount'] ?? 0,
              'playlistId': item['id'],
            });
          }
          nextPageToken = data['nextPageToken'] as String?;
        } else {
          throw Exception('Gagal memuat playlist');
        }
      } while (nextPageToken != null);

      if (mounted) {
        setState(() {
          playlists = allPlaylists;
          isLoadingPlaylist = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => isLoadingPlaylist = false);
    }
  }

  Future<void> _fetchLiveStream() async {
    if (youtubeApiKey.isEmpty || youtubeChannelId.isEmpty) return;

    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'channelId': youtubeChannelId,
      'eventType': 'live',
      'type': 'video',
      'key': youtubeApiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        if (mounted) {
          if (items.isNotEmpty) {
            final liveVideo = items.first as Map<String, dynamic>;
            setState(() {
              _liveStreamData = {
                'videoId': liveVideo['id']['videoId'],
                'thumbnail': liveVideo['snippet']['thumbnails']['high']['url'],
              };
            });
          } else {
            setState(() => _liveStreamData = null);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching livestream: $e');
      if (mounted) setState(() => _liveStreamData = null);
    }
  }

  Future<void> _loadAllPosts() async {
    setState(() => _isLoadingPosts = true);

    final instagramData = await _fetchInstagramPosts();
    if (mounted) setState(() => _instagramPosts = instagramData);

    await Future.wait([
      _fetchKabarWargaAPI(),
      _fetchMadiunTodayAPI(),
    ]);

    if (mounted) setState(() => _isLoadingPosts = false);
  }

  DateTime? _tryParseDate(dynamic input) {
    if (input == null) return null;
    try {
      if (input is int) {
        return input > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(input)
            : DateTime.fromMillisecondsSinceEpoch(input * 1000);
      } else if (input is String) {
        return DateTime.parse(input);
      }
    } catch (_) {}
    return null;
  }

  DateTime _getPostDate(Map<String, dynamic> post,
      {required int fallbackIndex}) {
    for (final k in _dateKeys) {
      if (post.containsKey(k)) {
        final dt = _tryParseDate(post[k]);
        if (dt != null) return dt.toUtc();
      }
    }

    if (post.containsKey('fetchedAt')) {
      final dt = _tryParseDate(post['fetchedAt']);
      if (dt != null) return dt.toUtc();
    }

    return DateTime.now().toUtc().subtract(Duration(seconds: fallbackIndex));
  }

  // filter & sorting
  List<Map<String, dynamic>> _getAllSortedPosts() {
    final allPosts = <Map<String, dynamic>>[
      ..._instagramPosts.map((e) => {...e, 'source': 'Instagram Post'}),
      ..._kabarWarga.map((e) => {...e, 'source': 'Kabar Warga'}),
      ..._madiunTodayPosts.map((e) => {...e, 'source': 'Madiun Today'}),
    ];

    final List<Map<String, dynamic>> sorted =
    List<Map<String, dynamic>>.from(allPosts);

    sorted.sort((a, b) {
      final aIndex = a['sourceOrderIndex'] is int ? a['sourceOrderIndex'] as int : 0;
      final bIndex = b['sourceOrderIndex'] is int ? b['sourceOrderIndex'] as int : 0;
      final da = _getPostDate(a, fallbackIndex: aIndex);
      final db = _getPostDate(b, fallbackIndex: bIndex);
      return db.compareTo(da);
    });

    for (var i = 0; i < sorted.length && i < 3; i++) {
      sorted[i]['isNewest'] = true;
    }

    final categories = _newsFilters.where((filter) => filter != 'All');
    for (final category in categories) {
      final categoryPosts = sorted.where((p) => p['source'] == category).toList();
      for (var i = 0; i < categoryPosts.length && i < 3; i++) {
        categoryPosts[i]['isNewest'] = true;
      }
    }

    return sorted;
  }

  Widget _buildLiveStreamCard() {
    if (_liveStreamData == null) return const SizedBox.shrink();

    final videoId = _liveStreamData!['videoId'];
    final url = 'https://www.youtube.com/watch?v=$videoId';

    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(_liveStreamData!['thumbnail']),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kami sedang siaran langsung!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchInstagramPosts() async {
    try {
      final response = await http.get(Uri.parse(instagramFeedUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        profileLink = data['home_page_url'] as String? ?? "";
        final items = data['items'] as List<dynamic>? ?? [];

        final posts = <Map<String, dynamic>>[];
        for (var i = 0; i < items.length; i++) {
          final post = items[i] as Map<String, dynamic>;
          final pub = post['isoDate'] ?? post['pubDate'] ?? post['date'];
          final fetchedAt = _tryParseDate(pub)?.toIso8601String() ??
              DateTime.now()
                  .toUtc()
                  .subtract(Duration(seconds: i))
                  .toIso8601String();

          final attachments = post['attachments'] as List<dynamic>?;
          final image = (attachments != null && attachments.isNotEmpty)
              ? (attachments[0] as Map<String, dynamic>)['url']
              : '';

          posts.add({
            'title': post['title'] ?? '',
            'url': post['url'],
            'image': image,
            'published': pub,
            'fetchedAt': fetchedAt,
            'sourceOrderIndex': i,
          });
        }
        return posts;
      }
    } catch (e) {
      debugPrint('Error fetching Instagram posts: $e');
    }
    return [];
  }

  Future<void> _fetchKabarWargaAPI() async {
    final url=
    Uri.parse('https://kominfo.madiunkota.go.id/api/berita/getKabarWarga');
    try{
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password1,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];
        final posts = <Map<String, dynamic>>[];
        for (var i = 0; i < list.length; i++) {
          final item = list[i] as Map<String, dynamic>;
          final pub = item['tanggal'] ?? item['created_at'] ?? item['date'];
          final fetchedAt = _tryParseDate(pub)?.toIso8601String() ??
              DateTime.now()
                  .toUtc()
                  .subtract(Duration(seconds: i))
                  .toIso8601String();

          posts.add({
            'title': item['judul'],
            'url': item['link'],
            'image': item['gambar'],
            'published': pub,
            'fetchedAt': fetchedAt,
            'sourceOrderIndex': i,
          });
        }
        if (mounted) setState(() => _kabarWarga = posts);
      }
    } catch (e) {
      debugPrint('Error fetching Kabar Warga: $e');
    }
  }

  Future<void> _fetchMadiunTodayAPI() async {
    try {
      final response = await http.post(
        Uri.parse('https://madiuntoday.id/api/berita/semua'),
        headers: {'passcode': passcode2},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body)['data'] as List? ?? [];
        List<Map<String, dynamic>> posts = [];

        for (int i = 0; i < data.length; i++) {
          final item = data[i];
          dynamic pub = item['tanggal'] ??
              item['date'] ??
              item['created_at'] ??
              item['published'];
          final fetchedAt = _tryParseDate(pub)?.toIso8601String() ??
              DateTime.now()
                  .toUtc()
                  .subtract(Duration(seconds: i))
                  .toIso8601String();

          posts.add({
            'title': item['slug'] ?? 'No Title',
            'url': item['link'] ?? 'No link',
            'image': item['thumbnail'] ?? '',
            'published': pub,
            'fetchedAt': fetchedAt,
            'sourceOrderIndex': i,
          });
        }

        if (mounted) setState(() => _madiunTodayPosts = posts);
      } else {
        debugPrint('MadiunToday API failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching MadiunToday: $e');
    }
  }


  // Modifikasi _onItemTapped
  void _onItemTapped(int index) {
    // Jika tombol Home (index 0) ditekan
    if (index == 0) {
      // Dan saat ini kita sedang melihat Playlist Video (selectedPlaylistId != null)
      if (selectedPlaylistId != null) {
        // Kita reset state internal playlist
        setState(() {
          selectedPlaylistId = null;
          selectedPlaylistTitle = null;
          _selectedIndex = index; // Tetap set index agar UI me-refresh
        });
        return; // Selesai, kembali ke Home List View
      }
    }

    // Jika tombol lain ditekan, atau Home ditekan dan kita sudah di List View Home
    setState(() => _selectedIndex = index);
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/img/bglppl.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const RadioScreen(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(0.1, 0), end: Offset.zero)
                            .animate(animation),
                        child: child,
                      ),
                    ),
                    child: _getSelectedPage(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar:
      BottomNavBar(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const KeyedSubtree(key: ValueKey(0), child: SizedBox())
            .childOr(_buildSpotifyStyleHome());
      case 1:
        return KeyedSubtree(key: const ValueKey(1), child: _buildAllNewsPage());
      case 2:
        return KeyedSubtree(
          key: const ValueKey(2),
          child: PlaylistPage(
            playlists: playlists,
            youtubeApiKey: youtubeApiKey,
            youtubeChannelId: youtubeChannelId,
            isLoading: isLoadingPlaylist,
            onPlaylistSelected: (id, title) {
              setState(() {
                selectedPlaylistId = id;
                selectedPlaylistTitle = title;
              });
            },
          ),
        );
      default:
        return KeyedSubtree(key: const ValueKey(0), child: _buildSpotifyStyleHome());
    }
  }

  //Widget _buildSpotifyStyleHomeWrapper() => _buildSpotifyStyleHome();

  Widget _buildSpotifyStyleHome() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (selectedPlaylistId != null && selectedPlaylistTitle != null) {
      return PlaylistVideoListPage(
        playlistId: selectedPlaylistId!,
        playlistTitle: selectedPlaylistTitle!,
        youtubeApiKey: youtubeApiKey,
        onBack: () => setState(() {
          selectedPlaylistId = null;
          selectedPlaylistTitle = null;
        }),
      );
    }

    final allSorted = _getAllSortedPosts();
    final kabarWarga = allSorted.where((p) => p['source'] == 'Kabar Warga').toList();
    final insta = allSorted.where((p) => p['source'] == 'Instagram Post').toList();
    final madiunToday = allSorted.where((p) => p['source'] == 'Madiun Today').toList();

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchDataAndUpdateVariablesFromFirebase();
        await _loadAllPosts();
      },
      color: Colors.white,
      backgroundColor: Colors.blueAccent,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Selamat Datang",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_liveStreamData != null)
              _buildLiveStreamCard(),
            const SizedBox(height: 20),
            _buildPlaylistSection(),
            const SizedBox(height: 20),
            _buildAutoCarouselSection("Kabar Warga", kabarWarga),
            const SizedBox(height: 20),
            _buildAutoCarouselSection("Instagram Feed", insta),
            const SizedBox(height: 20),
            _buildAutoCarouselSection("Madiun Today", madiunToday),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNewsPage() {
    final sortedPosts = _getAllSortedPosts();

    final List<Map<String, dynamic>> filteredPosts = _selectedNewsFilter == 'All'
        ? sortedPosts
        : sortedPosts.where((p) => p['source'] == _selectedNewsFilter).toList();

    final int totalPages = (filteredPosts.length / _perPage).ceil();
    final paginatedPosts =
    filteredPosts.skip((_currentPage - 1) * _perPage).take(_perPage).toList();

    return RefreshIndicator(
      onRefresh: _loadAllPosts,
      color: Colors.white,
      backgroundColor: Colors.blueAccent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Semua Berita",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: Colors.black87,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    value: _selectedNewsFilter,
                    items: _newsFilters
                        .map(
                          (filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _selectedNewsFilter = value!;
                      _currentPage = 1;
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...paginatedPosts.map((post) {
            final image = post['image'];
            final title = post['title'] ?? 'Tanpa Judul';
            final source = post['source'] ?? '';
            final isNewest = post['isNewest'] == true;
            final url = post['url'];

            return GestureDetector(
              onTap: () async {
                if (url != null && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .25),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: (image != null && image.toString().isNotEmpty)
                              ? Image.network(
                            image,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 180,
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white70),
                            ),
                          )
                              : Container(
                            height: 180,
                            color: Colors.grey[800],
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.white70),
                          ),
                        ),
                        if (isNewest)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "🔥 Terbaru",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            source,
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (totalPages > 1)
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(totalPages, (index) {
                  final isActive = _currentPage == index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _currentPage = index + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.blueAccent
                            : Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isActive ? Colors.blueAccent : Colors.white24),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistSection() {
    if (isLoadingPlaylist) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (playlists.isEmpty) {
      return const Text("Tidak ada playlist ditemukan.",
          style: TextStyle(color: Colors.white70));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Playlist YouTube",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            controller: _playlistScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPlaylistId = playlist['playlistId'];
                    selectedPlaylistTitle = playlist['title'];
                  });
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          playlist['thumbnail'],
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(playlist['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildAutoCarouselSection(String title, List<dynamic> posts) {
    if (posts.isEmpty) return const SizedBox();

    final mapped = posts.map((p) => Map<String, dynamic>.from(p)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mapped.length,
            itemBuilder: (context, index) {
              final post = mapped[index];
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final url = post['url'];
                      if (url != null && await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: 160,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: index == mapped.length - 1 ? 16 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .4),
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(12)),
                            child: (post['image'] != null && post['image'].toString().isNotEmpty)
                                ? Image.network(
                              post['image'],
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white70),
                                );
                              },
                            )
                                : Container(
                              height: 100,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['title'] ?? "Tanpa Judul",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post['source'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (post['isNewest'] == true)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "🔥 Terbaru",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}


extension _WidgetExt on Widget {
  Widget childOr(Widget other) => other;
}