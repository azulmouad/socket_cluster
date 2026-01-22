import 'dart:io';

import 'socket_platform_interface.dart' as socketinterface;

const IoSocketPlatform ioSocketPlatform = IoSocketPlatform();

class IoSocketPlatform extends socketinterface.IoSocketPlatform {
  const IoSocketPlatform();

  @override
  Future<WebSocket> webSocket([url]) => WebSocket.connect(url as String);
}

const socketinterface.SocketPlatform RuntimeSocketPlatform = ioSocketPlatform;
