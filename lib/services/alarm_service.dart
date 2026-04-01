import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isStopping = false;

  Future<void> playAlarm() async {
    if (_isPlaying) return;
    
    // Cargar configuración guardada
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getInt('alarm_volume') ?? 80;
    final duration = prefs.getInt('alarm_duration') ?? 30;
    
    try {
      _isPlaying = true;
      _isStopping = false;
      
      // Reproducir alarma
      await _audioPlayer.play(AssetSource('sounds/jacocosound.wav'));
      await _audioPlayer.setVolume(volume / 100.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      print('🔔 Alarma sonando - Volumen: $volume%, Duración: ${duration}s');
      
      // Detener automáticamente después de la duración configurada
      Future.delayed(Duration(seconds: duration), () {
        if (_isPlaying && !_isStopping) {
          stopAlarm();
          print('⏰ Alarma detenida automáticamente después de ${duration}s');
        }
      });
      
    } catch (e) {
      print('Error reproduciendo alarma: $e');
      _isPlaying = false;
    }
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;
    
    _isStopping = true;
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _isStopping = false;
      print('🔇 Alarma detenida manualmente');
    } catch (e) {
      print('Error deteniendo alarma: $e');
      _isStopping = false;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}