## 1.0.0

* Initial stable release.
* WebSocket-based SocketCluster client for Flutter (iOS, Android, Web, Desktop).
* `SocketClusterController` for high-level connection and channel management.
* `Socket` for low-level emit, subscribe, publish, and ack support.
* `Channel` for named channel lifecycle management.
* `ReconnectStrategy` for configurable reconnection with backoff.
* Cross-platform support via conditional `dart:io` / `dart:html` WebSocket imports.
* Authentication support via `authToken` on connect.
