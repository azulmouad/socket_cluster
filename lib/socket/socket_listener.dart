import 'dart:developer';

import 'package:socket_cluster/socket/library/basic_listener.dart';
import 'package:socket_cluster/socket/library/socket.dart';
import 'package:socket_cluster/socket/library/socket_callback.dart';
import 'package:socket_cluster/socket/library/socket_event_callback.dart';

class SocketListener extends BasicListener {
  SocketListener(this.callBack, this.eventCallBack);

  SocketEventListener? callBack;
  SocketEventCallBackListener? eventCallBack;

  String tag = "SocketListener";

  bool _messageReceived = false;

  @override
  void onAuthentication(Socket socket, bool? status) {
    log('$tag:onAuthentication: socket $socket status $status');
  }

  @override
  void onConnectError(Socket socket, e) {
    log('$tag:onConnectError: socket $socket e $e');
  }

  @override
  void onConnected(Socket socket) {
    callBack?.onConnected();
    log('$tag:onConnected!');
    //Do on connect
    _resetMessageReceived();
  }

  @override
  void onDisconnected(Socket socket) {
    callBack?.onDisconnected();
    log('$tag:onDisconnected!');
    //Start Reconnection
  }

  @override
  void onSetAuthToken(String? token, Socket socket) {
    log('$tag:onSetAuthToken: socket $socket token $token');
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
