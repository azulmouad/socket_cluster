class SocketMessage {
  SocketMessage({this.event, this.data});

  SocketMessage.fromJson(Map<String, dynamic> json) {
    event = json['event'] as String;
    data = json['data'] != null
        ? Data.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }
  String? event;
  Data? data;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['event'] = event;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Data({this.channel, this.data});

  Data.fromJson(Map<String, dynamic> json) {
    channel = json['channel'] as String;
    data = json['data'] as String?;
  }
  String? channel;
  String? data;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['channel'] = channel;
    data['data'] = this.data;
    return data;
  }
}
