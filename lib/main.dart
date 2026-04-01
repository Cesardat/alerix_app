import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alerix_app/screens/alarm_config_screen.dart';

void main() {
  runApp(const AlerixApp());
}

class AlerixApp extends StatelessWidget {
  const AlerixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALERIX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red.shade700,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== MODELO DE CONTACTO ====================
class Contact {
  final String name;
  final String phone;

  Contact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      phone: json['phone'],
    );
  }
}

// ==================== SERVICIO DE CONTACTOS ====================
class ContactService {
  static const String _contactsKey = 'contacts';

  Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson = contacts.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_contactsKey, contactsJson);
  }

  Future<List<Contact>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? contactsJson = prefs.getStringList(_contactsKey);
    if (contactsJson == null) return [];
    return contactsJson.map((jsonStr) => Contact.fromJson(jsonDecode(jsonStr))).toList();
  }
}

// ==================== SERVICIO DE UBICACIÓN ====================
class LocationService {
  Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await checkPermissions();
    if (!hasPermission) return null;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      return null;
    }
  }

  String getLocationLink(Position position) {
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }
}

// ==================== SERVICIO DE WHATSAPP ====================
class WhatsAppService {
  Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    String encodedMessage = Uri.encodeComponent(message);
    String url = 'https://wa.me/$cleanNumber?text=$encodedMessage';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        debugPrint('No se puede abrir WhatsApp');
      }
    } catch (e) {
      debugPrint('Error abriendo WhatsApp: $e');
    }
  }
}

// ==================== SERVICIO DE ALARMA ====================
class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isStopping = false;
  
  // URL de sonidos que funcionan en iOS
  final Map<String, String> _soundUrls = {
    'Alarma 1': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3',
    'Alarma 2': 'https://www.soundjay.com/misc/sounds/alarm-clock-01.mp3',
    'Sirena': 'https://www.soundjay.com/misc/sounds/police-siren-01.mp3',
    'Timbre': 'https://www.soundjay.com/misc/sounds/door-bell-01.mp3',
    'Campana': 'https://www.soundjay.com/misc/sounds/church-bell-01.mp3',
  };

  Future<void> playAlarm() async {
    if (_isPlaying) return;
    
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getInt('alarm_volume') ?? 80;
    final duration = prefs.getInt('alarm_duration') ?? 30;
    final selectedTone = prefs.getString('alarm_tone') ?? 'Alarma 1';
    
    try {
      _isPlaying = true;
      _isStopping = false;
      
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      
      final soundUrl = _soundUrls[selectedTone] ?? _soundUrls['Alarma 1']!;
      await _audioPlayer.play(UrlSource(soundUrl));
      await _audioPlayer.setVolume(volume / 100.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      debugPrint('🔔 Alarma sonando - Volumen: $volume%, Duración: ${duration}s');
      
      Future.delayed(Duration(seconds: duration), () {
        if (_isPlaying && !_isStopping) stopAlarm();
      });
      
    } catch (e) {
      debugPrint('Error reproduciendo alarma: $e');
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
      debugPrint('🔇 Alarma detenida');
    } catch (e) {
      debugPrint('Error deteniendo alarma: $e');
      _isStopping = false;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

// ==================== PANTALLA DE LOGIN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    if (password == "1234") {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña incorrecta. Prueba: 1234')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_rounded, size: 80, color: Colors.red.shade700),
                const SizedBox(height: 16),
                Text(
                  'ALERIX',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Número de teléfono',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contraseña de prueba: 1234',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PANTALLA PRINCIPAL ====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Contact> _contacts = [];
  int _contactCount = 0;
  final ContactService _contactService = ContactService();
  final LocationService _locationService = LocationService();
  final WhatsAppService _whatsappService = WhatsAppService();
  final AlarmService _alarmService = AlarmService();
  bool _isSosPressed = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactService.loadContacts();
    setState(() {
      _contacts = contacts;
      _contactCount = contacts.length;
    });
  }

  Future<void> _saveContacts() async {
    await _contactService.saveContacts(_contacts);
  }

  void _addContact(Contact contact) {
    if (_contactCount < 5) {
      setState(() {
        _contacts.add(contact);
        _contactCount = _contacts.length;
      });
      _saveContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacto agregado')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máximo 5 contactos')),
        );
      }
    }
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
      _contactCount = _contacts.length;
    });
    _saveContacts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacto eliminado')),
      );
    }
  }

  Future<void> _triggerEmergency() async {
    if (_isSosPressed) return;
    setState(() => _isSosPressed = true);

    // Reproducir alarma
    await _alarmService.playAlarm();

    // Mostrar diálogo de carga
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Obteniendo ubicación...'),
            ],
          ),
        ),
      );
    }

    // Obtener ubicación
    Position? position = await _locationService.getCurrentLocation();
    String locationLink = "Ubicación no disponible";
    
    if (position != null) {
      locationLink = _locationService.getLocationLink(position);
    }

    String message = "🚨 S.O.S. EMERGENCIA 🚨\n\nNecesito ayuda urgente.\n\nMi ubicación: $locationLink";

    // Cerrar diálogo de carga
    if (mounted) {
      Navigator.pop(context);
    }

    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviando alerta a ${_contacts.length} contactos...')),
      );
    }

    // Enviar mensaje a cada contacto
    for (var contact in _contacts) {
      await _whatsappService.sendWhatsAppMessage(contact.phone, message);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 EMERGENCIA ACTIVADA - Mensajes enviados a tus contactos')),
      );
    }

    setState(() => _isSosPressed = false);
  }

  void _cancelAlarm() {
    _alarmService.stopAlarm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarma cancelada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALERIX'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Contador de contactos
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Contactos: $_contactCount/5',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),
          // Lista de contactos
          Expanded(
            child: _contacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No hay contactos',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona + para agregar',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade100,
                            child: Icon(Icons.person, color: Colors.red.shade700),
                          ),
                          title: Text(
                            contact.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(contact.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteContact(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Botones inferiores
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlarmConfigScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajustes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSosPressed ? null : _triggerEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSosPressed
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'X',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar contacto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  _addContact(Contact(name: name, phone: phone));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}