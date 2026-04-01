import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmConfigScreen extends StatefulWidget {
  const AlarmConfigScreen({super.key});

  @override
  State<AlarmConfigScreen> createState() => _AlarmConfigScreenState();
}

class _AlarmConfigScreenState extends State<AlarmConfigScreen> {
  int _volume = 80;
  int _duration = 30;
  String _selectedTone = 'Predeterminado';
  bool _isLoading = false;
  final AudioPlayer _testPlayer = AudioPlayer();
  
  // Lista de tonos predefinidos
  final List<String> _systemTones = [
    'Predeterminado',
    'Alarma',
    'Timbre',
    'Sirena',
    'Campana',
  ];

  // Para iOS, usaremos sonidos del sistema con DeviceSource
  final Map<String, String> _iosSounds = {
    'Predeterminado': 'alarm.caf',
    'Alarma': 'alarm.caf',
    'Timbre': 'doorbell.caf',
    'Sirena': 'siren.caf',
    'Campana': 'bell.caf',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _testPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getInt('alarm_volume') ?? 80;
      _duration = prefs.getInt('alarm_duration') ?? 30;
      _selectedTone = prefs.getString('alarm_tone') ?? 'Predeterminado';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarm_volume', _volume);
    await prefs.setInt('alarm_duration', _duration);
    await prefs.setString('alarm_tone', _selectedTone);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testAlarm() async {
    try {
      await _testPlayer.stop();
      
      // Usar AssetSource para sonido local
      await _testPlayer.play(AssetSource('sounds/alarm.mp3'));
      await _testPlayer.setVolume(_volume / 100.0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 Probando alarma - Volumen: $_volume%'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      Future.delayed(const Duration(seconds: 3), () {
        _testPlayer.stop();
      });
      
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Error al probar la alarma')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Alarma'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tono de alarma
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tono de alarma',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedTone,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _systemTones.map((tone) {
                            return DropdownMenuItem(
                              value: tone,
                              child: Text(tone),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTone = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Volumen
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volume_up, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text(
                              'Volumen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_volume%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _volume.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          activeColor: Colors.red.shade700,
                          label: '$_volume%',
                          onChanged: (value) {
                            setState(() => _volume = value.round());
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duración
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text(
                              'Duración',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_duration segundos',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _duration.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 55,
                          activeColor: Colors.red.shade700,
                          label: '$_duration segundos',
                          onChanged: (value) {
                            setState(() => _duration = value.round());
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testAlarm,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Probar Alarma'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}