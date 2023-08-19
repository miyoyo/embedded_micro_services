import 'dart:async';

import 'package:embedded_micro_services/src/layers/network_access.dart';

class Segment implements NetworkAccessLayer {
  final _bus = StreamController<String>.broadcast();

  @override
  StreamSubscription<String> connect(
    Stream<String> input,
    Sink<String> output,
  ) {
    input.listen((e) {
      _bus.add(e);
    });
    return _bus.stream.listen(output.add);
  }

  Future<void> dispose() => _bus.close();
}
