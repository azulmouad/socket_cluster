abstract class SocketEventListener {
  void onConnected();

  void onDisconnected();

  void onConnectError(String error);
}
