class DatabaseConfiguration {
  DatabaseConfiguration([bool customDir = false, String directory]) {
    assert(customDir != null);
    _readonly = false;
    _customDir = customDir;
    _directory = directory;
  }

  bool _readonly;
  bool _customDir;
  String _directory;

  //---------------------------------------------
  // API - public methods
  //---------------------------------------------

  /// Returns the path to the directory to store the database in.
  ///
  /// @return the directory
  String getDirectory() {
    return _directory;
  }

  //---------------------------------------------
  // Protected level access
  //---------------------------------------------

  DatabaseConfiguration setDirectory(String directory) {
    assert(directory != null);
    if (_readonly) { throw Exception('DatabaseConfiguration is readonly mode.'); }
    _directory = directory;
    _customDir = true;
    return this;
  }

  DatabaseConfiguration getDatabaseConfiguration() {
    return this;
  }

  bool isReadonly() {
    return _readonly;
  }

  void setReadonly(bool readonly) {
    _readonly = readonly;
  }

  //---------------------------------------------
  // Package level access
  //---------------------------------------------

  /// Set the temp directory based on Database Configuration.
  /// The default temp directory is APP_CACHE_DIR/Couchbase/tmp.
  /// If a custom database directory is set, the temp directory will be
  /// CUSTOM_DATABASE_DIR/Couchbase/tmp.
  void setTempDir() {
    throw UnimplementedError('Local storage not implemented for web.');
  }

  DatabaseConfiguration readonlyCopy() {
    final config = DatabaseConfiguration(_customDir, _directory);
    config.setReadonly(true);
    return config;
  }

  /// Returns the temp directory. The default temp directory is APP_CACHE_DIR/Couchbase/tmp.
  /// If a custom database directory is set, the temp directory will be
  /// CUSTOM_DATABASE_DIR/Couchbase/tmp.
  String _getTempDir() {
    throw UnimplementedError('Local storage not implemented for web.');
  }
}
