import 'dart:developer';

import 'package:socket_cluster/socket/library/reconnect_strategy.dart';
import 'package:socket_cluster/socket/library/socket.dart';
import 'package:socket_cluster/socket/library/socket_callback.dart';
import 'package:socket_cluster/socket/library/socket_event_callback.dart';
import 'package:socket_cluster/socket/library/socket_event_type.dart';
import 'package:socket_cluster/socket/socket_listener.dart';

class SocketClusterController implements SocketEventListener {
  Socket? _socket;
  final Set<String> _subscribedChannels = {};

  SocketListener? listener;
  ReconnectStrategy? strategy = ReconnectStrategy(
      reconnectInterval: 5000, maxReconnectInterval: 60000, maxAttempts: 30);

  String? _defaultChannelName = '';
  String? _socketUrl;
  var _isClosed = false;

  Future<void> subscribe(
      {SocketEventCallBackListener? eventCallBack,
      String? channelName,
      required String socketUrl}) async {
    _isClosed = false;
    _defaultChannelName = channelName;
    listener = SocketListener(this, eventCallBack);

    try {
      _subscribeToChannel(_socket, channelName!);
    } catch (e) {
      log('[SocketClusterController] : ${e.toString()}');
      await startReconnection(channelName, socketUrl);
    }
  }

  Future<void> connect(String socketUrl) async {
    if (_socket != null) return;
    _socketUrl = socketUrl;
    final wsUrl = Uri.parse(socketUrl);
    _socket = await Socket.connect(
      wsUrl.toString(),
      listener: listener,
      strategy: strategy,
    );
  }

  Future<void> destroy() async {
    try {
      _isClosed = true;
      _socket = null;
    } catch (e) {
      log('[destroy] : ${e.toString()}');
    }
  }

  Future<void> disconnect(String channelId) async {
    if (_socket != null && _subscribedChannels.contains(channelId)) {
      try {
        // Unsubscribe from the channel
        // _isClosed = true;
        _socket?.unsubscribe(channelId);
        // _subscribedChannels.remove(channelId);

        // Optionally close the socket connection if no other channels are subscribed
        // if (_subscribedChannels.isEmpty) {
        //   await _socket?.close();
        // }

        log("Successfully unsubscribed from channel: $channelId");
      } catch (e) {
        log("Error disconnecting from channel: $channelId, Error: $e");
      }
    }
  }

  void _subscribeToChannel(Socket? socket, String channelId) {
    if (socket != null) {
      if (channelId.isNotEmpty) {
        _subscribedChannels.add(channelId);
        socket
          ..createChannel(channelId)
          ..subscribe(channelId)
          ..subscribeChannels()
          ..on(channelId, (name, data, ack) {
            if (!_isClosed) {
              listener?.eventCallBack
                  ?.onEvent(channelId, SocketEventType.Any, data);
            }
          });
      }
    }
  }

  @override
  void onConnected() {
    strategy?.reset();
    log('[SocketClusterController] : onConnected');
  }

  @override
  void onDisconnected() {
    log('[SocketClusterController] : onDisconnected');
    if (_socketUrl != null) {
      startReconnection(_defaultChannelName, _socketUrl!);
    }
  }

  Future<void> startReconnection(String? channelName, String socketUrl) async {
    if (_isClosed) {
      return;
    }
    if (strategy?.areAttemptsComplete() == false) {
      log('[SocketClusterController] : startReconnection');
      strategy?.processValues();
      log('[SocketClusterController] : Reconnection attempt: ${strategy?.attmptsMade}');
      await Socket.connect(
        socketUrl,
        listener: listener,
        strategy: strategy,
      ).then((value) {
        _socket = value;
        _subscribeToChannel(value, channelName!);
        strategy?.reset();
      }).catchError((err) async {
        log('[SocketClusterController] : Error: $err');
        await Future.delayed(
                Duration(milliseconds: strategy?.reconnectInterval ?? 3000))
            .then((a) {
          startReconnection(channelName, socketUrl);
        });
      });
    } else {
      strategy?.reset();
      log('[SocketClusterController] : All reconnection attempts are exhausted.');
    }
  }

  void sendMessage() {}
}

class SocketCallback implements SocketEventCallBackListener {
  final Function(dynamic data) callback;

  SocketCallback(this.callback);
  @override
  void onEvent(String channelId, SocketEventType type, data) {
    callback.call(data);
  }
}
