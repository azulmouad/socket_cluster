## 1.1.0

* **Fix:** `ReconnectStrategy.areAttemptsComplete()` no longer crashes when `maxAttempts` is null — returns `false` (unlimited retries) as documented.
* **Fix:** `ReconnectStrategy.getReconnectInterval()` now implements real exponential backoff (doubles each attempt, clamped to `maxReconnectInterval`).
* **Fix:** Double-fire bug — when both `on()` and `onSubscribe()` are registered for the same channel, and the server sends data in both formats, the message is now delivered exactly once via the `onSubscribe` handler.
* **Rename:** `attmptsMade` → `attemptsMade` (typo fix).

## 1.0.0

* Initial stable release.
* WebSocket-based SocketCluster client for Flutter (iOS, Android, Web, Desktop).
* `SocketClusterController` for high-level connection and channel management.
* `Socket` for low-level emit, subscribe, publish, and ack support.
* `Channel` for named channel lifecycle management.
* `ReconnectStrategy` for configurable reconnection with backoff.
* Cross-platform support via conditional `dart:io` / `dart:html` WebSocket imports.
* Authentication support via `authToken` on connect.
