//
// Generated file. Do not edit.
//

// ignore: unused_import
import 'dart:ui';

import 'package:couchbase_lite/web/couchbase_lite.dart';
import 'package:url_launcher_web/url_launcher_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(PluginRegistry registry) {
  CouchbaseLitePlugin.registerWith(registry.registrarFor(CouchbaseLitePlugin));
  UrlLauncherPlugin.registerWith(registry.registrarFor(UrlLauncherPlugin));
  registry.registerMessageHandler();
}
