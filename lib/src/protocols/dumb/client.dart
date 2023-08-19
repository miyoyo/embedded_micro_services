import 'package:embedded_micro_services/embedded_micro_services.dart';
import 'package:embedded_micro_services/src/protocols/dumb/packet.dart';
import 'package:embedded_micro_services/src/protocols/shit/client.dart';

/// D.U.M.B., the Dart Unified Messaging Binary (format)
class DUMBClient {
  DUMBClient(this.network, this.shit);

  final DartNet network;
  final SHITClient shit;

  Future<DUMBResponse> get({
    required Uri address,
    Map<String, String> headers = const {},
  }) async {
    final target = await shit.resolve(address.host);

    if (target == null) {
      throw Exception("Could not resolve identifier ${address.host}");
    }

    final (receive, send) =
        await network.connect(target, address.hasPort ? address.port : 80);

    final sentPacket = DUMBRequest(RequestType.get, address, headers, null);

    send.add(sentPacket.serialize());

    final response = await receive.first;

    send.close();

    return DUMBResponse.deserialize(response);
  }

  Future<DUMBResponse> set({
    required Uri address,
    Map<String, String> headers = const {},
    String data = "",
  }) async {
    final target = await shit.resolve(address.host);

    if (target == null) {
      throw Exception("Could not resolve identifier ${address.host}");
    }

    final (receive, send) =
        await network.connect(target, address.hasPort ? address.port : 1);

    final sentPacket = DUMBRequest(RequestType.set, address, headers, data);

    send.add(sentPacket.serialize());

    final response = await receive.first;

    send.close();

    return DUMBResponse.deserialize(response);
  }
}
