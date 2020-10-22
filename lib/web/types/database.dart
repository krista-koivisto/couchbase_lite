import 'package:couchbase_lite/couchbase_lite.dart' as cblite;
import 'package:couchbase_lite/web/types/database_config.dart';

class Database {
  Database(this.name, DatabaseConfiguration config)
      : config = config.readonlyCopy() {
    open();
  }

  final String name;
  final DatabaseConfiguration config;

  void open() {
    print('[Database->open] Called for db "$name", but not implemented.');
  }

  cblite.ListenerToken addChangeListener() {
    return cblite.ListenerToken();
  }
}
