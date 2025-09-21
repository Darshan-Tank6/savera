// package com.example.savera

// import android.content.Context
// import android.content.SharedPreferences
// import android.util.Log
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.EventChannel
// import io.flutter.plugin.common.MethodChannel
// import com.google.android.gms.nearby.Nearby
// import com.google.android.gms.nearby.connection.*
// import org.json.JSONArray
// import org.json.JSONObject
// import java.util.*

// private const val METHOD_CHANNEL = "mesh_channel"
// private const val EVENT_CHANNEL = "mesh_events"
// private const val SERVICE_ID = "savera_service"

// class MeshBridge(private val activity: FlutterActivity) {
//     private val connectionsClient: ConnectionsClient = Nearby.getConnectionsClient(activity)
//     private var localEndpointName: String = "AndroidDevice"
//     private var connectedEndpoints: MutableSet<String> = mutableSetOf()

//     private var eventSink: EventChannel.EventSink? = null
//     private val seenMessages: MutableSet<String> = mutableSetOf() // prevent loops

//     // Persistence keys
//     private val PREFS_NAME = "mesh_cache"
//     private val SOS_KEY = "sos_messages" // stored as JSON array string

//     private fun getPrefs(): SharedPreferences =
//         activity.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

//     fun setup(flutterEngine: FlutterEngine) {
//         // MethodChannel
//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
//             when (call.method) {
//                 "init" -> {
//                     startAdvertising()
//                     startDiscovery()
//                     // replay cached messages shortly after start (give discovery time)
//                     // call asynchronously so setup returns quickly
//                     android.os.Handler(activity.mainLooper).postDelayed({
//                         replayCachedMessages()
//                     }, 2000)
//                     result.success("Mesh initialized")
//                 }
//                 "send" -> {
//                     val msg = call.argument<String>("msg") ?: ""
//                     sendUserMessage(msg)
//                     result.success("Message sent: $msg")
//                 }
//                 else -> result.notImplemented()
//             }
//         }

//         // EventChannel
//         EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
//             object : EventChannel.StreamHandler {
//                 override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//                     eventSink = events
//                 }
//                 override fun onCancel(arguments: Any?) {
//                     eventSink = null
//                 }
//             }
//         )
//     }

//     private fun startAdvertising() {
//         val options = AdvertisingOptions.Builder().setStrategy(Strategy.P2P_CLUSTER).build()
//         connectionsClient.startAdvertising(localEndpointName, SERVICE_ID, connectionLifecycleCallback, options)
//             .addOnSuccessListener { Log.d("Mesh", "Started advertising") }
//             .addOnFailureListener { Log.e("Mesh", "Advertising failed: ${it.message}") }
//     }

//     private fun startDiscovery() {
//         val options = DiscoveryOptions.Builder().setStrategy(Strategy.P2P_CLUSTER).build()
//         connectionsClient.startDiscovery(SERVICE_ID, endpointDiscoveryCallback, options)
//             .addOnSuccessListener { Log.d("Mesh", "Started discovery") }
//             .addOnFailureListener { Log.e("Mesh", "Discovery failed: ${it.message}") }
//     }

//     private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
//         override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
//             Log.d("Mesh", "Found endpoint: $endpointId (${info.endpointName})")
//             connectionsClient.requestConnection(localEndpointName, endpointId, connectionLifecycleCallback)
//         }

//         override fun onEndpointLost(endpointId: String) {
//             Log.d("Mesh", "Lost endpoint: $endpointId")
//             connectedEndpoints.remove(endpointId)
//         }
//     }

//     private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
//         override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
//             Log.d("Mesh", "Connection initiated: $endpointId")
//             // accept
//             connectionsClient.acceptConnection(endpointId, payloadCallback)
//         }

//         override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
//             if (result.status.isSuccess) {
//                 Log.d("Mesh", "Connected: $endpointId")
//                 connectedEndpoints.add(endpointId)
//                 // When new connection completes, try resending cached SOS messages so they reach helpers
//                 replayCachedMessages()
//             } else {
//                 Log.e("Mesh", "Connection failed: $endpointId")
//             }
//         }

