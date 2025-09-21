import 'dart:convert';
import 'package:flutter/services.dart';

class Mesh {
  static const MethodChannel _channel = MethodChannel('mesh_channel');
  static const EventChannel _events = EventChannel('mesh_events');

  static Future<void> init() async {
    await _channel.invokeMethod('init');
  }

  static Future<void> sendStructured(Map<String, dynamic> msg) async {
    await _channel.invokeMethod('send', {'msg': json.encode(msg)});
  }

  static Stream<Map<String, dynamic>> get messages {
    return _events.receiveBroadcastStream().map((event) {
      try {
        // event is expected to be a JSON string
        return json.decode(event.toString()) as Map<String, dynamic>;
      } catch (_) {
        return {"type": "chat", "msg": event.toString()};
      }
    });
  }
}
