import 'dart:developer';

import 'package:socket_cluster/socket/library/basic_listener.dart';
import 'package:socket_cluster/socket/library/socket.dart';
import 'package:socket_cluster/socket/library/socket_callback.dart';
import 'package:socket_cluster/socket/library/socket_event_callback.dart';

class SocketListener extends BasicListener {
  SocketListener(this.callBack, this.eventCallBack, {this.enableLog = true});

  static const String _logTag = '[SocketCluster]';

  SocketEventListener? callBack;
  SocketEventCallBackListener? eventCallBack;

  bool enableLog;

  String tag = "SocketListener";

  bool _messageReceived = false;

  @override
  void onAuthentication(Socket socket, bool? status) {
    if (enableLog) {
      log('$_logTag $tag:onAuthentication: socket $socket status $status');
    }
  }

  @override
  void onConnectError(Socket socket, e) {
    if (enableLog) {
      log('$_logTag $tag:onConnectError: socket $socket e $e');
    }
  }

  @override
  void onConnected(Socket socket) {
    callBack?.onConnected();
    if (enableLog) {
      log('$_logTag $tag:onConnected!');
    }
    //Do on connect
    _resetMessageReceived();
  }

  @override
  void onDisconnected(Socket socket) {
    callBack?.onDisconnected();
    if (enableLog) {
      log('$_logTag $tag:onDisconnected!');
    }
    //Start Reconnection
  }

  @override
  void onSetAuthToken(String? token, Socket socket) {
    if (enableLog) {
      log('$_logTag $tag:onSetAuthToken: socket $socket token $token');
    }
    socket.authToken = token;
  }

  void _resetMessageReceived() {
    if (_messageReceived) {
      Future.delayed(const Duration(seconds: 2)).then((value) {
        _messageReceived = false;
      });
    }
  }

  static int getTimeStamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }
}
