part of couchbase_lite;

enum ReplicatorActivityLevel { busy, idle, offline, stopped, connecting }

class Replicator {
  Replicator(this.config) {
    //this.config._isLocked = true;
    _nativeIsReady = _jsonChannel.invokeMethod('storeReplicator', this);
  }

  static const MethodChannel _methodChannel =
      MethodChannel('com.saltechsystems.couchbase_lite/replicator');
  static const JSONMethodCodec _jsonMethod = JSONMethodCodec();
  static const MethodChannel _jsonChannel =
      MethodChannel('com.saltechsystems.couchbase_lite/json', _jsonMethod);
  static const EventChannel _replicationEventChannel =
      EventChannel('com.saltechsystems.couchbase_lite/replicationEventChannel');
  static final Stream _replicationStream =
      _replicationEventChannel.receiveBroadcastStream();

  final replicatorId = Uuid().v1();
  final Map<ListenerToken, StreamSubscription> tokens = {};

  final ReplicatorConfiguration config;
  Future<void> _nativeIsReady;

  /// Starts the replicator.
  ///
  /// The replicator runs asynchronously and will report its progress through
  /// the replicator change notification.
  ///
  /// Returns a Future which resolves to `true` once the replicator activity
  /// level has reached [idle]. Resolves to `false` if a timeout was specified
  /// and reached before the `idle` activity level was reported or if an error
  /// happened.
  Future<bool> start({int timeout}) async {
    await _nativeIsReady;
    await _methodChannel
        .invokeMethod('start', <String, dynamic>{'replicatorId': replicatorId});
    return waitForStatus(ReplicatorActivityLevel.idle, errorStatuses: [
      ReplicatorActivityLevel.stopped,
    ], timeout: timeout);
  }

  /// Stops a running replicator.
  ///
  /// When the replicator stops, the replicator will change its status’s
  /// activity level to .stopped and the replicator change notification will be
  /// notified accordingly.
  ///
  /// Returns a Future that resolves to `true` once the replicator has stopped.
  /// Resolves to `false` if a timeout was specified and reached before the
  /// `.stopped` activity level was reported or if an error happened.
  Future<bool> stop({int timeout}) async {
    await _nativeIsReady;
    await _methodChannel
        .invokeMethod('stop', <String, dynamic>{'replicatorId': replicatorId});
    return waitForStatus(ReplicatorActivityLevel.stopped, timeout: timeout);
  }

  /// Resets the local checkpoint of the replicator, meaning that it will read
  /// all changes since the beginning of time from the remote database.
  Future<void> resetCheckpoint() async {
    await _nativeIsReady;
    await _methodChannel.invokeMethod(
        'resetCheckpoint', <String, dynamic>{'replicatorId': replicatorId});
  }

  /// Adds a replicator change listener.
  ///
  /// Returns the listener token object for removing the listener.
  ListenerToken addChangeListener(Function(ReplicatorChange) callback) {
    var token = ListenerToken();
    tokens[token] = _replicationStream
        .where((data) => (data['replicator'] == replicatorId &&
            data['type'] == 'ReplicatorChange'))
        .listen((data) {
      var activity = ReplicatorStatus.activityFromString(data['activity']);
      String error;
      if (data['error'] is String) {
        error = data['error'];
      }
      callback(
          ReplicatorChange(this, ReplicatorStatus._internal(activity, error)));
    });
    return token;
  }

  /// Adds a document replicator change listener.
  ///
  /// Returns the listener token object for removing the listener.
  ListenerToken addDocumentReplicationListener(
      Function(DocumentReplication) callback) {
    var token = ListenerToken();
    tokens[token] = _replicationStream
        .where((data) => ((data['replicator'] == replicatorId &&
            data['type'] == 'DocumentReplication')))
        .listen((data) {
      callback(DocumentReplication.fromMap(data)
          .rebuild((b) => b..replicator = this));
    });
    return token;
  }

