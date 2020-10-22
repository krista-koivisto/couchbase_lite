import 'package:couchbase_lite/couchbase_lite.dart' as cblite;

class Replicator {
  const Replicator(this.data);

  final Map<String, dynamic> data;

  cblite.ListenerToken addChangeListener(void Function(cblite.ReplicatorChange change) callback) {
    return cblite.ListenerToken();
  }

  cblite.ListenerToken addDocumentReplicationListener(void Function(cblite.DocumentReplication change) callback) {
    return cblite.ListenerToken();
  }

  void start() {
    print('Totally starting over here for sure... Yup!');
  }
}
