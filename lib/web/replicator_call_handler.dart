import 'package:couchbase_lite/web/cb_manager.dart';
import 'package:flutter/services.dart';

import 'flutter_call_handler.dart';

class ReplicatorCallHandler extends FlutterCallHandler {
  const ReplicatorCallHandler(this.cbManager);

  final CBManager cbManager;

  @override
  Future<dynamic> handleMethodCall(MethodCall call) async {
    if (!call.hasArgument('replicatorId')) {
      throw PlatformException(code: 'errArgs', message: 'Error: Missing replicator', details: call.arguments.toString());
    }

    String replicatorId = call.argument('replicatorId');
    final replicator = cbManager.getReplicator(replicatorId);

    if (replicator == null) {
      throw PlatformException(code: 'errReplicator', message: 'Error: Replicator already disposed', details: null);
    }

    switch (call.method) {
      case 'start':
        replicator.start(); return;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'CBLite->Replicator->\'${call.method}\' not yet implemented',
        );
    }
  }
}
