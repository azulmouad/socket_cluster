import 'dart:html';

import 'socket_platform_interface.dart' as socketinterface;

const HttpSocketPlatform httpSocketPlatform = HttpSocketPlatform();

class HttpSocketPlatform extends socketinterface.HttpSocketPlatform {
  const HttpSocketPlatform();

  @override
  dynamic webSocket([url]) => WebSocket(url as String);
}

const socketinterface.SocketPlatform RuntimeSocketPlatform = httpSocketPlatform;
