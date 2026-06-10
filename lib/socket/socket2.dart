import 'dart:developer';

import 'package:socket_cluster/socket/library/reconnect_strategy.dart';
import 'package:socket_cluster/socket/library/socket.dart';
import 'package:socket_cluster/socket/library/socket_callback.dart';
import 'package:socket_cluster/socket/library/socket_event_callback.dart';
import 'package:socket_cluster/socket/library/socket_event_type.dart';
import 'package:socket_cluster/socket/socket_listener.dart';

class SocketClusterController implements SocketEventListener {
  SocketClusterController({bool enableLog = true}) : _enableLog = enableLog;

  static const String _logTag = '[SocketCluster]';

  Socket? _socket;
  final Set<String> _subscribedChannels = {};

  SocketListener? listener;
  ReconnectStrategy? strategy = ReconnectStrategy(
    reconnectInterval: 5000,
    maxReconnectInterval: 60000,
    maxAttempts: 30,
  );

  String? _defaultChannelName = '';
  String? _socketUrl;
  var _isClosed = false;

  bool _enableLog;

  bool get enableLog => _enableLog;

  set enableLog(bool value) {
    _enableLog = value;
    _socket?.enableLog = value;
    if (listener != null) {
      listener!.enableLog = value;
    }
  }

  void _debugLog(String message) {
    if (_enableLog) {
      log('$_logTag $message');
    }
  }

  Future<void> subscribe({
    SocketEventCallBackListener? eventCallBack,
    String? channelName,
    required String socketUrl,
  }) async {
    _isClosed = false;
    _defaultChannelName = channelName;
    _socketUrl = socketUrl; // Save socket URL for reconnection
    listener = SocketListener(this, eventCallBack, enableLog: _enableLog);

    if (channelName == null || channelName.isEmpty) {
      _debugLog(
        '[SocketClusterController] Failed to subscribe: channel name is empty',
      );
      return;
    }

    if (socketUrl.isEmpty) {
      _debugLog(
        '[SocketClusterController] Failed to subscribe: socket URL is empty',
      );
      return;
    }

    _debugLog(
      '[SocketClusterController] Attempting to subscribe to channel: $channelName',
    );

    try {
      if (_socket == null) {
        _debugLog(
          '[SocketClusterController] Socket not connected, connecting first...',
        );
        await connect(socketUrl);
      }

      _subscribeToChannel(_socket, channelName);
      _debugLog(
        '[SocketClusterController] Successfully subscribed to channel: $channelName',
      );
    } catch (e) {
      _debugLog(
        '[SocketClusterController] Failed to subscribe to channel $channelName: ${e.toString()}',
      );
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
      enableLog: _enableLog,
    );
  }

  Future<void> destroy() async {
    try {
      _isClosed = true;
      _socket = null;
    } catch (e) {
      _debugLog('[destroy] : ${e.toString()}');
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

        _debugLog("Successfully unsubscribed from channel: $channelId");
      } catch (e) {
        _debugLog("Error disconnecting from channel: $channelId, Error: $e");
      }
    }
  }

  void _subscribeToChannel(Socket? socket, String channelId) {
    if (socket == null) {
      _debugLog(
        '[SocketClusterController] Cannot subscribe to channel $channelId: socket is null',
      );
      return;
    }

    if (channelId.isEmpty) {
      _debugLog(
        '[SocketClusterController] Cannot subscribe: channel ID is empty',
      );
      return;
    }

    try {
      _subscribedChannels.add(channelId);
      socket
        ..createChannel(channelId)
        ..subscribe(channelId)
        ..subscribeChannels()
        ..onSubscribe(channelId, (name, data) {
          if (!_isClosed) {
            listener?.eventCallBack?.onEvent(
              channelId,
              SocketEventType.Any,
              data,
            );
          }
        })
        ..on(channelId, (name, data, ack) {
          if (!_isClosed) {
            listener?.eventCallBack?.onEvent(
              channelId,
              SocketEventType.Any,
              data,
            );
          }
        });
      _debugLog(
        '[SocketClusterController] Channel subscription initiated for: $channelId',
      );
    } catch (e) {
      _subscribedChannels.remove(channelId);
      _debugLog(
        '[SocketClusterController] Error during channel subscription for $channelId: $e',
      );
      rethrow;
    }
  }

  @override
  void onConnected() {
    strategy?.reset();
    _debugLog('[SocketClusterController] : onConnected');
  }

  @override
  void onDisconnected() {
    _debugLog('[SocketClusterController] : onDisconnected');
    if (_socketUrl != null) {
      startReconnection(_defaultChannelName, _socketUrl!);
    }
  }

  @override
  void onConnectError(String error) {
    _debugLog('[SocketClusterController] : onConnectError $error');
    if (_socketUrl != null) {
      startReconnection(_defaultChannelName, _socketUrl!);
    }
  }

  Future<void> startReconnection(String? channelName, String socketUrl) async {
    if (_isClosed) {
      return;
    }

    // Use stored socketUrl if provided socketUrl is empty
    final urlToUse = socketUrl.isEmpty ? _socketUrl : socketUrl;

    if (urlToUse == null || urlToUse.isEmpty) {
      _debugLog(
        '[SocketClusterController] Cannot reconnect: socket URL is empty',
      );
      return;
    }

    if (strategy?.areAttemptsComplete() == false) {
      _debugLog(
        '[SocketClusterController] Starting reconnection to: $urlToUse',
      );
      strategy?.processValues();
      _debugLog(
        '[SocketClusterController] Reconnection attempt: ${strategy?.attemptsMade}',
      );
      await Socket.connect(
            urlToUse,
            listener: listener,
            strategy: strategy,
            enableLog: _enableLog,
          )
          .then((value) {
            _socket = value;
            _debugLog(
              '[SocketClusterController] Successfully reconnected to: $urlToUse',
            );
            if (channelName != null && channelName.isNotEmpty) {
              _debugLog(
                '[SocketClusterController] Attempting to resubscribe to channel: $channelName',
              );
              _subscribeToChannel(value, channelName);
            }
            strategy?.reset();
          })
          .catchError((err) async {
            _debugLog(
              '[SocketClusterController] Reconnection failed: $err (URL: $urlToUse)',
            );
            await Future.delayed(
              Duration(milliseconds: strategy?.getReconnectInterval() ?? 3000),
            ).then((a) {
              startReconnection(channelName, urlToUse);
            });
          });
    } else {
      strategy?.reset();
      _debugLog(
        '[SocketClusterController] All reconnection attempts are exhausted.',
      );
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
