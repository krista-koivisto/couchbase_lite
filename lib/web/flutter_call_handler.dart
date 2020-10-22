import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

extension NativeArguments on MethodCall {
  bool hasArgument(String argument) {
    if (arguments is Map) {
      return (arguments as Map).containsKey(argument);
    }
    return false;
  }

  dynamic argument(String argument) {
    return arguments[argument];
  }
}

abstract class FlutterCallHandler {
  const FlutterCallHandler();
  /// Handles method calls over the MethodChannel of this plugin.
  Future<dynamic> handleMethodCall(MethodCall call) async {}

  /// Trigger an event.
  ///
  /// This is the same as performing a call to
  /// `EventChannel.EventSink.success(data)` in Java on the native side.
  ///
  /// A [codec] may be specified, but defaults to the standard method codec if
  /// none given.
  static void triggerEvent(String channel, dynamic data,
      {MethodCodec codec = const StandardMethodCodec()}) {
    WidgetsBinding.instance.defaultBinaryMessenger.send(channel,
        codec.encodeSuccessEnvelope(data));
  }
}
