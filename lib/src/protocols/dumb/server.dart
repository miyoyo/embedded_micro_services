import 'package:embedded_micro_services/embedded_micro_services.dart';
import 'package:embedded_micro_services/src/protocols/dumb/packet.dart';

/// D.U.M.B., the Dart Unified Messaging Binary (format)
class DUMBServer {
  DUMBServer(this.network, this.port, this.handler);

  final DartNet network;
  final int port;
  final DUMBResponse Function(DUMBRequest request) handler;

  void serve() {
    network.listen(port, (target, newConnection) async {
      final (receive, send) = await newConnection;
      final request = await receive.first;
      final packet = DUMBRequest.deserialize(request);
      final response = handler(packet);
      send.add(response.serialize());
      send.close();
    });
  }
}
