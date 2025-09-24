// ignore_for_file: prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables, must_call_super, prefer_typing_uninitialized_variables, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, unnecessary_null_comparison, prefer_is_empty, sized_box_for_whitespace, unused_local_variable, no_leading_underscores_for_local_identifiers, unused_field
import 'dart:async';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:lppl_93fm_suara_madiun/newUI/constants/constant.dart';
import 'package:marquee/marquee.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePlayer extends StatefulWidget {
  @override
  _HomePlayerState createState() => _HomePlayerState();
}

class _HomePlayerState extends State<HomePlayer>
    with AutomaticKeepAliveClientMixin {
  static const int MAX_SAMPLES = 44100; // Ubah nilai sesuai kebutuhan Anda
  static const String liveIndicatorText = "Siaran live sedang berlangsung";
  static String url = "https://play-93fm.madiunkota.go.id/live";
  static String youtubeApiKey = "";
  static String youtubeChannelId = "";
  int _listenersCount = 0;

  late AudioSession session;
  final _homePlayer = HomePlayer();

  List<double> audioSamples = []; // Data sampel audio
  final List<Color> colors = [
    Colors.red[900]!,
    Colors.green[900]!,
    Colors.blue[900]!,
    Colors.brown[900]!
  ];

  var duration;
  var phoneNumber = 'tel:+62351461817';
  final player = AudioPlayer();
  var position;
  late String profileLink = ""; // Deklarasikan profileLink di sini

  var urlWa =
      'https://wa.me/+6281556451817/?text=${Uri.encodeFull('Halo Radio Suara Madiun !')}';

  final List<int> visDurasi = [900, 700, 600, 800, 500];
  final _controller = SiriWaveController(); // Menambahkan SiriWaveController

  bool _isAudioPlaying = false;
  bool _isLive = false;
  // late bool _isLoadingPosts;

  late Timer _timer;
  List<Map<String, dynamic>> _instagramPosts = [];
  bool _isLoadingPosts = false;

  late List<Map<String, dynamic>> _youtubeData =
      []; // Tambahkan variabel _youtubeData

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values); // Show the system status bar
    _timer.cancel(); // Menghentikan timer
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values); // Show the system status bar
    _timer.cancel(); // Menghentikan timer
    super.dispose();
  }

  // Fungsi untuk mengambil data dari API dan memperbarui jumlah pendengar
  Future<void> _fetchListenersCount() async {
    try {
      // Lakukan panggilan HTTP ke API
      final response = await http
          .get(Uri.parse('https://play-93fm.madiunkota.go.id/status-json.xsl'));
      if (response.statusCode == 200) {
        // Parse data JSON
        final data = jsonDecode(response.body);
        // Ambil sumber pertama dari array "source"
        final firstSource = data['icestats']['source'][0];
        final listeners = firstSource['listeners'];
        setState(() {
          _listenersCount = listeners;
        });
      } else {
        print('Failed to fetch listeners count');
      }
    } catch (error) {
      print('Error fetching listeners count: $error');
    }
  }

  Future<void> initAudioSession() async {
    session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
    ));
    session.interruptionEventStream.listen((event) {
      if (event.type == AudioInterruptionType.duck) {
        // Tangani pemutusan audio (misalnya saat panggilan telepon masuk)
        stopAudio();
      } else if (event.type == AudioInterruptionType.pause) {
        // Tangani pemulihan setelah pemutusan audio
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SetUriPlay();
    playAudio();
    initAudioSession();
    fetchAllPosts();
    fetchDataAndUpdateVariablesFromFirebase();
    _fetchListenersCount();
    Timer(Duration(seconds: 2), () {
      _checkLiveStatus();
      _fetchListenersCount();
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]); // Show only the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]); // Show only the status bar
    // Fetch Instagram RSS feed
    _fetchInstagramPosts().then((instagramPosts) {
      setState(() {
        _instagramPosts = instagramPosts;
      });
    }).catchError((error) {
      print('Error fetching Instagram posts: $error');
    });

    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      _checkLiveStatus();
      _fetchListenersCount();
      fetchDataAndUpdateVariablesFromFirebase();
      print('Checking live status...'); // Tambahkan pernyataan print di sini
    });
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchListenersCount();
      print('=====UPDATE LISTENER====='); // Tambahkan pernyataan print di sini
    });
  }

  @override
  bool get wantKeepAlive => true;

  // Implementasi fungsi fetchDataFromFirebase untuk mengambil data dari Firebase
  Future<Map<String, dynamic>> fetchDataFromFirebase() async {
    try {
      final response = await http.get(Uri.parse(
          'https://live--suara-madiun-default-rtdb.firebaseio.com/.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch data from Firebase');
      }
    } catch (error) {
      print('Error fetching data from Firebase: $error');
      rethrow; // Melempar kembali error untuk ditangani di tempat lain jika diperlukan
    }
  }

  // Implementasi fungsi fetchDataAndUpdateVariablesFromFirebase untuk memperbarui variabel berdasarkan data dari Firebase
  Future<void> fetchDataAndUpdateVariablesFromFirebase() async {
    try {
      final data = await fetchDataFromFirebase();

      final firebaseYoutubeApiKey = data['youtubeApiKey'];
      final firebaseYoutubeChannelId = data['youtubeChannelId'];

      if (firebaseYoutubeApiKey != null && firebaseYoutubeChannelId != null) {
        setState(() {
          youtubeApiKey = firebaseYoutubeApiKey;
          youtubeChannelId = firebaseYoutubeChannelId;
        });
        print('youtubeApiKey: $youtubeApiKey');
        print('youtubeChannelId: $youtubeChannelId');
      }
    } catch (error) {
      print('Error fetching data from Firebase: $error');
    }
  }

  void loadAudioSamples() {
    final audioPlayer = player;
    if (audioPlayer != null) {
      final bufferedPositionStream = audioPlayer.bufferedPositionStream;
      bufferedPositionStream.listen((bufferedPosition) {
        setState(() {
          audioSamples.add(bufferedPosition.inMilliseconds.toDouble());
          if (audioSamples.length > MAX_SAMPLES) {
            audioSamples.removeAt(
                0); // Hapus sampel tertua jika jumlah sampel melebihi batas maksimum
          }
        });
      });
    }
  }

  void launchInstagramProfile(Uri profileLink) async {
    var url = 'https://www.instagram.com/93fmsuaramadiun/';

    if (await canLaunch(url)) {
      await launch(
        url,
        universalLinksOnly: true,
      );
    } else {
      throw 'There was a problem to open the url: $url';
    }
  }

  Future<void> launchWa(Uri noWa) async {
    if (await launchUrl(noWa)) {
    } else {
      throw 'Could not launch $noWa';
    }
  }

  void updateVisualPosition(Duration bufferPosition) {
    setState(() {});
  }

  double calculateVisualPosition(Duration bufferPosition) {
    return bufferPosition.inMilliseconds.toDouble();
  }

  void setWaveAmplitude(double volume) {
    // Map nilai volume dari rentang 0-1 ke rentang 0-100
    var amplitudeValue = volume * 100;
    _controller
        .setAmplitude(amplitudeValue); // Gunakan controller yang disediakan
  }

  Future<void> SetUriPlay() async {
    duration = await player.setUrl(url);
  }

  Future<void> playAudio() async {
    if (!_isAudioPlaying) {
      // Periksa apakah audio tidak sedang diputar
      await player.play();
      setState(() {
        _isAudioPlaying = true; // Atur status pemutaran audio menjadi true
      });
    }
  }

  void stopAudio() {
    if (_isAudioPlaying) {
      // Periksa apakah audio sedang diputar
      player.stop();
      setState(() {
        _isAudioPlaying = false; // Atur status pemutaran audio menjadi false
      });
    }
  }

  Future<void> _checkLiveStatus() async {
    print('_checkLiveStatus() is being executed');
    try {
      final response = await http.get(Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$youtubeChannelId&eventType=live&type=video&key=$youtubeApiKey'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final items = jsonData['items'];
        final bool isLive = items.isNotEmpty;
        setState(() {
          _isLive = isLive;
          _youtubeData = List<Map<String, dynamic>>.from(items);
        });
      } else {
        throw Exception('Failed to fetch live status');
      }
    } catch (e) {
      print('Error checking live status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInstagramPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final response = await http
          .get(Uri.parse('https://rss.app/feeds/v1.1/oBYCZ1GV2crnFf21.json'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String profileLinkIcon = responseData['home_page_url'];
        final List<Map<String, dynamic>> instagramPosts =
            List<Map<String, dynamic>>.from(responseData['items']);

        profileLink = profileLinkIcon; // Simpan link profile Instagram
        return instagramPosts
            .map((post) => {
                  'title': post['title'],
                  'description': post['attachments'] ?? '',
                  'url': post['url'],
                  'image': post['attachments'] != null &&
                          post['attachments'].isNotEmpty
                      ? post['attachments'][0]['url']
                      : null,
                })
            .toList();
      } else {
        throw Exception('Failed to load Instagram posts');
      }
    } catch (error) {
      print('Error fetching Instagram posts: $error');
      return [];
    } finally {
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> fetchAllPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _instagramPosts = []; // Pastikan list kosong sebelum mengambil data
    });

    // Fetch Instagram posts
    List<Map<String, dynamic>> instagramPosts = await _fetchInstagramPosts();

    // Tambahkan postingan Instagram ke dalam list _instagramPosts
    _instagramPosts.addAll(instagramPosts);

    // Fetch KabarWarga posts dan tambahkan ke list _instagramPosts
    await _fetchKabarWargaAPI();

    setState(() {
      _isLoadingPosts = false;
    });
  }

  Future<void> _fetchKabarWargaAPI() async {
    final url =
        Uri.parse('https://kominfo.madiunkota.go.id/api/berita/getKabarWarga');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': 'nirmalacantik',
          'password': password1,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Cek isi respons API

      // Memeriksa apakah status code adalah 2xx (berhasil)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body)['data'];

        // Hanya mengambil 3 postingan terbaru
        final kabarWargaPosts = data.take(3).toList().reversed.map((item) {
          return {
            'title': item['judul'],
            'description': item['content'],
            'url': item['link'],
            'image': item['gambar'],
          };
        }).toList();

        setState(() {
          _instagramPosts.addAll(kabarWargaPosts);
        });

        print(
            'Kabar Warga data successfully loaded: ${_instagramPosts.length} posts added.');
      } else {
        print('Failed to load Kabar Warga data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching Kabar Warga posts: $error');
    }
  }

  Widget buildInstagramCarousel(
      Size size, List<Map<String, dynamic>> instagramPosts) {
    return Container(
      width: size.width,
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: CarouselSlider.builder(
        itemCount: instagramPosts.length,
        itemBuilder: (context, index, realIndex) {
          final post = instagramPosts[index];
          final imageUrl = post['image'];
          final title = post['title'] ?? '';
          final profileLink = post['url'];

          return Container(
            width: size.width,
            child: InstagramCard(
              imageUrl: imageUrl,
              title: title,
              profileLink: profileLink,
            ),
          );
        },
        options: CarouselOptions(
          height: 300,
          aspectRatio: 16 / 9,
          viewportFraction: 1.0,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 5),
          autoPlayAnimationDuration: Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          pauseAutoPlayOnTouch: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Membuat latar belakang memperluas ke belakang appbar
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage("assets/img/bglppl.jpg"),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffDFEAFE), Color(0xffECF5FC)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image.asset(
                        "assets/img/logopemkotxradio.png",
                        width: 150,
                        height: 80,
                        fit: BoxFit.fitWidth,
                      ),
                      SizedBox(width: 90),
                      Row(
                        children: [
                          // Ganti IconButton dengan Image.asset
                          Image.asset(
                            'assets/img/listen.png', // Ganti dengan path gambar ikon Anda
                            width:
                                30, // Sesuaikan lebar gambar sesuai kebutuhan Anda
                            height:
                                30, // Sesuaikan tinggi gambar sesuai kebutuhan Anda
                            color: Colors
                                .white, // Sesuaikan warna gambar sesuai kebutuhan Anda
                          ),
                          SizedBox(
                              width:
                                  5), // Tambahkan jarak antara gambar dan teks
                          Text(
                            ' $_listenersCount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 159, 34),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isLive)
                    GestureDetector(
                      onTap: () {
                        if (_isLive && _youtubeData.isNotEmpty) {
                          final videoId = _youtubeData[0]['id']
                              ['videoId']; // Perbaiki pengambilan videoId
                          final url =
                              'https://www.youtube.com/watch?v=$videoId';
                          launchUrl(Uri.parse(url));
                        }
                      },
                      child: Image.asset(
                        'assets/img/live.gif',
                        width: 150,
                        height: 80,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 300,
              child: _isLoadingPosts
                  ? Center(child: CircularProgressIndicator())
                  : _instagramPosts == null || _instagramPosts.isEmpty
                      ? Center(child: Text('No Instagram posts available'))
                      : buildInstagramCarousel(size, _instagramPosts),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 25),
                      child: IconButton(
                        iconSize: 30,
                        padding: EdgeInsets.zero,
                        color: Colors.white,
                        onPressed: () {
                          launchInstagramProfile(Uri.parse(profileLink));
                        },
                        icon: Icon(FontAwesomeIcons.instagram),
                      ),
                    ),
                    IconButton(
                      iconSize: 30,
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      onPressed: () {
                        launchUrl(Uri.parse(
                            "https://www.youtube.com/channel/UC4kRQ6WcPUEu3Sa74FBliKQ"));
                      },
                      icon: Icon(FontAwesomeIcons.youtube),
                    ),
                    SizedBox(width: 5),
                    IconButton(
                      iconSize: 30,
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      onPressed: () {
                        launchUrl(Uri.parse(urlWa));
                      },
                      icon: Icon(FontAwesomeIcons.whatsapp),
                    ),
                    SizedBox(width: 5),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(right: 35),
                  child: IconButton(
                    iconSize: 25,
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    onPressed: () {
                      launchUrl(Uri.parse(phoneNumber));
                    },
                    icon: Icon(FontAwesomeIcons.phoneVolume),
                  ),
                ),
              ],
            ),
            Expanded(
              flex: 1,
              child: AudioPlayerWidget(
                player: player,
                audioSamples: audioSamples,
                updateVisualPosition: updateVisualPosition,
                isPlaying:
                    _isAudioPlaying, // Pass the audio playing status to AudioPlayerWidget
                playAudio:
                    playAudio, // Pass the playAudio method to AudioPlayerWidget
                stopAudio:
                    stopAudio, // Pass the stopAudio method to AudioPlayerWidget
              ),
            ),
            SizedBox(height: 80),
            Image.asset("assets/img/follow.png",
                width: 200, fit: BoxFit.fitHeight // Penyesuaian ukuran gambar
                ),
            SizedBox(
                height: size.height *
                    0.02), // Mengatur jarak antara gambar dan widget berikutnya
          ],
        ),
      ),
    );
  }
}

