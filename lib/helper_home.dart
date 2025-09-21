import 'dart:math';
import 'package:savera/user_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for readable timestamps
import 'mesh.dart';
import 'package:url_launcher/url_launcher.dart';

class HelperHome extends StatefulWidget {
  const HelperHome({super.key});
  @override
  State<HelperHome> createState() => _HelperHomeState();
}

class _HelperHomeState extends State<HelperHome>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _liveSOS = [];
  final List<Map<String, dynamic>> _ackSOS = [];
  final List<Map<String, dynamic>> _chats = [];
  String? _myUserName;
  String? _myRole;

  final TextEditingController _chatController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Mesh.messages.listen((msg) {
      if (msg["type"] == "sos") {
        if (!_ackSOS.any((s) => s["id"] == msg["id"])) {
          setState(() => _liveSOS.add(msg));
        }
      } else if (msg["type"] == "ack") {
        final sosId = msg["sosId"];
        final found = _liveSOS.firstWhere(
          (m) => m["id"] == sosId,
          orElse: () => {},
        );
        if (found.isNotEmpty) {
          setState(() {
            _liveSOS.removeWhere((m) => m["id"] == sosId);
            _ackSOS.add(found);
          });
        }
      } else if (msg["type"] == "chat") {
        setState(() => _chats.add(msg));
      }
    });
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await UserConfig.getUserName();
    final role = await UserConfig.getRole();
    setState(() {
      _myUserName = name;
      _myRole = role;
    });
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

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final msg = {
      "id": Random().nextInt(1 << 31).toString(),
      "type": "chat",
      "fromRole": _myRole ?? "helper",
      "userName": _myUserName, // TODO: load from UserConfig
      "msg": text,
      "timestamp": DateTime.now().toIso8601String(),
    };

    Mesh.sendStructured(msg);
    setState(() => _chats.add(msg));
    _chatController.clear();
  }

  void _ackSOS1(Map<String, dynamic> sos) {
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

  Widget _buildSOSTile(Map<String, dynamic> m, {bool acknowledged = false}) {
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

  Widget _buildChatTile1(Map<String, dynamic> m, String myUserId) {
    final role = m['fromRole'] ?? 'peer';
    final name = m['userName'] ?? role;
    final isMe = m['senderId'] == myUserId; // identify if this msg is mine

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280), // bubble max width
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.green[200] : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe
                  ? const Radius.circular(12)
                  : const Radius.circular(0),
              bottomRight: isMe
                  ? const Radius.circular(0)
                  : const Radius.circular(12),
            ),
            boxShadow: [
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
              if (!isMe) // show sender details only for received messages
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

  Widget _buildChatTile2(Map<String, dynamic> m) {
    final role = m['fromRole'] ?? 'peer';
    final name = m['userName'] ?? role;

    // check against stored username
    final isMe = (_myUserName != null && name == _myUserName);

    print("isMe: $isMe, name: $name, myUserName: $_myUserName");

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.green[200] : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe
                  ? const Radius.circular(12)
                  : const Radius.circular(0),
              bottomRight: isMe
                  ? const Radius.circular(0)
                  : const Radius.circular(12),
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

  Widget _buildChatTile3(Map<String, dynamic> m, String? myUserName) {
    final role = m['fromRole'] ?? 'peer';
    final name = m['userName'] ?? role;

    final isMe = (myUserName != null && name == myUserName);
    debugPrint("isMe: $isMe, name: $name, myUserName: $myUserName");

    // return Align(
    //   alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    //   // ... rest of bubble UI ...
    // );
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.green[200] : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe
                  ? const Radius.circular(12)
                  : const Radius.circular(0),
              bottomRight: isMe
                  ? const Radius.circular(0)
                  : const Radius.circular(12),
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

  Widget _buildChatTile(Map<String, dynamic> m) {
    final role = m['fromRole'] ?? 'peer';
    final name = m['userName'] ?? role;
    return ListTile(
      tileColor: Colors.blueGrey[50],

      // leading: const Icon(Icons.chat),
      // title: Text(m['msg']?.toString() ?? ''),
      // subtitle: Text(
      //   "From: $name ($role)\n${_formatTime(m['timestamp'])}",
      //   style: const TextStyle(fontSize: 12),
      // ),
      title: Text("$name ($role): ${m['msg']?.toString() ?? ''}"),
      subtitle: Text(
        _formatTime(m['timestamp']),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Helper Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Live SOS"),
            Tab(text: "Acknowledged SOS"),
            Tab(text: "Chat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Live SOS
          ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (_liveSOS.isEmpty)
                const Center(child: Text("No live SOS requests")),
              ..._liveSOS.map((m) => _buildSOSTile(m)),
            ],
          ),

          // Tab 2: Acknowledged SOS
          ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (_ackSOS.isEmpty)
                const Center(child: Text("No acknowledged SOS requests")),
              ..._ackSOS.map((m) => _buildSOSTile(m, acknowledged: true)),
            ],
          ),

          // Tab 3: Chat
          Column(
            children: [
              // Expanded(
              //   child: ListView(
              //     padding: const EdgeInsets.all(8),
              //     children: _chats.map((m) => _buildChatTile2(m)).toList(),
              //   ),
              // ),
              Expanded(
                child: FutureBuilder<String?>(
                  future: UserConfig.getUserName(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final myUserName = snapshot.data;

                    return ListView(
                      padding: const EdgeInsets.all(8),
                      children: _chats
                          .map((m) => _buildChatTile3(m, myUserName))
                          .toList(),
                    );
                  },
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
        ],
      ),
    );
  }
}
