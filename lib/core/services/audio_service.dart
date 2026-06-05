import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<void> startRecording(String path) async {
    if (await hasPermission()) {
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000,
        sampleRate: 16000,
      );
      await _recorder.start(config, path: path);
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> pauseRecording() async {
    await _recorder.pause();
  }

  Future<void> resumeRecording() async {
    await _recorder.resume();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<String> getTempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/lecture_rect_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  void dispose() {
    _recorder.dispose();
  }
}
