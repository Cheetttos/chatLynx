import 'package:flutter/services.dart';

class IncomingCallChannel {
  static const MethodChannel _channel =
      MethodChannel('com.example.chatlynx/incoming_call');

  static Future<Map<String, String>> getIncomingCallData() async {
    final result = await _channel.invokeMethod('getIncomingCallData');
    return result.cast<String, String>();
  }
}
