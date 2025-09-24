// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';

// class RadioAudioHandler extends BaseAudioHandler {
//   final _player = AudioPlayer();
//   MediaItem? _mediaItem;

//   RadioAudioHandler() {
//     _notifyAudioHandlerAboutPlaybackEvents();
//     _player.setUrl("https://play-93fm.madiunkota.go.id/live");

//     // Inisialisasi mediaItem
//     _mediaItem = MediaItem(
//       id: 'https://play-93fm.madiunkota.go.id/live',
//       album: '93FM Radio',
//       title: 'Live Broadcast',
//       artUri: Uri.parse(
//           'https://93fm.madiunkota.go.id/media/background/record.png'), // opsional
//     );

//     // Set media item
//     mediaItem.add(_mediaItem!);
//   }

//   void _notifyAudioHandlerAboutPlaybackEvents() {
//     _player.playbackEventStream.listen((event) {
//       final playing = _player.playing;
//       final state =
//           playing ? AudioProcessingState.ready : AudioProcessingState.idle;

//       playbackState.add(playbackState.value.copyWith(
//         controls: [
//           MediaControl.stop,
//           if (!playing) MediaControl.play else MediaControl.pause,
//         ],
//         systemActions: const {
//           MediaAction.play,
//           MediaAction.pause,
//           MediaAction.stop,
//         },
//         androidCompactActionIndices: const [0, 1],
//         processingState: state,
//         playing: playing,
//       ));
//     });
//   }

//   @override
//   Future<void> play() => _player.play();

//   @override
//   Future<void> pause() => _player.pause();

//   @override
//   Future<void> stop() => _player.stop();
// }