class InstagramCard extends StatelessWidget {
  InstagramCard({
    required this.imageUrl,
    required this.title,
    required this.profileLink,
  });

  final String title;
  final String imageUrl;
  final String profileLink;

  void launchInstagramProfile(Uri profileLink) async {
    if (await launchUrl(profileLink)) {
      // Berhasil membuka tautan
    } else {
      // Gagal membuka tautan
      throw 'Could not launch $profileLink';
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        if (profileLink.isNotEmpty) {
          // tambahkan pengecekan ini
          launchInstagramProfile(Uri.parse(profileLink));
          print("url $profileLink");
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20),
                bottomRight:
                    Radius.circular(20)), // Menambahkan efek lengkungan
          ),
          child: Container(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  width: size.width,
                  height: size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        20.0), // Menambahkan efek lengkungan
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.fitWidth,
                      width: size.width,
                      height: size.height,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  AudioPlayerWidget({
    Key? key,
    required this.player,
    required this.audioSamples,
    required this.updateVisualPosition,
    required this.isPlaying,
    required this.playAudio,
    required this.stopAudio,
  }) : super(key: key);

  final List<double> audioSamples;
  final bool isPlaying; // Tambahkan properti untuk status pemutaran audio
  final VoidCallback playAudio; // Tambahkan properti untuk metode playAudio
  final AudioPlayer player;
  final VoidCallback stopAudio; // Tambahkan properti untuk metode stopAudio
  final void Function(Duration) updateVisualPosition;

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  double _amplitude = 0.0;
  late SiriWaveController _controller;
  bool _isPlaying = false;
  String _nowPlayingTitle = '';
  late Timer _timerPlaying;

