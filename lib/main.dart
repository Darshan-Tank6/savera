import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'landing_page.dart';
import 'mesh.dart';
import 'user_config.dart';
import 'role_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMesh();
  runApp(DisasterMeshApp());
}

Future<void> initMesh() async {
  // final statuses = await [
  //   Permission.location,
  //   Permission.bluetoothScan,
  //   Permission.bluetoothConnect,
  //   Permission.nearbyWifiDevices,
  // ].request();

  // if (statuses.values.every((s) => s.isGranted)) {
  //   await Mesh.init();
  // } else {
  //   debugPrint("❌ Missing required permissions for mesh networking");
  // }
  final permissions = [
    Permission.location,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.nearbyWifiDevices,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ];

  // Nearby Wi-Fi only on Android 13+
  // if (Platform.isAndroid) {
  //   final android = await DeviceInfoPlugin().androidInfo;
  //   if (android.version.sdkInt >= 33) {
  //     permissions.add(Permission.nearbyWifiDevices);
  //   }
  // }

  final statuses = await permissions.request();
  if (statuses.values.every((s) => s.isGranted)) {
    await Mesh.init();
  } else {
    debugPrint("❌ Missing required permissions for mesh networking");
  }
}

class DisasterMeshApp extends StatefulWidget {
  const DisasterMeshApp({super.key});

  @override
  State<DisasterMeshApp> createState() => _DisasterMeshAppState();
}

class _DisasterMeshAppState extends State<DisasterMeshApp> {
  bool _ready = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    _role = await UserConfig.getRole();
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: "DisasterMesh",
      home: _role == null ? RoleSelector(onDone: _loadRole) : DisasterApp(),
    );
  }
}
