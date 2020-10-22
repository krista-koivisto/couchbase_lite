import 'package:couchbase_lite/web/cb_manager.dart';
import 'package:flutter/services.dart';

import '../couchbase_lite.dart' as cblite;
import 'flutter_call_handler.dart';

class DatabaseCallHandler extends FlutterCallHandler {
  const DatabaseCallHandler(this.cbManager);

  final CBManager cbManager;

  @override
  Future<dynamic> handleMethodCall(MethodCall call) async {
    // All following methods are database dependent
    if (!call.hasArgument('database')) {
      throw PlatformException(code: 'errArgs',
          message: 'Error: Missing database',
          details: call.arguments.toString());
    }

    String dbname = call.argument('database');
    final database = cbManager.getDatabase(dbname);
    cblite.ConcurrencyControl _concurrencyControl;
    if (call.hasArgument('concurrencyControl')) {
      String arg = call.argument('concurrencyControl');
      if (arg != null) {
        switch (arg) {
          case 'failOnConflict':
            _concurrencyControl = cblite.ConcurrencyControl.failOnConflict;
            break;
          default:
            _concurrencyControl = cblite.ConcurrencyControl.lastWriteWins;
        }
      }
    }

    switch (call.method) {
      case 'initDatabaseWithName':
        try {
          final database = cbManager.initDatabaseWithName(dbname);
          return database.name;
        } catch (e) {
          throw PlatformException(code: 'errInit', message: 'error initializing database with name ' + dbname, details: e.toString());
        }
        break;
      case 'addChangeListener':
        if (database == null) {
          throw PlatformException(code: 'errDatabase', message: 'Database with name ' + dbname + 'not found', details: null);
        }
        final token = database.addChangeListener();
        cbManager.addDatabaseListenerToken(database.name, token);
        break;
      case 'getDocumentWithId':
        if (database == null) {
          throw PlatformException(code: 'errDatabase', message: 'Database with name ' + dbname + 'not found', details: null);
        } else if (!call.hasArgument('id')) {
          throw PlatformException(code: 'errArgs', message: 'Database Error: Invalid Arguments', details: call.arguments.toString());
        }
        final _id = call.argument('id');
        return cbManager.getDocumentWithId(database, _id);
      default:
      throw PlatformException(
        code: 'Unimplemented',
        details: 'CBLite->Database->\'${call.method}\' not yet implemented',
      );
    }
  }
}
