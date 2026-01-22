enum SocketEventType { Any }

extension ParseToString on SocketEventType {
  String toShortString() {
    return toString().split('.').last;
  }
}
