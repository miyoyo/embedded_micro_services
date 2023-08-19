import 'package:embedded_micro_services/embedded_micro_services.dart';
import 'package:embedded_micro_services/src/protocols/shit/packet.dart';

/// S.H.I.T., the Simple Helper Identifier Transaction (protocol)
class SHITClient {
  SHITClient(this.network);

  DartNet network;

  Future<int?> resolve(String host) async {
    final (receive, send) = await network.connect(0, 0);

    final packet = SHITPacket(SHITAction.resolve, host);

    send.add(packet.serialize());

    final response = await receive.first;

    send.close();

    return int.tryParse(response);
  }

  Future<bool> register(String host) async {
    final (receive, send) = await network.connect(0, 0);

    final packet = SHITPacket(SHITAction.register, host);

    send.add(packet.serialize());

    final response = await receive.first;

    send.close();

    return response == "ok";
  }

  Future<bool> unregister(String host) async {
    final (receive, send) = await network.connect(0, 0);

    final packet = SHITPacket(SHITAction.unregister, host);

    send.add(packet.serialize());

    final response = await receive.first;

    send.close();

    return response == "ok";
  }
}
