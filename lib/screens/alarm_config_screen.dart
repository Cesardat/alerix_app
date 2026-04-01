import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AlarmConfigScreen extends StatefulWidget {
  const AlarmConfigScreen({super.key});

  @override
  State<AlarmConfigScreen> createState() => _AlarmConfigScreenState();
}

class _AlarmConfigScreenState extends State<AlarmConfigScreen> {
  int _volume = 80;
  int _duration = 30;
  String _selectedTone = 'Predeterminado';
  String? _customTonePath;
  String? _customToneName;
  bool _isLoading = false;
  final AudioPlayer _testPlayer = AudioPlayer();
  
  // Lista de tonos predefinidos
  final List<String> _systemTones = [
    'Predeterminado',
    'Alarma 1',
    'Alarma 2',
    'Sirena',
    'Timbre',
    'Campana',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
  }

  @override
  void dispose() {
    _testPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.request();
      if (!status.isGranted) {
        debugPrint('Permiso de biblioteca multimedia denegado');
      }
    } else if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getInt('alarm_volume') ?? 80;
      _duration = prefs.getInt('alarm_duration') ?? 30;
      _selectedTone = prefs.getString('alarm_tone') ?? 'Predeterminado';
      _customTonePath = prefs.getString('custom_tone_path');
      _customToneName = prefs.getString('custom_tone_name');
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarm_volume', _volume);
    await prefs.setInt('alarm_duration', _duration);
    await prefs.setString('alarm_tone', _selectedTone);
    if (_customTonePath != null) {
      await prefs.setString('custom_tone_path', _customTonePath!);
    }
    if (_customToneName != null) {
      await prefs.setString('custom_tone_name', _customToneName!);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _selectCustomTone() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.mediaLibrary.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Se necesita acceso a la biblioteca de música')),
            );
          }
          return;
        }
      } else if (Platform.isAndroid) {
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      }
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        final appDir = await getApplicationDocumentsDirectory();
        final destination = File('${appDir.path}/custom_alarm_${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}');
        await File(filePath).copy(destination.path);
        
        // Probar el tono seleccionado - usar UrlSource con file://
        await _testPlayer.stop();
        await _testPlayer.play(UrlSource('file://${destination.path}'));
        await _testPlayer.setVolume(_volume / 100.0);
        
        Future.delayed(const Duration(seconds: 2), () {
          _testPlayer.stop();
        });
        
        setState(() {
          _customTonePath = destination.path;
          _customToneName = fileName;
          _selectedTone = 'Personalizado: $fileName';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tono seleccionado: $fileName')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error seleccionando tono: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar el tono')),
        );
      }
    }
  }

  Future<void> _testAlarm() async {
    try {
      await _testPlayer.stop();
      
      if (_selectedTone == 'Predeterminado') {
        await _testPlayer.play(AssetSource('sounds/jacocosound.mp3'));
      } else if (_selectedTone.startsWith('Personalizado:') && _customTonePath != null) {
        final file = File(_customTonePath!);
        if (await file.exists()) {
          await _testPlayer.play(UrlSource('file://$_customTonePath'));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Archivo no encontrado. Selecciona otro tono.')),
            );
          }
          return;
        }
      } else {
        await _testPlayer.play(AssetSource('sounds/jacocosound.mp3'));
      }
      
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
                          items: [
                            ..._systemTones.map((tone) {
                              return DropdownMenuItem(
                                value: tone,
                                child: Text(tone),
                              );
                            }),
                            if (_customToneName != null)
                              DropdownMenuItem(
                                value: 'Personalizado: $_customToneName',
                                child: Text('Personalizado: $_customToneName'),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTone = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _selectCustomTone,
                          icon: const Icon(Icons.music_note),
                          label: const Text('Seleccionar de mi biblioteca'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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