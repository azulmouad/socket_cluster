# Socket Cluster

A Flutter package that provides a SocketCluster client for real-time communication. Supports iOS, Android, Web, and Desktop via `dart:io` / `dart:html` WebSocket.

## Installation

```yaml
dependencies:
  socket_cluster: ^1.1.0
```

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:socket_cluster/socket_cluster.dart';

final controller = SocketClusterController();
await controller.connect('wss://your-server.com');
```

---

## Recommended Pattern — Direct Socket API

For production apps, use the raw `Socket` API directly instead of `SocketClusterController.subscribe()`. This gives you full control over channel registration, reconnection, and lifecycle.

```dart
import 'package:socket_cluster/socket_cluster.dart';

class SocketService {
  Socket? _socket;

  Future<void> connect(String url) async {
    _socket = await Socket.connect(
      url,
      listener: _MyListener(
        onConnected: _onConnected,
        onDisconnected: _onDisconnected,
      ),
    );
  }

  void subscribe(String channelName, void Function(dynamic) onMessage) {
    final socket = _socket;
    if (socket == null) return;

    // Tell the server to start publishing this channel.
    socket.subscribe(channelName);

    // Handle #publish messages: {"event":"#publish","data":{"channel":"...","data":{...}}}
    socket.onSubscribe(channelName, (name, data) => onMessage(data));

    // handle direct events: {"event":"channelName","data":{...}}
    // Since 1.1.0: skipped automatically when onSubscribe is registered —
    // no double-fire even if the server sends both formats.
    socket.on(channelName, (name, data, ack) => onMessage(data));
  }

  void unsubscribe(String channelName) {
    _socket?.unsubscribe(channelName);
  }

  Future<void> destroy() async {
    await _controller?.destroy();
  }
}
```

### Connection event listener

Extend `BasicListener` to handle connection lifecycle:

```dart
class _MyListener extends BasicListener {
  final VoidCallback onConnected;
  final VoidCallback onDisconnected;

  _MyListener({required this.onConnected, required this.onDisconnected});

  @override
  void onConnected(Socket socket) => onConnected();

  @override
  void onDisconnected(Socket socket) => onDisconnected();

  @override
  void onConnectError(Socket socket, dynamic e) {
    debugPrint('Socket error: $e');
  }

  @override
  void onAuthentication(Socket socket, bool? status) {}

  @override
  void onSetAuthToken(String? token, Socket socket) {
    socket.authToken = token;
  }
}
```

---

## SocketClusterController (High-level API)

Suitable for simple use cases. For apps that need reconnection, multiple channels, or lifecycle management, the direct `Socket` API above is preferred.

```dart
final controller = SocketClusterController();

// Disable built-in reconnect if you implement your own
controller.strategy = null;

// Set a listener before connecting
controller.listener = SocketListener(
  MySocketEventListener(),
  null,
);

await controller.connect('wss://your-server.com');

// Subscribe to a channel
await controller.subscribe(
  socketUrl: 'wss://your-server.com',
  channelName: 'notifications',
  eventCallBack: SocketCallback((data) {
    print('Received: $data');
  }),
);

// Cleanup
await controller.destroy();
```

---

## Reconnection Strategy

```dart
final controller = SocketClusterController();

controller.strategy = ReconnectStrategy(
  reconnectInterval: 3000,      // Initial delay: 3s
  maxReconnectInterval: 60000,  // Max delay: 60s
  maxAttempts: 10,              // null = unlimited
);
```

`getReconnectInterval()` returns an exponentially increasing delay — it doubles each attempt up to `maxReconnectInterval`. `areAttemptsComplete()` is safe when `maxAttempts` is `null` (returns `false`, allowing unlimited retries).

---

## Emit & Publish

```dart
final socket = await Socket.connect('wss://your-server.com');

// Emit a custom event
socket.emit('my-event', {'key': 'value'});

// Emit with acknowledgement
socket.emit('my-event', {'key': 'value'}, (name, error, data) {
  print('Ack received: $data');
});

// Publish to a channel
socket.publish('my-channel', {'message': 'hello'});
```

---

## Authentication

```dart
final socket = await Socket.connect(
  'wss://your-server.com',
  authToken: 'your-jwt-token',
);
```

---

## API Reference

### `Socket`

| Method | Description |
|---|---|
| `Socket.connect(url, {authToken, strategy, listener})` | Open a WebSocket connection |
| `emit(event, data, [ack])` | Send an event to the server |
| `subscribe(channel, [ack])` | Subscribe to a channel |
| `unsubscribe(channel, [ack])` | Unsubscribe from a channel |
| `publish(channel, data, [ack])` | Publish data to a channel |
| `on(event, fn)` | Listen for direct events |
| `onSubscribe(channel, fn)` | Listen for `#publish` channel messages |
| `sendOrAdd(json)` | Send a raw JSON string |

### `ReconnectStrategy`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `reconnectInterval` | `int` | `3000` | Initial delay (ms) |
| `maxReconnectInterval` | `int` | `30000` | Max delay (ms) |
| `maxAttempts` | `int?` | `null` | Max attempts, `null` = unlimited |

| Method | Description |
|---|---|
| `getReconnectInterval()` | Returns next delay with exponential backoff |
| `areAttemptsComplete()` | `true` when limit reached; always `false` if `maxAttempts` is `null` |
| `processValues()` | Increment attempt counter |
| `reset()` | Reset attempt counter |

### `BasicListener`

| Callback | Description |
|---|---|
| `onConnected(socket)` | Socket connected and handshake complete |
| `onDisconnected(socket)` | Socket closed |
| `onConnectError(socket, e)` | Connection failed |
| `onAuthentication(socket, status)` | Auth status received |
| `onSetAuthToken(token, socket)` | Server set an auth token |

---

## Platform Support

| Platform | Supported |
|---|---|
| iOS | ✅ |
| Android | ✅ |
| Web | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |

---

## License

MIT — see [LICENSE](LICENSE).

## Additional Information

[SocketCluster Documentation](https://socketcluster.io/)
