@JS()
library firecouch;

import 'dart:js_util';

import 'package:couchbase_lite/couchbase_lite.dart';
import 'package:js/js.dart';
import 'package:meta/meta.dart';

/// A workaround to converting an object from JS to a Dart Map.
///
/// Only converts a single level.
Map jsToMap(o) => Map.fromIterable(_jsKeys(o), value: (k) => getProperty(o, k));

@JS('Object.keys')
external List<String> _jsKeys(jsObject);

// The `Map` constructor invokes JavaScript `new google.maps.Map(location)`
@JS()
class Firecouch {
  external Firecouch(FirecouchSettings settings);

  external FirecouchSettings get settings;
  external FirecouchBackend get backend;
  external FirecouchSession get session;
  external bool get isReady;
  external Map<String, dynamic> get queue;

  /// Initialize the Firecouch backend.
  ///
  /// Returns a Promise which resolves when the backend has been initialized.
  external Future<bool> initialize();

  /// Get a DocumentReference for the document with the specified id.
  ///
  /// If no id is specified, an automatically-generated unique ID will be used
  /// for the returned DocumentReference.
  external DocumentReference doc(String id);

  /// Add a listener for changes to document with id `id`.
  ///
  /// @returns A unique id which can be passed to `removeListener` to remove the
  /// listener.
  external num addListener<T>(String, void Function(Map<String, dynamic> data) parser,
      void Function(Map<String, dynamic> data) onNext, void Function(dynamic error) onError);

  /// Remove a previously added listener.
  external removeListener(num uid);
}

@JS()
@anonymous
class FirecouchSettings {
  external factory FirecouchSettings({
    /// Domain name or IP address of the Sync Gateway host.
    @required
    String domain,
    /**
     * Bucket to which to connect.
     */
    @required
    String bucket,
    /**
     * Port number. Defaults to 4984.
     */
    num port,
    /**
     * Path to add to where the API is hosted. Defaults to `undefined`.
     *
     * If the server is behind a reverse proxy serving it up under a path
     * belonging to your main site, you can specify it here.
     */
    String path,
    /**
     * Whether to connect over insecure protocols.
     *
     * Connects to WS and HTTP instead of HTTPS and WSS if set to true.
     *
     * Defaults to `false`.
     */
    bool insecure,
    /**
     * Sync Gateway credentials for establishing a session.
     *
     * The session is created with an idle session timeout of 24 hours. An idle
     * session timeout in the context of Sync Gateway is defined as the following:
     *
     * If 10% or more of the current expiration time has elapsed when a subsequent
     * request with that session id is processed, the session’s expiry time is
     * automatically updated to 24 hours from that time.
     */
    FirecouchCredentials authentication,
    /**
     * Firecouch uses a queueing system for simultaneous operations to protect the
     * backend from accidentally being overloaded.
     *
     * For example, every time a write is to be performed, a slot is requested in
     * the queue and if one is available it is reserved during the operation.
     *
     * The queue can be given limits and a strategy can be defined for how to deal
     * with the situation if capacity is ever reached.
     *
     * Capacity is typically reached for one of two reasons:
     *
     *  1. Failure to await calls to `set`.
     *  2. A large number of intentional simultaneous writes.
     *
     * Reason #1 is easily solved by simply `await`ing consecutive calls to `set`.
     *
     * Reason #2 is more challenging to solve. It requires managing the flow of
     * writes or allowing loss of data.
     *
     *  * Managing the flow can be done by either bulking operations or attempting
     * to smooth out peaks and valleys in data rates if having instantaneous
     * writes isn't important.
     *  * Allowing loss of data can be achieved by using the `drop` strategy to
     * not write any new data whenever capacity has been reached.
     *  * A combination of both with smarter filters can be achieved by using the
     * `call` strategy and using a callback to take over management of the queue
     * when it reaches capacity.
     *
     * NOTE: This does not serve as protection from denial of service or other
     * similar attacks. Such features can only be implemented on the server itself
     * or right in front of it, before the client.
     */
    Map<String, dynamic> queueOptions,
  });
}

@JS()
@anonymous
class FirecouchCredentials {
  external String get username;
  external String get password;
  external factory FirecouchCredentials({
    @required String username,
    @required String password,
  });
}

@JS()
@anonymous
class FirecouchSession {
  external FirecouchCredentials get credentials;
  external FirecouchCredentials get authenticator;
  external String get user;

  external factory FirecouchSession({FirecouchBackend backend, FirecouchCredentials credentials});
  /// Authenticates using the credentials passed to the constructor.
  external void initialize();

  /// Note: this is an admin feature and requires setting up a reverse proxy
  /// forwarding the PUT request to `/{db}/_users/add/{name}` to a PUT request
  /// to `/{db}/_users/{name}` on the Sync Gateway admin server.
  ///
  /// Creates a new user account associated with the specified email address and
  /// password.
  ///
  /// On successful creation of the user account, this user will also be
  /// signed in to your application.
  ///
  /// User account creation can fail if the account already exists or the
  /// password is invalid.
  ///
  /// Note: The email address acts as a unique identifier for the user and
  /// enables an email-based password reset. This method will create a new user
  /// account and set the initial user password.
  ///
  /// Parameters:
  /// [email] The user's email address.
  /// [password] The user's chosen password.
  /// Returns a Future that resolves to `true` on success and `false` on
  /// failure.
  external Future<bool> createUserWithEmailAndPassword(String email, String password, List<String> roles);

