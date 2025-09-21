import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:savera/mesh.dart';
import 'package:savera/user_config.dart';
import 'package:url_launcher/url_launcher.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});
  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _inbox = []; // SOS and system messages
  final List<Map<String, dynamic>> _chats = []; // chat messages
  final List<Map<String, dynamic>> _ackSOS = [];
  final TextEditingController _chatController = TextEditingController();
  late TabController _tabController;
  String? _myUserName;
  String? _myRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load username once
    // UserConfig.getUserName().then((name) {
    //   setState(() => _myUserName = name ?? "Anonymous");
    // });
    _loadUser();
    // initMesh();
    // Listen for mesh messages
    Mesh.messages.listen((msg) {
      if (msg["type"] == "ack") {
        final ackId = msg["sosId"];
        setState(() {
          _inbox.removeWhere((m) => m["id"] == ackId);
        });
        debugPrint("✅ SOS $ackId acknowledged by helper");
      } else if (msg["type"] == "chat") {
        setState(() {
          _chats.add(msg);
        });
      } else {
        setState(() {
          _inbox.add(msg);
        });
      }
    });
  }

  Future<void> initMesh() async {
    final statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    if (statuses.values.every((s) => s.isGranted)) {
      await Mesh.init();
    } else {
      debugPrint("❌ Missing required permissions for mesh networking");
    }
  }

  Future<void> _loadUser() async {
    final name = await UserConfig.getUserName();
    final role = await UserConfig.getRole();
    setState(() {
      _myUserName = name;
      _myRole = role;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return "";
    try {
      final dt = DateTime.parse(isoTime);
      return DateFormat("dd MMM yyyy, h:mm a").format(dt);
    } catch (_) {
      return isoTime;
    }
  }

  void _sendSOS(String service) async {
    final name = await UserConfig.getUserName() ?? "Anonymous";
    final role = await UserConfig.getRole() ?? "user";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint("⚠️ Location permission permanently denied.");
      return;
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("⚠️ Could not fetch GPS: $e");
    }

    final msg = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "type": "sos",
      "fromRole": role,
      "userName": name,
      "serviceType": service,
      "timestamp": DateTime.now().toIso8601String(),
      "location": {"lat": pos?.latitude ?? 0.0, "lng": pos?.longitude ?? 0.0},
    };

    Mesh.sendStructured(msg);
    setState(() => _inbox.add(msg));
  }

  Widget _buildSOSTileUser(Map<String, dynamic> m) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text("SOS: ${m['serviceType'] ?? 'unknown'}"),
        subtitle: Text(
          "From: ${m['userName'] ?? 'unknown'}\nAt: ${_formatTime(m['timestamp'])}",
        ),
      ),
    );
  }

  void _ackSOS1(Map<String, dynamic> sos) {
    if (_myRole != "helper") return;
    final ack = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "type": "ack",
      "sosId": sos["id"],
      "fromRole": "helper",
      "timestamp": DateTime.now().toIso8601String(),
    };
    Mesh.sendStructured(ack);

    setState(() {
      _liveSOS.removeWhere((m) => m["id"] == sos["id"]);
      _ackSOS.add(sos);
    });
  }

  Widget _buildSOSTileHelper(
    Map<String, dynamic> m, {
    bool acknowledged = false,
  }) {
    final lat = m['location']?['lat'];
    final lng = m['location']?['lng'];

    return Card(
      color: acknowledged ? Colors.green.shade50 : Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text("🚨 ${m['serviceType']?.toString().toUpperCase()}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "From: ${m['userName'] ?? 'unknown'}\n"
              "Time: ${_formatTime(m['timestamp'])}\n"
              "Location: $lat, $lng",
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final Uri googleMapsUri = Uri.parse(
                  "geo:$lat,$lng?q=$lat,$lng(SOS Location)",
                );

                if (await canLaunchUrl(googleMapsUri)) {
                  await launchUrl(googleMapsUri);
                } else {
                  final Uri browserUri = Uri.parse(
                    "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                  );
                  await launchUrl(
                    browserUri,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: const Text("Maps"),
            ),
          ],
        ),

        // Text(
        //   "From: ${m['userName'] ?? 'unknown'}\n"
        //   "Time: ${_formatTime(m['timestamp'])}\n"
        //   "Location: $lat, $lng",
        // ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            !acknowledged
                ? ElevatedButton(
                    onPressed: () => _ackSOS1(m),
                    child: const Text("Ack"),
                  )
                : const Text("✅ Acked"),
            const SizedBox(width: 8),
            // ElevatedButton(
            //   onPressed: () async {
            //     final double lat = m['location']?['lat'] ?? 0.0;
            //     final double lng = m['location']?['lng'] ?? 0.0;

            //     final Uri googleMapsUri = Uri.parse(
            //       "geo:$lat,$lng?q=$lat,$lng(SOS Location)",
            //     );

            //     if (await canLaunchUrl(googleMapsUri)) {
            //       await launchUrl(googleMapsUri);
            //     } else {
            //       // fallback to browser if no maps app available
            //       final Uri browserUri = Uri.parse(
            //         "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
            //       );
            //       await launchUrl(
            //         browserUri,
            //         mode: LaunchMode.externalApplication,
            //       );
            //     }
            //   },
            //   child: const Text("Maps"),
            // ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _liveSOS =>
      _inbox.where((m) => m['type'] == 'sos').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$_myRole Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Send SOS"),
            Tab(text: "Live SOS"),
            Tab(text: "Acknowledged SOS"),
            // Tab(text: "Chat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: SOS Request
          // if (_myRole == "user")
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  "Send SOS Request",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _sendSOS("ambulance"),
                      icon: const Icon(Icons.local_hospital),
                      label: const Text("Ambulance"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _sendSOS("fire"),
                      icon: const Icon(Icons.local_fire_department),
                      label: const Text("Fire"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _sendSOS("police"),
                      icon: const Icon(Icons.local_police),
                      label: const Text("Police"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tab 2: Live SOS
          (_myRole == "helper")
              ? ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (_liveSOS.isEmpty)
                      const Center(child: Text("No live SOS requests")),
                    ..._liveSOS.map((m) => _buildSOSTileHelper(m)),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: _liveSOS.map(_buildSOSTileUser).toList(),
                ),

          // Tab 3: Acknowledged SOS
          (_myRole == "helper")
              ? ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (_ackSOS.isEmpty)
                      const Center(child: Text("No acknowledged SOS requests")),
                    ..._ackSOS.map(
                      (m) => _buildSOSTileHelper(m, acknowledged: true),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (_ackSOS.isEmpty)
                      const Center(child: Text("No acknowledged SOS requests")),
                    ..._ackSOS.map(_buildSOSTileUser).toList(),
                  ],
                ),
          // Tab 2: Live SOS
          // ListView(
          //   padding: const EdgeInsets.all(8),
          //   children: _liveSOS.map(_buildSOSTileUser).toList(),
          // ),
          //
          // else
          //   const Center(
          //     child: Text("Acknowledged SOS will appear here."),
          //   ),
        ],
      ),
    );
  }
}