  Future<void> fetchNowPlayingTitle() async {
    try {
      final response = await http
          .get(Uri.parse('https://play-93fm.madiunkota.go.id/status-json.xsl'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['icestats']['source'][1]
            ['title']; // Ambil judul lagu dari sumber kedua
        setState(() {
          _nowPlayingTitle = title; // Perbarui judul lagu yang sedang diputar
        });
      } else {
        throw Exception('Failed to fetch now playing title');
      }
    } catch (error) {
      print('Error Pengambilan Data title: $error');
    }
  }

  @override
  void dispose() {
    widget.player.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = SiriWaveController();

    widget.player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed ||
          playerState.processingState == ProcessingState.idle) {
        setState(() {
          _isPlaying = false;
          _updateAmplitude(0.0);
        });
      } else if (playerState.processingState == ProcessingState.ready ||
          playerState.processingState == ProcessingState.buffering ||
          playerState.processingState == ProcessingState.ready) {
        setState(() {
          _isPlaying = true;
          _updateAmplitude(1.0);
        });
      }
    });
    fetchNowPlayingTitle();
    _timerPlaying = Timer.periodic(Duration(seconds: 40), (timer) {
      fetchNowPlayingTitle();

      print(
          '=====UPDATE NowPlaying====='); // Tambahkan pernyataan print di sini
    });
  }

  void _updateAmplitude(double amplitude) {
    setState(() {
      _amplitude = amplitude;
      _controller.setAmplitude(_amplitude);
    });
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      widget.stopAudio(); // Stop audio if it's playing
      setState(() {
        _isPlaying = false; // Update playback status
      });
    } else {
      widget.playAudio(); // Start audio if it's not playing
      setState(() {
        _isPlaying = true; // Update playback status
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Container(
                  width: size.width *
                      0.8, // Ukuran lebar sesuai dengan parent (Expanded)
                  height: size.height *
                      0.1, // Atur tinggi sesuai kebutuhan atau gunakan ukuran yang cocok
                  child: SiriWave(
                    controller: _controller,
                    style: SiriWaveStyle.ios_9,
                    options: SiriWaveOptions(
                      height: size.height * 0.2,
                      width: kIsWeb ? 600 : 360,
                      showSupportBar: true,
                      backgroundColor: Colors.black,
                    ),
                  ),
                ),
                Container(
                  width: size.width *
                      0.8, // Ukuran lebar sesuai dengan parent (Expanded)
                  height: size.height *
                      0.02, // Atur tinggi sesuai kebutuhan atau gunakan ukuran yang cocok
                  child: Marquee(
                      text:
                          _nowPlayingTitle.isNotEmpty ? _nowPlayingTitle : "-",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      blankSpace: 70,
                      velocity: 50,
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      showFadingOnlyWhenScrolling: true,
                      fadingEdgeStartFraction: 0.1,
                      fadingEdgeEndFraction: 0.1),
                ),
              ],
            ),
          ),
          Container(
            height: size.height * 0.1,
            padding: const EdgeInsets.only(top: 0.0),
            child: ElevatedButton(
              onPressed: () {
                if (_isPlaying) {
                  widget.player.stop(); // Stop audio if it's playing
                } else {
                  widget.player.play(); // Start audio if it's not playing
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: CircleBorder(),
                elevation: 5,
                padding: EdgeInsets.all(10),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _isPlaying
                    ? Icon(Icons.stop, size: 50, color: Colors.white)
                    : Icon(Icons.play_circle_filled,
                        size: 50, color: Colors.white),
              ),
            ),
          ),
          SizedBox(
            height: size.height * 0.01,
          ),
        ],
      ),
    );
  }
}
