# Socket Cluster

A Flutter package that provides SocketCluster client functionality for real-time communication in Flutter applications. This package enables bidirectional communication between your Flutter app and SocketCluster servers.

## Features

- ✅ **WebSocket Support**: Full WebSocket client implementation for SocketCluster
- ✅ **Automatic Reconnection**: Configurable reconnection strategy with exponential backoff
- ✅ **Channel Management**: Subscribe/unsubscribe to multiple channels
- ✅ **Event Handling**: Listen to connection events and channel messages
- ✅ **Cross-Platform**: Works on iOS, Android, Web, and Desktop
- ✅ **Type-Safe**: Strongly typed API with Dart's type system

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  socket_cluster: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup

```dart
import 'package:socket_cluster/socket_cluster.dart';

// Create a controller instance
final socketController = SocketClusterController();

// Connect to SocketCluster server
await socketController.connect('wss://your-socket-server.com');
```

### Subscribe to a Channel

```dart
// Create a callback to handle events
final callback = SocketCallback((data) {
  print('Received data: $data');
  // Handle your data here
});

// Subscribe to a channel
await socketController.subscribe(
  socketUrl: 'wss://your-socket-server.com',
  channelName: 'my-channel',
  eventCallBack: callback,
);
```

### Complete Example

```dart
import 'package:socket_cluster/socket_cluster.dart';

class MySocketService {
  late SocketClusterController _controller;
  
  Future<void> initialize() async {
    _controller = SocketClusterController();
    
    // Configure reconnection strategy (optional)
    _controller.strategy = ReconnectStrategy(
      reconnectInterval: 5000,
      maxReconnectInterval: 60000,
      maxAttempts: 30,
    );
    
    // Connect to server
    await _controller.connect('wss://your-socket-server.com');
    
    // Subscribe to channel with event handler
    await _controller.subscribe(
      socketUrl: 'wss://your-socket-server.com',
      channelName: 'notifications',
      eventCallBack: SocketCallback((data) {
        print('Notification received: $data');
        // Handle notification
      }),
    );
  }
  
  Future<void> disconnect(String channelId) async {
    await _controller.disconnect(channelId);
  }
  
  Future<void> cleanup() async {
    await _controller.destroy();
  }
}
```

### Using with Riverpod (Optional)

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:socket_cluster/socket_cluster.dart';

final socketControllerProvider = Provider<SocketClusterController>((ref) {
  final controller = SocketClusterController();
  
  // Setup connection when provider is created
  ref.onDispose(() {
    controller.destroy();
  });
  
  return controller;
});

// In your widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketController = ref.watch(socketControllerProvider);
    
    // Use socketController...
    
    return Container();
  }
}
```

### Custom Event Listener

```dart
class MySocketEventListener implements SocketEventListener {
  @override
  void onConnected() {
    print('Socket connected!');
    // Handle connection
  }
  
  @override
  void onDisconnected() {
    print('Socket disconnected!');
    // Handle disconnection
  }
}

// Use custom listener
final controller = SocketClusterController();
final listener = SocketListener(
  MySocketEventListener(),
  SocketCallback((data) => print('Data: $data')),
);

controller.listener = listener;
```

### Reconnection Strategy

```dart
// Custom reconnection strategy
final strategy = ReconnectStrategy(
  reconnectInterval: 3000,        // Initial delay: 3 seconds
  maxReconnectInterval: 60000,    // Max delay: 60 seconds
  maxAttempts: 30,                 // Max reconnection attempts
);

final controller = SocketClusterController();
controller.strategy = strategy;
```

### Multiple Channels

```dart
final controller = SocketClusterController();
await controller.connect('wss://your-socket-server.com');

// Subscribe to multiple channels
await controller.subscribe(
  socketUrl: 'wss://your-socket-server.com',
  channelName: 'channel-1',
  eventCallBack: SocketCallback((data) {
    print('Channel 1: $data');
  }),
);

await controller.subscribe(
  socketUrl: 'wss://your-socket-server.com',
  channelName: 'channel-2',
  eventCallBack: SocketCallback((data) {
    print('Channel 2: $data');
  }),
);

// Disconnect from a specific channel
await controller.disconnect('channel-1');
```

## API Reference

### SocketClusterController

Main controller class for managing SocketCluster connections.

#### Methods

- `Future<void> connect(String socketUrl)` - Connect to SocketCluster server
- `Future<void> subscribe({required String socketUrl, String? channelName, SocketEventCallBackListener? eventCallBack})` - Subscribe to a channel
- `Future<void> disconnect(String channelId)` - Unsubscribe from a channel
- `Future<void> destroy()` - Clean up and close all connections

#### Properties

- `ReconnectStrategy? strategy` - Reconnection strategy configuration
- `SocketListener? listener` - Socket event listener

### ReconnectStrategy

Configuration for automatic reconnection behavior.

#### Constructor Parameters

- `reconnectInterval` (int, default: 3000) - Initial delay between reconnection attempts in milliseconds
- `maxReconnectInterval` (int, default: 30000) - Maximum delay between reconnection attempts in milliseconds
- `maxAttempts` (int?, default: null) - Maximum number of reconnection attempts (null = unlimited)

#### Methods

- `void reset()` - Reset the attempt counter
- `void processValues()` - Increment the attempt counter
- `bool areAttemptsComplete()` - Check if max attempts reached
- `int getReconnectInterval()` - Get current reconnect interval

### SocketCallback

Simple callback wrapper for handling channel events.

```dart
SocketCallback((data) {
  // Handle data
})
```

### SocketListener

Listener for socket connection events. Extends `BasicListener` and provides callbacks for:
- `onConnected()` - Called when socket connects
- `onDisconnected()` - Called when socket disconnects
- `onAuthentication()` - Called during authentication
- `onConnectError()` - Called on connection errors
- `onSetAuthToken()` - Called when auth token is set

## Error Handling

The package handles errors gracefully:

- Connection errors trigger automatic reconnection (if configured)
- Failed subscriptions will attempt reconnection
- All errors are logged using `dart:developer` log

## Platform Support

- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See the LICENSE file for details.

## Additional Information

For more information about SocketCluster protocol, visit: [SocketCluster Documentation](https://socketcluster.io/)
