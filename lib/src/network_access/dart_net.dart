import 'dart:async';
import 'dart:convert';

import 'package:embedded_micro_services/src/transports/segment.dart';
import 'package:embedded_micro_services/src/layers/transport.dart';

typedef PortListener = void Function(
  int target,
  Future<(Stream<String> receive, Sink<String> send)>,
);

typedef Port = int;

typedef PortPair = (Port source, Port target, int address);

typedef ConnectionDescription = (
  StreamController<String> send,
  StreamController<String> receive,
  Completer<(Stream<String> receive, Sink<String> send)>
);

class DartNet implements TransportLayer {
  DartNet(Segment segment, [this.address = -1]) {
    segment.connect(_send.stream, _receive.sink);
    _receive.stream.listen(_onPacketReceived);
  }

  int address;
  int _sourcePortPool = 0;

  Map<int, PortListener> portListeners = {};
  Map<PortPair, ConnectionDescription> connections = {};

  final _send = StreamController<String>();
  final _receive = StreamController<String>();

  void listen(Port port, PortListener listener) {
    if (portListeners.containsKey(port)) {
      throw StateError("Port $port is already being listened to.");
    }

    portListeners[port] = listener;
  }

  void stopListening(Port port) {
    if (!portListeners.containsKey(port)) {
      throw StateError("Port $port is not being listened to.");
    }

    portListeners.remove(port);

    connections.entries
        .where((element) => element.key.$1 == port)
        .forEach((element) {
      _sendPacket(
        _DartNetPacket(address, element.key.$3, element.key.$1, element.key.$2,
            Command.close, "Listener has stopped listening to this port"),
      );
    });

    connections.removeWhere((key, value) => key.$1 == port);
  }

  Future<(Stream<String>, Sink<String>)> connect(int target, Port port) async {
    final portPair = (_sourcePortPool++, port, target);

    final send = StreamController<String>();
    send.stream.listen((e) => _onDataSent(e, portPair));
    final receive = StreamController<String>();
    final completer = Completer<(Stream<String> receive, Sink<String> send)>();

    connections[portPair] = (send, receive, completer);

    _sendPacket(_DartNetPacket(
        address, target, portPair.$1, port, Command.connect, ""));

    return completer.future;
  }

  void _sendPacket(_DartNetPacket packet) {
    final serialized = packet.serialize();
    _send.sink.add(serialized);
  }

  void _onDataSent(
      String data, (Port source, Port target, int address) portPair) {
    final packet = _DartNetPacket(
        address, portPair.$3, portPair.$1, portPair.$2, Command.none, data);

    _sendPacket(packet);
  }

  void _onPacketReceived(String raw) {
    late final _DartNetPacket packet;

    packet = _DartNetPacket.deserialize(raw);

    if (address != -1 && packet.target != address && packet.target != -1) {
      // Not in addressless mode, Not for us, drop
      return;
    }

    final portPair = (packet.targetPort, packet.sourcePort, packet.source);

    switch (packet.command) {
      case Command.connect:
        if (connections.containsKey(portPair)) return; // Invalid sequence, drop

        if (!portListeners.containsKey(packet.targetPort)) {
          return _sendPacket(packet.asReply(
            command: Command.close,
            data: "No listener on this port",
          ));
        }

        final send = StreamController<String>();
        send.stream.listen((e) => _onDataSent(e, portPair));
        final receive = StreamController<String>();
        final completer =
            Completer<(Stream<String> receive, Sink<String> send)>();

        connections[portPair] = (send, receive, completer);

        portListeners[packet.targetPort]!.call(
          packet.source,
          completer.future,
        );

        return _sendPacket(packet.asReply(command: Command.connectReady));
      case Command.connectReady:
        if (!connections.containsKey(portPair)) break; // Invalid sequence, drop

        final connection = connections[portPair]!;

        connection.$3.complete((connection.$2.stream, connection.$1.sink));

        return _sendPacket(packet.asReply(command: Command.connectOk));
      case Command.connectOk:
        if (!connections.containsKey(portPair)) break; // Invalid sequence, drop
        final connection = connections[portPair]!;

        connection.$3.complete((connection.$2.stream, connection.$1.sink));
      case Command.close:
        if (!connections.containsKey(portPair)) break; // Invalid sequence, drop
        var (send, receive, _) = connections[portPair]!;
        send.close();
        receive.close();
        connections.remove(portPair);
      case Command.none:
        if (!connections.containsKey(portPair)) {
          break; // No connection, drop
        }

        final connection = connections[portPair]!;

        connection.$2.add(packet.data);
    }
  }
}

enum Command { none, connect, connectReady, connectOk, close }

class _DartNetPacket {
  _DartNetPacket(
    this.source,
    this.target,
    this.sourcePort,
    this.targetPort,
    this.command,
    this.data,
  );

  final int source;
  final int target;
  final int sourcePort;
  final int targetPort;

  final Command command;

  String data;

  _DartNetPacket asReply({Command? command, String? data}) {
    return _DartNetPacket(
      target,
      source,
      targetPort,
      sourcePort,
      command ?? Command.none,
      data ?? "",
    );
  }

  String serialize() {
    return """{
      "source": $source,
      "target": $target,
      "sourcePort":   $sourcePort,
      "targetPort":   $targetPort,
      "command": ${command.index},
      "data":   "${base64Encode(utf8.encode(data))}"
    }""";
  }

  factory _DartNetPacket.deserialize(String serialized) {
    final deserialized = jsonDecode(serialized);
    if (deserialized is! Map<String, dynamic> ||
        !deserialized.containsKey("source") ||
        deserialized["source"] is! num ||
        !deserialized.containsKey("target") ||
        deserialized["target"] is! num ||
        !deserialized.containsKey("sourcePort") ||
        deserialized["sourcePort"] is! num ||
        !deserialized.containsKey("targetPort") ||
        deserialized["targetPort"] is! num ||
        !deserialized.containsKey("command") ||
        deserialized["command"] is! num ||
        !deserialized.containsKey("data") ||
        deserialized["data"] is! String) {
      throw FormatException("Malformed DartNet Packet");
    }
    return _DartNetPacket(
      deserialized["source"].toInt(),
      deserialized["target"].toInt(),
      deserialized["sourcePort"].toInt(),
      deserialized["targetPort"].toInt(),
      Command.values[deserialized["command"]],
      utf8.decode(base64Decode(deserialized["data"])),
    );
  }

  @override
  String toString() {
    return """
Source: $source:$sourcePort
Target: $target:$targetPort
Command: $command,
Data:
$data""";
  }
}
