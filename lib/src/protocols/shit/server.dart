import 'package:embedded_micro_services/embedded_micro_services.dart';
import 'package:embedded_micro_services/src/protocols/shit/packet.dart';

/// S.H.I.T., the Simple Helper Identifier Transaction (protocol)
class SHITServer {
  SHITServer(this.network);

  DartNet network;
  Map<String, int> cache = {};

  void serve() {
    network.listen(0, (target, newConnection) async {
      final (receive, send) = await newConnection;
      final request = await receive.first;
      final packet = SHITPacket.deserialize(request);
      switch (packet.action) {
        case SHITAction.resolve:
          send.add(cache[packet.host]?.toString() ?? "-1");
        case SHITAction.register:
          if (cache.containsKey(packet.host)) {
            send.add("Host already exists");
          } else {
            cache[packet.host] = target;
            send.add("ok");
          }
        case SHITAction.unregister:
          if (!cache.containsKey(packet.host)) {
            send.add("Host doesn't exist");
          } else if (cache[packet.host] != target) {
            send.add("Cannot unregister another server's identifier");
          } else {
            cache.remove(packet.host);
            send.add("ok");
          }
      }
      send.close();
    });
  }
}
