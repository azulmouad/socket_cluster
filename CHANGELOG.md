## 1.2.1

* **Fix:** Triple subscription bug — channel subscribe request was sent 3× on every connect/reconnect. `subscribeChannels()` was called redundantly in `_subscribeToChannel` (causing a second send) and again inside the `ISAUTHENTICATED` handler in `socket.dart` (causing a third). Both redundant calls removed; a single `socket.subscribe(channelId)` is now the only send path.

## 1.2.0

* **Fix:** `SocketEventListener` now exposes `onConnectError(String error)` — connection errors are no longer silently swallowed.
* **Fix:** `SocketListener.onConnectError` now forwards the error to the app-level `callBack`, not just logs it.
* **Fix:** `_subscribeToChannel` now registers both `onSubscribe` (for `#publish` messages) and `on` (for direct events) — previously only direct events were received via the controller API.
* **Fix:** `startReconnection` now uses `getReconnectInterval()` for real exponential backoff — previously always used the fixed initial interval.

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
