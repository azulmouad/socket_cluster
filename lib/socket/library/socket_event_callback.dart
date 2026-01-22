import 'package:socket_cluster/socket/library/socket_event_type.dart';

abstract class SocketEventCallBackListener {
  void onEvent(String channelId, SocketEventType type, dynamic data);
}