//         override fun onDisconnected(endpointId: String) {
//             Log.d("Mesh", "Disconnected: $endpointId")
//             connectedEndpoints.remove(endpointId)
//         }
//     }

//     private val payloadCallback = object : PayloadCallback() {
//         override fun onPayloadReceived(endpointId: String, payload: Payload) {
//             payload.asBytes()?.let {
//                 val raw = String(it)
//                 try {
//                     // We expect the incoming payload to be a JSON object string
//                     val json = JSONObject(raw)
//                     val id = json.optString("id", UUID.randomUUID().toString())
//                     val type = json.optString("type", "chat")

//                     // if (!seenMessages.contains(id)) {
//                     //     seenMessages.add(id)

//                     //     if (type == "sos") {
//                     //         Log.d("Mesh", "🚨 SOS received: $raw")
//                     //         // Only cache if the message's fromRole is 'user' (so helpers don't cache)
//                     //         val fromRole = json.optString("fromRole", "user")
//                     //         if (fromRole == "user") {
//                     //             cacheMessage(json.toString())
//                     //         }
//                     //     } else {
//                     //         Log.d("Mesh", "Chat from $endpointId: $raw")
//                     //     }

//                     //     // Try to send to Flutter (safe guard)
//                     //     eventSink?.let { sink ->
//                     //         try {
//                     //             sink.success(json.toString())
//                     //         } catch (e: Exception) {
//                     //             Log.w("Mesh", "Flutter not attached, dropping message")
//                     //         }
//                     //     }

//                     //     // Forward to others (rebroadcast)
//                     //     forwardMessage(json.toString(), endpointId)
//                     // }

//                     if (!seenMessages.contains(id)) {
//                         seenMessages.add(id)

//                         if (type == "sos") {
//                             Log.d("Mesh", "🚨 SOS received: $raw")
//                             val fromRole = json.optString("fromRole", "user")
//                             if (fromRole == "user") {
//                                 cacheMessage(json.toString())
//                             }
//                         } else if (type == "ack") {
//                             val sosId = json.optString("sosId")
//                             if (sosId.isNotEmpty()) {
//                                 removeCachedMessageById(sosId)
//                             }
//                             Log.d("Mesh", "✅ ACK received for SOS $sosId")
//                         } else {
//                             Log.d("Mesh", "Chat from $endpointId: $raw")
//                         }

//                         // Deliver to Flutter if running
//                         eventSink?.let { sink ->
//                             try { sink.success(json.toString()) } catch (_: Exception) {}
//                         }

//                         // Rebroadcast to peers
//                         forwardMessage(json.toString(), endpointId)
//                     }


//                 } catch (e: Exception) {
//                     Log.e("Mesh", "Invalid message: $raw")
//                 }
//             }
//         }

//         override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
//             // optional: log statuses (1 = success? depends on API)
//             Log.d("Mesh", "Payload update from $endpointId: ${update.status}")
//         }
//     }

//     // Called when Flutter sends a new message (expects a JSON-string)
//     private fun sendUserMessage(text: String) {
//         try {
//             // treat incoming text as a full JSON message (not nested)
//             val json = JSONObject(text)
//             val id = json.optString("id", UUID.randomUUID().toString())
//             json.put("id", id)

//             val type = json.optString("type", "chat")
//             seenMessages.add(id)

//             // Persist SOS messages (only if originating from a user)
//             if (type == "sos") {
//                 // Ensure we store the JSON exactly
//                 cacheMessage(json.toString())
//             }

//             // broadcast to connected peers
//             sendMessageToAll(json.toString())
//             Log.d("Mesh", "Broadcasted from flutter: ${json.toString()}")
//         } catch (e: Exception) {
//             Log.e("Mesh", "Invalid JSON from Flutter: $text")
//         }
//     }

//     // Cache helper: append to a JSON array string in SharedPreferences
//     private fun cacheMessage(msg: String) {
//         try {
//             val prefs = getPrefs()
//             val current = prefs.getString(SOS_KEY, "[]")
//             val arr = JSONArray(current)
//             arr.put(JSONObject(msg))
//             prefs.edit().putString(SOS_KEY, arr.toString()).apply()
//             Log.d("Mesh", "Cached SOS message: $msg (total ${arr.length()})")
//         } catch (e: Exception) {
//             Log.e("Mesh", "Failed to cache message: ${e.message}")
//         }
//     }

