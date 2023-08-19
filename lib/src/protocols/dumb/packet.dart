import 'dart:convert';

enum RequestType {
  get,
  set,
}

class DUMBRequest {
  DUMBRequest(this.type, this.uri, this.headers, this.data);

  RequestType type;
  Uri uri;
  Map<String, String> headers = {};
  String? data;

  String serialize() {
    return """{
      "type": ${type.index},
      "uri": "${uri.toString()}",
      "headers": ${jsonEncode(headers)},
      "data": ${data != null ? '"${base64Encode(utf8.encode(data!))}"' : null}
    }""";
  }

  factory DUMBRequest.deserialize(String raw) {
    final deserialized = jsonDecode(raw);
    if (deserialized is! Map<String, dynamic> ||
        !deserialized.containsKey("type") ||
        deserialized["type"] is! num ||
        !deserialized.containsKey("uri") ||
        deserialized["uri"] is! String ||
        !deserialized.containsKey("headers") ||
        deserialized["headers"] is! Map<String, dynamic> ||
        !deserialized.containsKey("data") ||
        !(deserialized["data"] == null || deserialized["data"] is String)) {
      throw FormatException("Malformed DUMB Packet");
    }

    String? data;

    if (deserialized["data"] != null) {
      data = utf8.decode(base64Decode(deserialized["data"]));
    }

    return DUMBRequest(
      RequestType.values[deserialized["type"].toInt()],
      Uri.parse(deserialized["uri"]),
      deserialized["headers"].map<String, String>(
          (key, value) => MapEntry(key.toString(), value.toString())),
      data,
    );
  }
}

enum ResponseCode {
  ok,
  notOk,
  notFound,
  badRequest,
  serverError,
}

class DUMBResponse {
  DUMBResponse(this.code, this.headers, this.data);

  ResponseCode code;
  Map<String, String> headers;
  String data;

  String serialize() {
    return """{
      "code": ${code.index},
      "headers": ${jsonEncode(headers)},
      "data": "${base64Encode(utf8.encode(data))}"
    }""";
  }

  factory DUMBResponse.deserialize(String raw) {
    final deserialized = jsonDecode(raw);
    if (deserialized is! Map<String, dynamic> ||
        !deserialized.containsKey("code") ||
        deserialized["code"] is! num ||
        !deserialized.containsKey("headers") ||
        deserialized["headers"] is! Map<String, dynamic> ||
        !deserialized.containsKey("data") ||
        deserialized["data"] is! String) {
      throw FormatException("Malformed DUMB Packet");
    }

    return DUMBResponse(
      ResponseCode.values[deserialized["code"].toInt()],
      deserialized["headers"].map<String, String>(
          (key, value) => MapEntry(key.toString(), value.toString())),
      utf8.decode(base64Decode(deserialized["data"])),
    );
  }
}
