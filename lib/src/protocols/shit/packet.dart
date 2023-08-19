import 'dart:convert';

enum SHITAction {
  resolve,
  register,
  unregister,
}

class SHITPacket {
  SHITPacket(
    this.action,
    this.host,
  );

  SHITAction action;
  String host;

  String serialize() {
    return """{
      "action": ${action.index},
      "host": "${base64Encode(utf8.encode(host))}"
    }""";
  }

  factory SHITPacket.deserialize(String raw) {
    final deserialized = jsonDecode(raw);
    if (deserialized is! Map<String, dynamic> ||
        !deserialized.containsKey("action") ||
        deserialized["action"] is! num ||
        !deserialized.containsKey("host") ||
        deserialized["host"] is! String) {
      throw FormatException("Malformed DUMB Packet");
    }

    return SHITPacket(
      SHITAction.values[deserialized["action"].toInt()],
      utf8.decode(base64Decode(deserialized["host"])),
    );
  }
}