//     // Replay cached messages: send each cached message to connected peers (and to Flutter)
//     private fun replayCachedMessages() {
//         try {
//             val prefs = getPrefs()
//             val current = prefs.getString(SOS_KEY, "[]")
//             val arr = JSONArray(current)
//             if (arr.length() == 0) return
//             Log.d("Mesh", "Replaying ${arr.length()} cached SOS messages")
//             for (i in 0 until arr.length()) {
//                 val obj = arr.getJSONObject(i)
//                 val msgStr = obj.toString()
//                 // Send to peers
//                 sendMessageToAll(msgStr)
//                 // Also deliver to Flutter if attached
//                 eventSink?.let { sink ->
//                     try { sink.success(msgStr) } catch (_: Exception) {}
//                 }
//                 // mark seen so we don't loop
//                 try { seenMessages.add(JSONObject(msgStr).getString("id")) } catch (_: Exception) {}
//             }
//             // Clear the cache after replay (optional). If you want to keep until helper ack, keep it.
//             prefs.edit().putString(SOS_KEY, "[]").apply()
//             Log.d("Mesh", "Cleared cached SOS after replay (change if you prefer ack-based deletes)")
//         } catch (e: Exception) {
//             Log.e("Mesh", "Failed to replay cached messages: ${e.message}")
//         }
//     }

//     // For rebroadcasting received messages
//     private fun forwardMessage(message: String, fromEndpoint: String) {
//         val payload = Payload.fromBytes(message.toByteArray())
//         for (endpoint in connectedEndpoints) {
//             if (endpoint != fromEndpoint) {
//                 connectionsClient.sendPayload(endpoint, payload)
//             }
//         }
//         Log.d("Mesh", "Forwarded: $message (excluding $fromEndpoint)")
//     }

//     // Send to all peers
//     private fun sendMessageToAll(message: String) {
//         val payload = Payload.fromBytes(message.toByteArray())
//         for (endpoint in connectedEndpoints) {
//             connectionsClient.sendPayload(endpoint, payload)
//         }
//         Log.d("Mesh", "Broadcast: $message to $connectedEndpoints")
//     }

//     private fun removeCachedMessageById(sosId: String) {
//         try {
//             val prefs = getPrefs()
//             val current = prefs.getString(SOS_KEY, "[]")
//             val arr = JSONArray(current)
//             val newArr = JSONArray()
//             for (i in 0 until arr.length()) {
//                 val obj = arr.getJSONObject(i)
//                 if (obj.optString("id") != sosId) {
//                     newArr.put(obj)
//                 }
//             }
//             prefs.edit().putString(SOS_KEY, newArr.toString()).apply()
//             Log.d("Mesh", "Removed cached SOS $sosId")
//         } catch (e: Exception) {
//             Log.e("Mesh", "Failed to remove cached SOS: ${e.message}")
//         }
//     }

// }

package com.example.savera

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

private const val METHOD_CHANNEL = "mesh_channel"
private const val EVENT_CHANNEL = "mesh_events"
private const val SERVICE_ID = "savera_service"

class MeshBridge(private val activity: FlutterActivity) {
    private val connectionsClient: ConnectionsClient = Nearby.getConnectionsClient(activity)
    private var localEndpointName: String = "AndroidDevice"
    private var connectedEndpoints: MutableSet<String> = mutableSetOf()

    private var eventSink: EventChannel.EventSink? = null
    private val seenMessages: MutableSet<String> = mutableSetOf() // prevent loops

    // Persistence keys
    private val PREFS_NAME = "mesh_cache"
    private val SOS_KEY = "sos_messages" // stored as JSON array string