  /// Asynchronously signs in using an email and password.
  ///
  /// Fails with an error if the email address and password do not match.
  ///
  /// Note: The user's password is NOT the password used to access the user's
  /// email account. The email address serves as a unique identifier for the
  /// user, and the password is used to access the user's data in your
  /// Firecouch bucket.
  ///
  /// Returns a Future that resolves to `true` on success and `false` on failure
  /// when authentication is complete.
  external Future<bool> signInWithEmailAndPassword(String email, String password);

  /// Signs out the current user.
  ///
  /// Returns a Future that resolves when operation is complete.
  external Future<void> signOut();

  /// Returns a short user identifier which is unique to the email address
  /// given.
  external String _getUuidFromEmail(String email);
}

@JS()
@anonymous
class FirecouchBackend {
  external Database get db;
  external FirecouchSettings get settings;
  external bool get initialized;

  external factory FirecouchBackend({Firecouch parent, FirecouchSettings settings});

  /// Initializes the backend.
  ///
  /// Returns a Future which resolves when initialized.
  external Future<void> initialize();

  /// Add a listener for changes to document with id `id`.
  ///
  /// Returns a unique ListenerToken which can be passed to `removeListener` to
  /// remove the listener.
  external ListenerToken addListener<T>(String id,
      Map<String, dynamic> Function(String id, Map<String, dynamic> data) parser,
      void Function(DocumentSnapshot data) onNext,
      [void Function(dynamic error) onError]);

  /// Remove a previously added listener.
  ///
  /// Returns a Future that resolves when action is complete.
  external Future<void> removeListener(ListenerToken token);

  /// Reconnect with new session details.
  ///
  /// [createNewSession] should be called any time changes happen to the
  /// session. For example, when a user logs in or out.
  ///
  /// Disconnects from the backend then reconnects with the new session.
  ///
  /// Returns a Future which resolves once the new connection has been
  /// established.
  external Future<void> createNewSession();

  /// Returns the name of the bucket to which Firecouch is currently connected.
  external String getBucket();

  /// Returns a connection string for connecting to a Sync Gateway server.
  external getConnectionString([String protocol]);

  /// Returns a full resource string for connecting to a Sync Gateway server.
  ///
  /// The resource string is equal to:
  ///
  ///    `${getConnectionString(protocol)}/${settings.bucket}/${api}`
  external getResourceString([String protocol, String api]);
}

@JS()
@anonymous
class DocumentSnapshot {
  external const factory DocumentSnapshot({
      String id,
      Map<String, dynamic> data,
      Map<String, dynamic> Function(String id, Map<String, dynamic> data) parser});

  /// Document identifier.
  external String get id;

  /// Retrieves all fields in the document as a Map.
  ///
  /// Returns an object containing all fields in the document or 'null' if the
  /// document doesn't exist.
  external dynamic data();
}

@JS()
@anonymous
class DocumentReference {
  external String get id;
  /// Attaches a listener for document change events.
  /// If the document already exists this function will be called immediately
  /// with the current contents when the connection has been established.
  ///
  /// Parameters:
  /// [onNext] A callback to be called every time a new document change is
  /// available.
  /// [onError] A callback to be called if the listen fails or is
  /// cancelled. No further callbacks will occur.
  ///
  /// Returns an unsubscribe function that can be called to cancel the snapshot
  /// listener.
  external void Function() onSnapshot(void Function(DocumentSnapshot document) onNext,
    void Function(dynamic error) onError);

  /// Writes to the document referred to by `DocumentReference`. If the
  /// document does not yet exist, it will be created.
  ///
  /// If two or more writes are performed simultaneously, the last write wins.
  ///
  /// [data] A map of the fields and values for the document.
  /// [options] Change the default behavior of set.
  /// Returns a Promise resolved once the data has been successfully written
  /// to the backend.
  external Future<void> set(Map<String, dynamic> data);

  /// Deletes the document referred to by this `DocumentReference`.
  ///
  /// Returns a Promise resolved once the document has been successfully
  /// deleted from the backend.
  external Future<void> delete();

  /// Reads the document referred to by this `DocumentReference`.
  ///
  /// Parameters:
  /// [keepMetaData] Whether or not to keep meta data used by Firecouch
  /// internally for housekeeping and authentication. Defaults to `false`.
  ///
  /// Returns a Promise resolved with a FirecouchDocument containing the
  /// current document contents if document exists, otherwise `null`.
  external Future<FirecouchDocument> get([bool keepMetaData = false]);
}

@JS()
@anonymous
class FirecouchDocument {
  external String get id;
  external Map get data;

  /// Strip meta data from a document.
  ///
  /// Firecouch sets some fields under '$_firecouch' for housekeeping as well as
  /// authentication purposes. This method removes all such data and returns
  /// only the relevant data.
  ///
  /// @param data `Map<String, dynamic>` from which to strip metadata.
  /// @returns `data` with all metadata removed.
  external static Map stripMetaData(Map data);
}
