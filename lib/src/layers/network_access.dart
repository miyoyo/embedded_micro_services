abstract interface class NetworkAccessLayer {
  void connect(Stream<String> input, Sink<String> output);
}