    private fun getPrefs(): SharedPreferences =
        activity.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun setup(flutterEngine: FlutterEngine) {
        // MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    startAdvertising()
                    startDiscovery()
                    // replay cached messages shortly after start (give discovery time)
                    // call asynchronously so setup returns quickly
                    android.os.Handler(activity.mainLooper).postDelayed({
                        replayCachedMessages()
                    }, 2000)
                    result.success("Mesh initialized")
                }
                "send" -> {
                    val msg = call.argument<String>("msg") ?: ""
                    sendUserMessage(msg)
                    result.success("Message sent: $msg")
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun startAdvertising() {
        val options = AdvertisingOptions.Builder().setStrategy(Strategy.P2P_CLUSTER).build()
        connectionsClient.startAdvertising(localEndpointName, SERVICE_ID, connectionLifecycleCallback, options)
            .addOnSuccessListener { Log.d("Mesh", "Started advertising") }
            .addOnFailureListener { Log.e("Mesh", "Advertising failed: ${it.message}") }
    }

    private fun startDiscovery() {
        val options = DiscoveryOptions.Builder().setStrategy(Strategy.P2P_CLUSTER).build()
        connectionsClient.startDiscovery(SERVICE_ID, endpointDiscoveryCallback, options)
            .addOnSuccessListener { Log.d("Mesh", "Started discovery") }
            .addOnFailureListener { Log.e("Mesh", "Discovery failed: ${it.message}") }
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            Log.d("Mesh", "Found endpoint: $endpointId (${info.endpointName})")
            connectionsClient.requestConnection(localEndpointName, endpointId, connectionLifecycleCallback)
        }

        override fun onEndpointLost(endpointId: String) {
            Log.d("Mesh", "Lost endpoint: $endpointId")
            connectedEndpoints.remove(endpointId)
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            Log.d("Mesh", "Connection initiated: $endpointId")
            // accept
            connectionsClient.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            if (result.status.isSuccess) {
                Log.d("Mesh", "Connected: $endpointId")
                connectedEndpoints.add(endpointId)
                // When new connection completes, try resending cached SOS messages so they reach helpers
                replayCachedMessages()
            } else {
                Log.e("Mesh", "Connection failed: $endpointId")
            }
        }

        override fun onDisconnected(endpointId: String) {
            Log.d("Mesh", "Disconnected: $endpointId")
            connectedEndpoints.remove(endpointId)
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            payload.asBytes()?.let {
                val raw = String(it)
                try {
                    // We expect the incoming payload to be a JSON object string
                    val json = JSONObject(raw)
                    val id = json.optString("id", UUID.randomUUID().toString())
                    val type = json.optString("type", "chat")

                    // if (!seenMessages.contains(id)) {
                    //     seenMessages.add(id)

                    //     if (type == "sos") {
                    //         Log.d("Mesh", "🚨 SOS received: $raw")
                    //         // Only cache if the message's fromRole is 'user' (so helpers don't cache)
                    //         val fromRole = json.optString("fromRole", "user")
                    //         if (fromRole == "user") {
                    //             cacheMessage(json.toString())
                    //         }
                    //     } else {
                    //         Log.d("Mesh", "Chat from $endpointId: $raw")
                    //     }

                    //     // Try to send to Flutter (safe guard)
                    //     eventSink?.let { sink ->
                    //         try {
                    //             sink.success(json.toString())
                    //         } catch (e: Exception) {
                    //             Log.w("Mesh", "Flutter not attached, dropping message")
                    //         }
                    //     }

                    //     // Forward to others (rebroadcast)
                    //     forwardMessage(json.toString(), endpointId)
                    // }

                    if (!seenMessages.contains(id)) {
                        seenMessages.add(id)

                        if (type == "sos") {
                            Log.d("Mesh", "🚨 SOS received: $raw")
                            val fromRole = json.optString("fromRole", "user")
                            if (fromRole == "user") {
                                cacheMessage(json.toString())
                            }
                        } else if (type == "ack") {
                            val sosId = json.optString("sosId")
                            if (sosId.isNotEmpty()) {
                                removeCachedMessageById(sosId)
                            }
                            Log.d("Mesh", "✅ ACK received for SOS $sosId")
                        } else {
                            Log.d("Mesh", "Chat from $endpointId: $raw")
                        }

                        // Deliver to Flutter if running
                        eventSink?.let { sink ->
                            try { sink.success(json.toString()) } catch (_: Exception) {}
                        }

                        // Rebroadcast to peers
                        forwardMessage(json.toString(), endpointId)
                    }


                } catch (e: Exception) {
                    Log.e("Mesh", "Invalid message: $raw")
                }
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            // optional: log statuses (1 = success? depends on API)
            Log.d("Mesh", "Payload update from $endpointId: ${update.status}")
        }
    }

    // Called when Flutter sends a new message (expects a JSON-string)
    private fun sendUserMessage(text: String) {
        try {
            // treat incoming text as a full JSON message (not nested)
            val json = JSONObject(text)
            val id = json.optString("id", UUID.randomUUID().toString())
            json.put("id", id)

            val type = json.optString("type", "chat")
            seenMessages.add(id)

            // Persist SOS messages (only if originating from a user)
            if (type == "sos") {
                // Ensure we store the JSON exactly
                cacheMessage(json.toString())
            }

            // broadcast to connected peers
            sendMessageToAll(json.toString())
            Log.d("Mesh", "Broadcasted from flutter: ${json.toString()}")
        } catch (e: Exception) {
            Log.e("Mesh", "Invalid JSON from Flutter: $text")
        }
    }

    // Cache helper: append to a JSON array string in SharedPreferences
    private fun cacheMessage(msg: String) {
        try {
            val prefs = getPrefs()
            val current = prefs.getString(SOS_KEY, "[]")
            val arr = JSONArray(current)
            arr.put(JSONObject(msg))
            prefs.edit().putString(SOS_KEY, arr.toString()).apply()
            Log.d("Mesh", "Cached SOS message: $msg (total ${arr.length()})")
        } catch (e: Exception) {
            Log.e("Mesh", "Failed to cache message: ${e.message}")
        }
    }

    // Replay cached messages: send each cached message to connected peers (and to Flutter)
    private fun replayCachedMessages() {
        try {
            val prefs = getPrefs()
            val current = prefs.getString(SOS_KEY, "[]")
            val arr = JSONArray(current)
            if (arr.length() == 0) return
            Log.d("Mesh", "Replaying ${arr.length()} cached SOS messages")
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val msgStr = obj.toString()
                // Send to peers
                sendMessageToAll(msgStr)
                // Also deliver to Flutter if attached
                eventSink?.let { sink ->
                    try { sink.success(msgStr) } catch (_: Exception) {}
                }
                // mark seen so we don't loop
                try { seenMessages.add(JSONObject(msgStr).getString("id")) } catch (_: Exception) {}
            }
            // Clear the cache after replay (optional). If you want to keep until helper ack, keep it.
            prefs.edit().putString(SOS_KEY, "[]").apply()
            Log.d("Mesh", "Cleared cached SOS after replay (change if you prefer ack-based deletes)")
        } catch (e: Exception) {
            Log.e("Mesh", "Failed to replay cached messages: ${e.message}")
        }
    }

