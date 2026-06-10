typedef Listener = Function(String? name, dynamic data);

typedef AckListener = Function(String? name, dynamic data, AckCall ack);

typedef AckCall = Function(String name, dynamic error, dynamic data);

class Emitter {
  final Map<String, Listener> _singleCallbacks = {};
  final Map<String, AckListener> _singleAckCallbacks = {};
  final Map<String, Listener> _publishCallbacks = {};

  Emitter on(String event, Function func) {
    if (func is Listener) {
      _on(event, func);
    } else if (func is AckListener) {
      _onAck(event, func);
    } else {
      throw Exception('on(event, func) - func incorrect format');
    }
    return this;
  }

  Emitter _on(String event, Listener fn) {
    if (_singleCallbacks.containsKey(event)) _singleCallbacks.remove(event);

    _singleCallbacks[event] = fn;
    return this;
  }

  Emitter _onAck(String event, AckListener fn) {
    if (_singleAckCallbacks.containsKey(event)) {
      _singleAckCallbacks.remove(event);
    }

    _singleAckCallbacks[event] = fn;
    return this;
  }

  Emitter onSubscribe(String event, Listener fn) {
    if (_publishCallbacks.containsKey(event)) _publishCallbacks.remove(event);

    _publishCallbacks[event] = fn;
    return this;
  }

  Emitter handleEmit(String? event, dynamic object) {
    // If a #publish (onSubscribe) handler exists for this event, let it handle
    // the message exclusively — prevents double-fire when the server sends the
    // same payload as both a direct event and a #publish channel message.
    if (_publishCallbacks.containsKey(event)) return this;

    if (_singleCallbacks.containsKey(event)) {
      final listener = _singleCallbacks[event!]!;
      listener(event, object);
    }
    return this;
  }

  Emitter handleEmitAck(String? event, dynamic object, AckCall ack) {
    if (_singleAckCallbacks.containsKey(event)) {
      final listener = _singleAckCallbacks[event!]!;
      listener(event, object, ack);
    }
    return this;
  }

  Emitter handlePublish(String? event, dynamic object) {
    if (_publishCallbacks.containsKey(event)) {
      final listener = _publishCallbacks[event!]!;
      listener(event, object);
    }
    return this;
  }

  bool hasEventAck(String? event) => _singleAckCallbacks.containsKey(event);
}
