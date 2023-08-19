import 'package:embedded_micro_services/embedded_micro_services.dart';
import 'package:embedded_micro_services/src/protocols/dumb/client.dart';
import 'package:embedded_micro_services/src/protocols/dumb/packet.dart';
import 'package:embedded_micro_services/src/protocols/dumb/server.dart';
import 'package:embedded_micro_services/src/protocols/shit/client.dart';
import 'package:embedded_micro_services/src/protocols/shit/server.dart';
import 'package:stack_trace/stack_trace.dart';

void main() async {
  Chain.capture(run);
  while (true) {
    await Future.delayed(Duration(seconds: 5));
  }
}

void run() async {
  while (true) {
    final network = Segment();

    final toilet = DartNet(network, 0);
    final firstStack = DartNet(network, 74);
    final secondStack = DartNet(network, 20);

    SHITServer(toilet).serve();

    final firstShitClient = SHITClient(firstStack);
    final secondShitClient = SHITClient(secondStack);

    final hasRegistered = await firstShitClient.register("mom");
    print("First Registered 'mom': $hasRegistered");

    DUMBServer(firstStack, 80, (request) {
      return DUMBResponse(ResponseCode.ok, {}, "DUMBServer Works!");
    }).serve();

    final client = DUMBClient(secondStack, secondShitClient);

    final response = await client.get(address: Uri(host: "mom"));

    print(response.data);
  }
}
