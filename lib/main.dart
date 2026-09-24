import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const GestorFiwiApp());
}

class GestorFiwiApp extends StatelessWidget {
  const GestorFiwiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Fiwi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class DeviceModel {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String ip;
  final String mac;
  bool isBlocked;

  DeviceModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.ip,
    required this.mac,
    this.isBlocked = false,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _wifiName = "Cargando red...";
  bool _isScanning = false;

  final List<DeviceModel> _devices = [
    DeviceModel(
      id: '1',
      name: 'Teléfono Principal',
      brand: 'Samsung',
      model: 'Galaxy A13 5G',
      ip: '192.168.1.15',
      mac: '44:55:66:77:88:99',
      isBlocked: false,
    ),
    DeviceModel(
      id: '2',
      name: 'Televisor Sala',
      brand: 'Samsung',
      model: 'Crystal UHD 4K',
      ip: '192.168.1.22',
      mac: 'AA:BB:CC:DD:EE:FF',
      isBlocked: false,
    ),
    DeviceModel(
      id: '3',
      name: 'Computadora Trabajo',
      brand: 'HP',
      model: 'Pavilion 15',
      ip: '192.168.1.45',
      mac: '11:22:33:44:55:66',
      isBlocked: true,
    ),
    DeviceModel(
      id: '4',
      name: 'Dispositivo Invitado',
      brand: 'Xiaomi',
      model: 'Redmi Note 12',
      ip: '192.168.1.88',
      mac: '99:88:77:66:55:44',
      isBlocked: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _obtenerInfoRed();
  }

  Future<void> _obtenerInfoRed() async {
    final info = NetworkInfo();
    try {
      String? wifiName = await info.getWifiName();
      setState(() {
        _wifiName = wifiName != null && wifiName.isNotEmpty
            ? wifiName.replaceAll('"', '')
            : "Red Wi-Fi Local";
      });
    } catch (e) {
      setState(() {
        _wifiName = "Red Local Conectada";
      });
    }
  }

  Future<void> _mostrarNotificacion(String titulo, String cuerpo) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gestor_fiwi_channel',
      'Gestor Fiwi Alertas',
      channelDescription: 'Notificaciones de estado de dispositivos Wi-Fi',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      titulo,
      cuerpo,
      platformChannelSpecifics,
    );
  }

  void _escanearRed() async {
    setState(() {
      _isScanning = true;
    });
    await _obtenerInfoRed();
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isScanning = false;
    });
    _mostrarNotificacion(
      "Escaneo completado",
      "Red actual: $_wifiName. ${_devices.length} dispositivos analizados.",
    );
  }

  void _toggleDeviceBlock(DeviceModel device, bool value) {
    setState(() {
      device.isBlocked = value;
    });

    String estado = value ? "bloqueado con éxito" : "desbloqueado y con acceso";
    _mostrarNotificacion(
      "Control de Dispositivo",
      "${device.brand} ${device.model} ha sido $estado.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor Fiwi - Dispositivos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _escanearRed,
            tooltip: 'Escanear red',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.deepPurple.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.wifi, color: Colors.deepPurple, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Red Wi-Fi Activa:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _wifiName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dispositivos Conectados (Marca y Modelo):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: device.isBlocked
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        device.isBlocked ? Icons.block : Icons.devices,
                        color: device.isBlocked ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(
                      '${device.brand} ${device.model}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Nombre: ${device.name}\nIP: ${device.ip} | MAC: ${device.mac}',
                    ),
                    isThreeLine: true,
                    trailing: Switch(
                      value: device.isBlocked,
                      activeColor: Colors.red,
                      onChanged: (bool value) {
                        _toggleDeviceBlock(device, value);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
