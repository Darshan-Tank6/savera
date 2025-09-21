import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'user_config.dart';
import 'mesh.dart';
import 'dart:math';

class UserHome extends StatefulWidget {
  const UserHome({super.key});
  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _inbox = []; // SOS and system messages
  final List<Map<String, dynamic>> _chats = []; // chat messages
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

  Widget _buildChatTile(Map<String, dynamic> m) {
    final role = m['fromRole'] ?? 'peer';
    final name = m['userName'] ?? role;

    final isMe = (_myUserName != null && name == _myUserName);
    print(
      "isMe: $isMe, name: $name, myUserName: $_myUserName role: $role, msg: ${m['fromRole']}",
    );
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.green[200] : Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(12),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe) // only show sender for others
                Text(
                  "$name ($role)",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                m['msg']?.toString() ?? '',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(m['timestamp']),
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final msg = {
      "id": Random().nextInt(1 << 31).toString(),
      "type": "chat",
      "fromRole": _myRole ?? "user",
      "userName": _myUserName ?? "Anonymous",
      "msg": text,
      "timestamp": DateTime.now().toIso8601String(),
    };

    Mesh.sendStructured(msg);
    setState(() => _chats.add(msg));
    _chatController.clear();
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

  Widget _buildSOSTile(Map<String, dynamic> m) {
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

  List<Map<String, dynamic>> get _liveSOS =>
      _inbox.where((m) => m['type'] == 'sos').toList();

  List<Map<String, dynamic>> get _ackedSOS =>
      []; // TODO: keep track of acked SOS separately if needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Live SOS"),
            // Tab(text: "Acknowledged SOS"),
            Tab(text: "Chat"),
            Tab(text: "Send SOS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Live SOS
          ListView(
            padding: const EdgeInsets.all(8),
            children: _liveSOS.map(_buildSOSTile).toList(),
          ),

          // Tab 2: Acknowledged SOS (empty for now)
          // ListView(
          //   padding: const EdgeInsets.all(8),
          //   children: _ackedSOS.map(_buildSOSTile).toList(),
          // ),

          // Tab 3: Chat
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: _chats.map(_buildChatTile).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: const InputDecoration(
                          hintText: "Enter message",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendChat,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tab 4
          // Tab 4: SOS Request
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
        ],
      ),
    );
  }
}
