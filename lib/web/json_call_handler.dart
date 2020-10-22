import 'dart:convert';

import 'package:couchbase_lite/couchbase_lite.dart' as cblite;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'cb_manager.dart';
import 'couchbase_lite.dart';
import 'flutter_call_handler.dart';
import 'types/replicator.dart';

class JsonCallHandler extends FlutterCallHandler {
  const JsonCallHandler(this.cbManager);

  final CBManager cbManager;
  static const channel = '$saltyTech/replicationEventChannel';
  static const codec = StandardMethodCodec();

  @override
  Future<dynamic> handleMethodCall(MethodCall call) async {
    final json = Map<String, dynamic>.from(call.arguments);
    switch (call.method) {
      case 'storeReplicator':
        storeReplicator(json);
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'CBLite->Json->\'${call.method}\' not yet implemented',
        );
    }
  }

  void storeReplicator(Map<String, dynamic> json) {
    try {
      final id = json['replicatorId'];
      final replicator = Replicator(json);

      if (replicator != null) {
        final mListenerToken = replicator.addChangeListener((change) {
          final json = <String, dynamic>{};
          json['replicator'] = id;
          json['type'] = 'ReplicatorChange';

          final error = change.status.error;
          if (error != null) {
            json['error'] = error;
          }

          switch (change.status.activity) {
            case cblite.ReplicatorActivityLevel.busy:
              json['activity'] = 'BUSY';
              break;
            case cblite.ReplicatorActivityLevel.idle:
              json['activity'] = 'IDLE';
              break;
            case cblite.ReplicatorActivityLevel.offline:
              json['activity'] = 'OFFLINE';
              break;
            case cblite.ReplicatorActivityLevel.stopped:
              json['activity'] = 'STOPPED';
              break;
            case cblite.ReplicatorActivityLevel.connecting:
              json['activity'] = 'CONNECTING';
              break;
          }

          FlutterCallHandler.triggerEvent(channel, json);
        });

        final mDocumentReplicationListenerToken = replicator.addDocumentReplicationListener((replication) {
          final json = <String, dynamic>{};
          json['replicator'] = id;
          json['type'] = 'DocumentReplication';
          json['isPush'] = replication.isPush;

          final documents = <Map<String, dynamic>>[];
          replication.documents.forEach((document) {
            final documentReplication = <String, dynamic>{};
            documentReplication['document'] = document.id;
            final error = document.error;
            if (error != null) {
              documentReplication['error'] = error;
            }
            documents.add(documentReplication);
          });

          json['documents'] = documents;

          FlutterCallHandler.triggerEvent(channel, json);
        });

        final tokens = <cblite.ListenerToken>[mListenerToken, mDocumentReplicationListenerToken];
        cbManager.addReplicator(id, replicator, tokens);
      } else {
        throw PlatformException(code: 'errReplicator', message: 'Replicator Error: Failed to initialize replicator', details: null);
      }
    } catch (e) {
      throw PlatformException(code: 'errArg', message: 'Query Error: Invalid Arguments', details: e);
    }

    print('Store that ish!!!');
  }
}