  /// Removes a change listener with the given listener token.
  Future<ListenerToken> removeChangeListener(ListenerToken token) async {
    var subscription = tokens.remove(token);
    if (subscription != null) {
      await subscription.cancel();
    }
    return token;
  }

  /// Removes all change listeners for this replicator.
  ///
  /// Returns a Future that resolves on task completion.
  Future<void> removeAllChangeListeners() async {
    return Future.forEach(tokens.keys.toList(), (token) async {
      await removeChangeListener(token);
    });
  }

  /// Removes change listeners and references on the Platform.  This should be
  /// called when finished with the replicator to prevent memory leaks.
  Future<void> dispose() async {
    await _nativeIsReady;
    await removeAllChangeListeners();
    await _methodChannel.invokeMethod(
        'dispose', <String, dynamic>{'replicatorId': replicatorId});
  }

  Map<String, dynamic> toJson() {
    return {'replicatorId': replicatorId, 'config': config};
  }

  /// Wait for the Replicator to reach a specific activity level.
  ///
  /// If [timeout] has been specified, waits for the given number of
  /// milliseconds before giving up and resolving to `false`.
  /// Defaults to `undefined`.
  ///
  /// Resolves to `false` if any error is encountered when [stopOnError] is set
  /// to `true`. Defaults to `true`.
  ///
  /// Allows specification of one ore more statuses that are considered errors
  /// by use of [errorStatuses].
  ///
  /// Returns a Future that resolves to `true` when the activity level has been
  /// reached and `false` if timeout is reached before that or an error happens.
  Future<bool> waitForStatus(ReplicatorActivityLevel _status, {
      List<ReplicatorActivityLevel> errorStatuses, int timeout,
      bool stopOnError = true}) async {
    assert(_status != null);
    assert(timeout == null || !timeout.isNegative);
    final completer = Completer<bool>();
    ListenerToken token;
    if (timeout != null) {
      Future.delayed(Duration(milliseconds: timeout), () async {
        await _resolveCompleter(completer, token, false);
      });
    }
    token = addChangeListener((event) async {
      if (event.status.error != null && stopOnError) {
        await _resolveCompleter(completer, token, false);
      } else if (event.status.activity == _status) {
        await _resolveCompleter(completer, token, true);
      } else if (errorStatuses != null && errorStatuses.isNotEmpty) {
        if (errorStatuses.contains(event.status.activity)) {
          await _resolveCompleter(completer, token, false);
        }
      }
    });
    return completer.future;
  }

  /// Resolve a listening completer to [result].
  ///
  /// Stops listening for changes for replicator changes listener [token] and
  /// calls complete on [completer] unless it has previously been completed.
  ///
  /// Returns a Future that resolves once action is complete.
  Future<void> _resolveCompleter<T>(Completer<T> completer, ListenerToken token,
      [FutureOr<T> result]) async {
    assert(completer != null);
    assert(token != null);
    if (tokens.containsKey(token)) {
      await removeChangeListener(token);
    }
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }
}

class ReplicatorStatus {
  ReplicatorStatus._internal(this.activity, this.error);

  final ReplicatorActivityLevel activity;
  final String error;

  static ReplicatorActivityLevel activityFromString(String _status) {
    switch (_status) {
      case 'BUSY':
        return ReplicatorActivityLevel.busy;
        break;
      case 'IDLE':
        return ReplicatorActivityLevel.idle;
        break;
      case 'OFFLINE':
        return ReplicatorActivityLevel.offline;
        break;
      case 'STOPPED':
        return ReplicatorActivityLevel.stopped;
        break;
      case 'CONNECTING':
        return ReplicatorActivityLevel.connecting;
        break;
    }

    return null;
  }
}

class ReplicatorChange {
  const ReplicatorChange(this.replicator, this.status);

  final Replicator replicator;
  final ReplicatorStatus status;
}