    // For rebroadcasting received messages
    private fun forwardMessage(message: String, fromEndpoint: String) {
        val payload = Payload.fromBytes(message.toByteArray())
        for (endpoint in connectedEndpoints) {
            if (endpoint != fromEndpoint) {
                connectionsClient.sendPayload(endpoint, payload)
            }
        }
        Log.d("Mesh", "Forwarded: $message (excluding $fromEndpoint)")
    }

    // Send to all peers
    private fun sendMessageToAll(message: String) {
        val payload = Payload.fromBytes(message.toByteArray())
        for (endpoint in connectedEndpoints) {
            connectionsClient.sendPayload(endpoint, payload)
        }
        Log.d("Mesh", "Broadcast: $message to $connectedEndpoints")
    }

    private fun removeCachedMessageById(sosId: String) {
        try {
            val prefs = getPrefs()
            val current = prefs.getString(SOS_KEY, "[]")
            val arr = JSONArray(current)
            val newArr = JSONArray()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.optString("id") != sosId) {
                    newArr.put(obj)
                }
            }
            prefs.edit().putString(SOS_KEY, newArr.toString()).apply()
            Log.d("Mesh", "Removed cached SOS $sosId")
        } catch (e: Exception) {
            Log.e("Mesh", "Failed to remove cached SOS: ${e.message}")
        }
    }

}