class ReconnectStrategy {
  /// Milliseconds for the initial reconnect delay. Default: 3000
  final int reconnectInterval;

  /// Maximum milliseconds between reconnect attempts. Default: 30000
  final int maxReconnectInterval;

  /// Maximum reconnect attempts before giving up. null = unlimited. Default: null
  final int? maxAttempts;

  var attemptsMade = 0;

  ReconnectStrategy({
    this.reconnectInterval = 3000,
    this.maxReconnectInterval = 30000,
    this.maxAttempts,
  });

  void reset() {
    attemptsMade = 0;
  }

  void processValues() {
    attemptsMade++;
  }

  /// Returns the next reconnect delay using exponential backoff,
  /// clamped between [reconnectInterval] and [maxReconnectInterval].
  int getReconnectInterval() {
    final multiplier = 1 << attemptsMade.clamp(0, 10);
    return (reconnectInterval * multiplier).clamp(
      reconnectInterval,
      maxReconnectInterval,
    );
  }

  /// Returns true when [maxAttempts] is set and has been reached.
  /// Always returns false when [maxAttempts] is null (unlimited).
  bool areAttemptsComplete() =>
      maxAttempts != null && attemptsMade >= maxAttempts!;
}
