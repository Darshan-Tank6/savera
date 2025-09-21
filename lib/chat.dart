// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:savera/mesh.dart';
// import 'package:savera/user_config.dart';

// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
//   final TextEditingController _messageController = TextEditingController();
//   final List<String> _messages = [];
//   late TabController _tabController;

//   final List<Map<String, dynamic>> _liveSOS = [];
//   final List<Map<String, dynamic>> _ackSOS = [];
//   final List<Map<String, dynamic>> _chats = [];
//   String? _myUserName;
//   String? _myRole;

//   final TextEditingController _chatController = TextEditingController();

//   @override
//   // void initState() {
//   //   super.initState();
//   //   _tabController = TabController(length: 2, vsync: this);
//   // }
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);

//     UserConfig.getUserName().then((name) {
//       setState(() => _myUserName = name);
//     });
//     UserConfig.getRole().then((role) {
//       setState(() => _myRole = role);
//     });

//     initMesh();
//   }

//   Future<void> initMesh() async {
//     final statuses = await [
//       Permission.location,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.nearbyWifiDevices,
//     ].request();

//     if (statuses.values.every((s) => s.isGranted)) {
//       await Mesh.init();
//     } else {
//       debugPrint("❌ Missing required permissions for mesh networking");
//     }
//   }

//   void _sendChat() {
//     final text = _chatController.text.trim();
//     if (text.isEmpty) return;

//     final msg = {
//       "id": Random().nextInt(1 << 31).toString(),
//       "type": "chat",
//       "fromRole": _myRole ?? "helper",
//       "userName": _myUserName, // TODO: load from UserConfig
//       "msg": text,
//       "timestamp": DateTime.now().toIso8601String(),
//     };

//     Mesh.sendStructured(msg);
//     setState(() => _chats.add(msg));
//     _chatController.clear();
//   }

//   String _formatTime(String? isoTime) {
//     if (isoTime == null) return "";
//     try {
//       final dt = DateTime.parse(isoTime);
//       return DateFormat("dd MMM yyyy, h:mm a").format(dt);
//     } catch (_) {
//       return isoTime;
//     }
//   }

//   Widget _buildChatTile3(Map<String, dynamic> m, String? myUserName) {
//     final role = m['fromRole'] ?? 'peer';
//     final name = m['userName'] ?? role;

//     final isMe = (myUserName != null && name == myUserName);
//     debugPrint("isMe: $isMe, name: $name, myUserName: $myUserName");

