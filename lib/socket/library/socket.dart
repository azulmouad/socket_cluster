import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:socket_cluster/socket/library/parser.dart';
import 'package:socket_cluster/socket/library/reconnect_strategy.dart';
import 'package:socket_cluster/socket/library/socket_platform.dart';

import 'basic_listener.dart';
import 'channel.dart';
import 'emitter.dart';

class Socket extends Emitter {
  dynamic _socket;
  String? url;
  String? id;
  final ReconnectStrategy? strategy;
  final BasicListener? listener;
  int _counter = 0;
  String? authToken;
  final List<Channel> channels = [];
  final Map<int, List<dynamic>> _acks = {};

  int get state => _socket.readyState as int;

  static const int CONNECTING = 0;
  static const int OPEN = 1;
  static const int CLOSING = 2;
  static const int CLOSED = 3;

  Socket._internal(this._socket,
      {this.authToken, this.strategy, this.listener}) {
    _socket = _socket;
    if (globalSocketPlatform is IoSocketPlatform) {
      _socket.listen(handleMessage).onDone(onSocketDone);
      onSocketOpened();
    } else {
      _socket
        ..onOpen.listen(onSocketOpened)
        ..onClose.listen(onSocketDone)
        ..onMessage.listen(handleMessage);
    }
  }

  static Future<Socket> connect(String url,
      {String? authToken,
      ReconnectStrategy? strategy,
      BasicListener? listener}) async {
    if (globalSocketPlatform is IoSocketPlatform) {
      final socket = await globalSocketPlatform.webSocket(url);
      return Socket._internal(
        socket,
        authToken: authToken,
        strategy: strategy,
        listener: listener,
      );
    } else {
      final htmlsocket = globalSocketPlatform.webSocket(url);
      final socket0 = Socket._internal(htmlsocket,
          authToken: authToken, strategy: strategy, listener: listener);
      await whenTrue(socket0._socket.onOpen as Stream);
      return socket0;
    }
  }

  static Future<dynamic> whenTrue(Stream source) async {
    await for (dynamic value in source) {
      if (value != null) {
        return value;
      }
    }
    return null;
    // stream exited without a true value, maybe return an exception.
  }

  void sendOrAdd([json]) {
    if (globalSocketPlatform is IoSocketPlatform) {
      _socket.add(json);
    } else {
      _socket.send(json);
    }
  }

  void setProxy(String host, int port) {
    throw UnimplementedError();
    /*var proxy = new HttpConnectProxy(new IPEndPoint(IPAddress.Parse(host), port));
    _socket.Proxy = (SuperSocket.ClientEngine.IProxyConnector)proxy;*/
  }

  void setSSLCertVerification(bool value) {
    throw UnimplementedError();
    //_socket.AllowUnstrustedCertificate = value;
  }

  void onSocketOpened([event]) {
    _counter = 0;
    strategy?.attmptsMade = 0;
    final authObject = {
      'event': '#handshake',
      'data': {
        'authToken': authToken,
      },
      'cid': ++_counter
    };
    // Note: ported C# code had Formatting.Indented parameter
    final dynamic json = jsonEncode(authObject);
    sendOrAdd(json);
    if (listener != null) {
      listener!.onConnected(this);
    }
  }

  void onSocketDone([event]) {
    if (listener != null) {
      listener!.onDisconnected(this);
    }
  }

  Channel createChannel(String name) {
    final channel = Channel(this, name);
    channels.add(channel);
    return channel;
  }

  void handleMessage([dynamic messageEvent]) {
    String? message;
    if (globalSocketPlatform is IoSocketPlatform) {
      message = messageEvent as String;
    } else {
      message = messageEvent.data as String;
    }
    if (message == "#1") {
      sendOrAdd('#2');
    } else {
      if (message == '' || message.trim().isEmpty) {
        //print('Empty Message received: $message <--- from the websocket.');
        return;
      }
      log('Message received: $message');

      final map = jsonDecode(message);
      final data = map['data'];
      final rid = map['rid'];
      final cid = map['cid'];
      final event = map['event'];

      //print('Event: $event, rid: $rid, cid: $cid, data: $data');

      //if (cid == null) return;

      switch (Parser.parse(data, rid as int?, cid as int?, event as String?)) {
        case ParseResult.ISAUTHENTICATED:
          log('IS authenticated got called');
          id = data['id'] as String?;
          bool? auth = data['isAuthenticated'] as bool?;
          if (listener != null) {
            listener!.onAuthentication(this, auth);
          }
          subscribeChannels();
          break;
        case ParseResult.PUBLISH:
          handlePublish(data['channel'] as String?, data['data']);
          //print('Publish got called');
          break;
        case ParseResult.REMOVETOKEN:
          authToken = null;
          log('Removetoken got called');
          break;
        case ParseResult.SETTOKEN:
          if (listener != null) {
            listener!.onSetAuthToken(data['token'] as String?, this);
          }
          log('Set token got called');
          break;
        case ParseResult.EVENT:
          if (hasEventAck(event)) {
            handleEmitAck(event, data, ack(cid));
          } else {
            handleEmit(event, data);
          }
          break;
        case ParseResult.ACKRECEIVE:
          //print('Ack receive got called');
          if (_acks.containsKey(rid)) {
            var mapObj = _acks[rid!];
            _acks.remove(rid);
            if (mapObj != null) {
              AckCall fn = mapObj[1] as AckCall;
              fn(mapObj[0] as String, map['error'], map['data']);
                        }
          }
          break;
      }
    }
  }

  AckCall ack(int? cid) {
    return (name, dynamic error, dynamic data) {
      var message = {
        'error': error as String?,
        'data': data as String?,
        'rid': cid as String?, // FIXME: rid -> cid?
      };
      var json = jsonEncode(message);
      sendOrAdd(json);
    };
  }

  Socket emit(String event, Object data, [AckCall? ack]) {
    int count = ++_counter;
    var message = <String, Object>{};
    message['event'] = event;
    message['data'] = data;
    if (ack != null) {
      message['cid'] = count;
      _acks[count] = getAckObject(event, ack);
    }
    var json = jsonEncode(message);
    sendOrAdd(json);

    return this;
  }

  Socket subscribe(String channel, [AckCall? ack]) {
    int count = ++_counter;
    final message = {
      'event': '#subscribe',
      'data': {
        'channel': channel,
        // 'userId' : 'unbzprhk' //for test
      },
      'cid': count
    };
    if (ack != null) _acks[count] = getAckObject(channel, ack);
    final json = jsonEncode(message);
    sendOrAdd(json);
    return this;
  }

  Socket unsubscribe(String channel, [AckCall? ack]) {
    int count = ++_counter;
    var message = {'event': '#unsubscribe', 'data': channel, 'cid': count};
    if (ack != null) _acks[count] = getAckObject(channel, ack);
    var json = jsonEncode(message);
    sendOrAdd(json);
    return this;
  }

  Socket publish(String channel, Object data, [AckCall? ack]) {
    int count = ++_counter;
    var message = {
      'event': '#publish',
      'data': {'channel': channel, 'data': data},
      'cid': count
    };
    if (ack != null) _acks[count] = getAckObject(channel, ack);
    var json = jsonEncode(message);
    sendOrAdd(json);
    return this;
  }

  List<dynamic> getAckObject(String event, AckCall ack) {
    return [event, ack];
  }

  void subscribeChannels() {
    for (var c in channels) {
      c.subscribe();
    }
  }
}
