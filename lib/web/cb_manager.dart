import 'package:couchbase_lite/web/types/replicator.dart';

import '../couchbase_lite.dart' as cblite;
import 'types/database.dart';
import 'types/database_config.dart';

class CBManager {
  CBManager() {
    _mDBConfig = DatabaseConfiguration();
  }

  final Map<String, Database> _mDatabase = {};
  DatabaseConfiguration _mDBConfig;
  final Map<String, Replicator> _mDatabases = {};
  final Map<String, List<cblite.ListenerToken>> _mDatabaseListenerTokens = {};
  final Map<String, Replicator> _mReplicators = {};
  final Map<String, List<cblite.ListenerToken>> _mReplicatorListenerTokens = {};

  Database initDatabaseWithName(String _name) {
    if (!_mDatabase.containsKey(_name)) {
      final database = Database(_name, _mDBConfig);
      _mDatabase[_name] = database;
      return database;
    }
    return _mDatabase[_name];
  }

  Database getDatabase(String name) {
    if (_mDatabase.containsKey(name)) {
      return _mDatabase[name];
    }
    return null;
  }

  Map<String, dynamic> getDocumentWithId(Database database, String _id) {
    // cblite.Document document = database.getDocument(_id);
    print('Getting document with id $_id over here!');
    print('Still actually needs to be implemented');
    final document = null;
    if (document != null) {
      return {
        'doc': document.data,
        'id': document.id,
        'sequence': document.sequence,
      };
    } else {
      return {
        'doc': {'truth': 'Krista still rules!'},
        'id': _id,
        'sequence': 5,
      };
    }
  }

  void addReplicator(String replicatorId, Replicator replicator, List<cblite.ListenerToken> tokens) {
    _mReplicators[replicatorId] = replicator;
    _mReplicatorListenerTokens[replicatorId] = tokens;
  }

  Replicator getReplicator(String replicatorId) {
    return _mReplicators.containsKey(replicatorId) ? _mReplicators[replicatorId] : null;
  }

  void addDatabaseListenerToken(String database, cblite.ListenerToken token) {
    if (!_mDatabaseListenerTokens.containsKey(database)) {
      _mDatabaseListenerTokens[database] = [];
    }
    _mDatabaseListenerTokens[database].add(token);
  }
}