//     // return Align(
//     //   alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//     //   // ... rest of bubble UI ...
//     // );
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 280),
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: isMe ? Colors.green[200] : Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(12),
//               topRight: const Radius.circular(12),
//               bottomLeft: isMe
//                   ? const Radius.circular(12)
//                   : const Radius.circular(0),
//               bottomRight: isMe
//                   ? const Radius.circular(0)
//                   : const Radius.circular(12),
//             ),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 2,
//                 offset: Offset(1, 1),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: isMe
//                 ? CrossAxisAlignment.end
//                 : CrossAxisAlignment.start,
//             children: [
//               if (!isMe) // only show sender for others
//                 Text(
//                   "$name ($role)",
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               Text(
//                 m['msg']?.toString() ?? '',
//                 style: const TextStyle(fontSize: 15),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 _formatTime(m['timestamp']),
//                 style: const TextStyle(fontSize: 10, color: Colors.black54),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Chat"),
//         // bottom: TabBar(
//         //   controller: _tabController,
//         //   tabs: const [
//         //     Tab(text: "Messages"),
//         //     Tab(text: "Send Message"),
//         //   ],
//         // ),
//       ),
//       // body: Column(
//       //   children: [
//       //     Column(
//       //       children: [
//       //         // Expanded(
//       //         //   child: ListView(
//       //         //     padding: const EdgeInsets.all(8),
//       //         //     children: _chats.map((m) => _buildChatTile2(m)).toList(),
//       //         //   ),
//       //         // ),
//       //         Expanded(
//       //           child: FutureBuilder<String?>(
//       //             future: UserConfig.getUserName(),
//       //             builder: (context, snapshot) {
//       //               if (!snapshot.hasData) {
//       //                 return const Center(child: CircularProgressIndicator());
//       //               }
//       //               final myUserName = snapshot.data;

//       //               return ListView(
//       //                 padding: const EdgeInsets.all(8),
//       //                 children: _chats
//       //                     .map((m) => _buildChatTile3(m, myUserName))
//       //                     .toList(),
//       //               );
//       //             },
//       //           ),
//       //         ),

//       //         Padding(
//       //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       //           child: Row(
//       //             children: [
//       //               Expanded(
//       //                 child: TextField(
//       //                   controller: _chatController,
//       //                   decoration: const InputDecoration(
//       //                     hintText: "Enter message",
//       //                   ),
//       //                 ),
//       //               ),
//       //               IconButton(
//       //                 icon: const Icon(Icons.send),
//       //                 onPressed: _sendChat,
//       //               ),
//       //             ],
//       //           ),
//       //         ),
//       //       ],
//       //     ),
//       //   ],
//       // ),
//       body: Column(
//         children: [
//           Expanded(
//             child: FutureBuilder<String?>(
//               future: UserConfig.getUserName(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final myUserName = snapshot.data;
//                 return ListView(
//                   padding: const EdgeInsets.all(8),
//                   children: _chats
//                       .map((m) => _buildChatTile3(m, myUserName))
//                       .toList(),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _chatController,
//                     decoration: const InputDecoration(
//                       hintText: "Enter message",
//                     ),
//                   ),
//                 ),
//                 IconButton(icon: const Icon(Icons.send), onPressed: _sendChat),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:savera/mesh.dart';
import 'package:savera/user_config.dart';

// Utility for formatting time
String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

// Message model
class Message {
  final String userName;
  final String role;
  final String text;
  final DateTime timestamp;

  Message({
    required this.userName,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      userName: json['userName'] ?? 'unknown',
      role: json['role'] ?? 'user',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'role': role,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final List<Map<String, dynamic>> _chats = [];
  late final ScrollController _scrollController;
  String? _myUserName;
  String? _myRole;

  // @override
  // void initState() {
  //   super.initState();
  //   _scrollController = ScrollController();

  //   // Listen to mesh messages
  //   Mesh.messages.listen((data) {
  //     try {
  //       final msg = Message.fromJson(data);
  //       debugPrint("📩 Received from Mesh: $data");

  //       setState(() {
  //         _messages.add(msg);
  //       });
  //       _scrollToBottom();
  //     } catch (e) {
  //       debugPrint("⚠️ Failed to parse message: $e");
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Listen to mesh messages
    // Mesh.messages.listen((msg) {
    //   // if (msg["type"] == "sos") {
    //   //   if (!_ackSOS.any((s) => s["id"] == msg["id"])) {
    //   //     setState(() => _liveSOS.add(msg));
    //   //   }
    //   // } else if (msg["type"] == "ack") {
    //   //   final sosId = msg["sosId"];
    //   //   final found = _liveSOS.firstWhere(
    //   //     (m) => m["id"] == sosId,
    //   //     orElse: () => {},
    //   //   );
    //   //   if (found.isNotEmpty) {
    //   //     setState(() {
    //   //       _liveSOS.removeWhere((m) => m["id"] == sosId);
    //   //       _ackSOS.add(found);
    //   //     });
    //   //   }
    //   // } else
    //   if (msg["type"] == "chat") {
    //     setState(() => _messages.add(msg as Message));
    //   }
    // });
    // Mesh.messages.listen((data) {
    //   debugPrint("📩 Received raw Mesh event: $data");

    //   try {
    //     Map<String, dynamic> parsed;

    //     if (data is String) {
    //       parsed = jsonDecode(data) as Map<String, dynamic>;
    //     } else if (data is Map) {
    //       parsed = Map<String, dynamic>.from(data);
    //     } else {
    //       debugPrint("⚠️ Unsupported event type: ${data.runtimeType}");
    //       return;
    //     }

    //     final msg = Message.fromJson(parsed);

    //     setState(() {
    //       _messages.add(msg);
    //     });
    //     _scrollToBottom();
    //   } catch (e, st) {
    //     debugPrint("❌ Failed to parse message: $e\n$st");
    //   }
    // });
    // Mesh.messages.listen((data) {
    //   debugPrint("📩 Received raw Mesh event: $data");

    //   try {
    //     late Map<String, dynamic> parsed;

    //     if (data is String) {
    //       // Only decode if it's actually a String
    //       parsed = jsonDecode(data as String) as Map<String, dynamic>;
    //     } else if (data is Map) {
    //       // If it's already a Map, just cast it
    //       parsed = Map<String, dynamic>.from(data);
    //     } else {
    //       debugPrint("⚠️ Unsupported event type: ${data.runtimeType}");
    //       return;
    //     }

    //     final msg = Message.fromJson(parsed);

    //     setState(() {
    //       _messages.add(msg);
    //     });
    //     _scrollToBottom();
    //   } catch (e, st) {
    //     debugPrint("❌ Failed to parse message: $e\n$st");
    //   }
    // });
    Mesh.messages.listen((msg) {
      if (msg['type'] == "chat") {
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // final name = await UserConfig.getUserName() ?? "anonymous";
    // final role = await UserConfig.getRole() ?? "user";

    final msg = {
      "id": Random().nextInt(1 << 31).toString(),
      "type": "chat",
      "fromRole": _myRole ?? "user",
      "userName": _myUserName ?? "anonymous",
      "msg": text,
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      // await Mesh.sendStructured(msg.toJson());
      // setState(() {
      //   _messages.add(msg);
      // });
      // _messageController.clear();
      // _scrollToBottom();
      Mesh.sendStructured(msg);
      setState(() => _chats.add(msg));
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint("❌ Failed to send message: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to send message")));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat"), centerTitle: true),
      body: Column(
        children: [
          // Expanded(
          //   child: ListView.builder(
          //     controller: _scrollController,
          //     itemCount: _messages.length,
          //     itemBuilder: (context, index) {
          //       final msg = _messages[index];
          //       return Card(
          //         margin: const EdgeInsets.symmetric(
          //           horizontal: 8,
          //           vertical: 4,
          //         ),
          //         child: ListTile(
          //           title: Text(msg.text),
          //           subtitle: Text(
          //             "From: ${msg.userName} (${msg.role})\n${formatTime(msg.timestamp)}",
          //           ),
          //         ),
          //       );
          //     },
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
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
