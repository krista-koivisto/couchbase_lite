// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html show window;
import 'dart:js_util';

import 'package:couchbase_lite/web/cb_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';

import 'database_call_handler.dart';
import 'json_call_handler.dart';
import 'replicator_call_handler.dart';

import 'firecouch.dart';

const saltyTech = 'com.saltechsystems.couchbase_lite';

/// A web implementation of the CouchbaseLite plugin.
class CouchbaseLitePlugin {
  static void registerWith(Registrar registrar) {
    WidgetsFlutterBinding.ensureInitialized();
    final instance = CouchbaseLitePlugin();

    final mCBManager = CBManager();

    final databaseCallHandler = DatabaseCallHandler(mCBManager);
    final replicatorCallHandler = ReplicatorCallHandler(mCBManager);
    final jsonCallHandler = JsonCallHandler(mCBManager);

    final databaseChannel = MethodChannel('$saltyTech/database', const StandardMethodCodec(), registrar.messenger);
    final replicatorChannel = MethodChannel('$saltyTech/replicator', const StandardMethodCodec(), registrar.messenger);
    final jsonChannel = MethodChannel('$saltyTech/json', const JSONMethodCodec(), registrar.messenger);

    test();

    databaseChannel.setMethodCallHandler(databaseCallHandler.handleMethodCall);
    replicatorChannel.setMethodCallHandler(replicatorCallHandler.handleMethodCall);
    jsonChannel.setMethodCallHandler(jsonCallHandler.handleMethodCall);
  }

  static void onUpdate(DocumentSnapshot doc) {
    print(doc);
    final data = doc.data();
    print(data);
    final mapped = jsToMap(data);
    print(mapped);
  }

  static void test() async {
    final firecouch = Firecouch(FirecouchSettings(
      domain: 'appli.fi',
      bucket: 'apps',
      port: 443,
      path: 'api/v1',
      insecure: false,
      authentication: FirecouchCredentials(
        username: 'user',
        password: 'readonly',
      ),
    ));
    await promiseToFuture(firecouch.initialize());
    final ref = firecouch.doc('henlo-vijhBqNbPpEf1j5vQs3Cho');
    // final okay = await promiseToFuture<FirecouchDocument>(ref.get(true));
    ref.onSnapshot(allowInterop(onUpdate), allowInterop((document) => null));
  }
}
