import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alerix_app/screens/alarm_config_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const AlerixApp());
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _controller.forward();
    
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.warning_rounded,
                        size: 100,
                        color: Color(0xFFE53935),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'ALERIX',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE53935),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: const Color(0xFFE53935),
                    backgroundColor: Colors.grey.shade800,
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

// ==================== ANIMACIÓN DE FADE ====================
class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;

  const FadeAnimation(this.delay, this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child!,
          ),
        );
      },
      child: child,
    );
  }
}

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(settings);
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
  
  await flutterLocalNotificationsPlugin.show(
    999,
    '🔔 PRUEBA DE NOTIFICACIÓN',
    'Si ves esto, las notificaciones funcionan correctamente',
    const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
  );
  
  await showPersistentNotification();
}

Future<void> showPersistentNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'emergency_channel',
    'Emergencia',
    channelDescription: 'Canal para alertas de emergencia',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    autoCancel: false,
  );
  
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
    threadIdentifier: 'emergency',
  );
  
  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  
  await flutterLocalNotificationsPlugin.show(
    1,
    '🚨 ALERIX EMERGENCIA 🚨',
    'Presiona para activar SOS',
    details,
  );
}

class AlerixApp extends StatelessWidget {
  const AlerixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALERIX',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE53935),
          secondary: Color(0xFF1E88E5),
          tertiary: Color(0xFF43A047),
          error: Color(0xFFE53935),
          surface: Color(0xFF1E1E1E),
          onSurface: Color(0xFFB0B0B0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFE0E0E0),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFB0B0B0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
          prefixIconColor: Color(0xFFB0B0B0),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== MODELO DE CONTACTO ====================
class Contact {
  final String name;
  final String phone;
  Contact({required this.name, required this.phone});
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(name: json['name'], phone: json['phone']);
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
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }
  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await checkPermissions();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
      }
    } catch (e) {
      debugPrint('Error abriendo WhatsApp: $e');
    }
  }
}

// ==================== SERVICIO DE ALARMA (ACTUALIZADO CON MÚLTIPLES TONOS) ====================
class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isStopping = false;

  // Mapeo de tonos a archivos
  final Map<String, String> _toneFiles = {
    'Alarma 1': 'alarm1.mp3',
    'Alarma 2': 'alarm2.mp3',
    'Sirena': 'siren.mp3',
    'Campana': 'bell.mp3',
    'Alerta': 'alert.mp3',
  };

  Future<void> playAlarm() async {
    if (_isPlaying) return;
    
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getInt('alarm_volume') ?? 80;
    final duration = prefs.getInt('alarm_duration') ?? 30;
    final selectedTone = prefs.getString('alarm_tone') ?? 'Alarma 1';
    
    // Obtener el archivo correspondiente
    final toneFile = _toneFiles[selectedTone] ?? 'alarm1.mp3';
    
    try {
      _isPlaying = true;
      _isStopping = false;
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(AssetSource('sounds/$toneFile'));
      await _audioPlayer.setVolume(volume / 100.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      debugPrint('🔔 Alarma sonando: $selectedTone - Volumen: $volume%, Duración: ${duration}s');
      
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

  @override
  void initState() {
    super.initState();
    _setupNotificationTap();
  }

  void _setupNotificationTap() {
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      },
    );
  }

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
            colors: const [
              Color(0xFF1A1A1A),
              Color(0xFF121212),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeAnimation(0.2, Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.warning_rounded, size: 80, color: const Color(0xFFE53935));
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ALERIX',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE53935),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Número de teléfono',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contraseña de prueba: 1234',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            )),
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
    _setupNotificationTap();
  }

  void _setupNotificationTap() {
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _triggerEmergency();
      },
    );
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

    await _alarmService.playAlarm();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFE53935)),
              const SizedBox(height: 16),
              const Text(
                'Obteniendo ubicación...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    Position? position = await _locationService.getCurrentLocation();
    String locationLink = "Ubicación no disponible";
    if (position != null) {
      locationLink = _locationService.getLocationLink(position);
    }

    String message = "🚨 S.O.S. EMERGENCIA 🚨\n\nNecesito ayuda urgente.\n\nMi ubicación: $locationLink";

    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviando alerta a ${_contacts.length} contactos...')),
      );
    }

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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'ALERIX',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          FadeAnimation(0.1, Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Center(
              child: Text(
                'Contactos: $_contactCount/5',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          )),
          Expanded(
            child: _contacts.isEmpty
                ? FadeAnimation(0.2, Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts, size: 64, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay contactos',
                          style: TextStyle(color: Color(0xFFB0B0B0)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona + para agregar',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ))
                : FadeAnimation(0.2, ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE53935).withOpacity(0.2),
                            child: const Icon(Icons.person, color: Color(0xFFE53935)),
                          ),
                          title: Text(
                            contact.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            contact.phone,
                            style: const TextStyle(color: Color(0xFFB0B0B0)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFFE53935)),
                            onPressed: () => _deleteContact(index),
                          ),
                        ),
                      );
                    },
                  )),
          ),
          FadeAnimation(0.3, Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmConfigScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Ajustes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSosPressed ? null : _triggerEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF757575),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'X',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Agregar contacto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
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
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}