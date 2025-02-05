import 'package:sembast/src/api/sembast.dart';
import 'package:sembast/src/database_client_impl.dart';

/// Record ref sembast public extension.
///
/// Provides access helper to data on the store using a given [DatabaseClient].
extension SembastRecordsRefExtension<K, V> on RecordsRef<K, V> {
  /// Delete records
  Future<List<K?>> delete(DatabaseClient databaseClient) async {
    var client = getClient(databaseClient);
    return await client.inTransaction((txn) async {
      var sembastStore = client.getSembastStore(store);
      return (await sembastStore.txnDeleteAll(txn, keys)).cast<K?>();
    });
  }

  /// Get all records snapshot.
  Future<List<RecordSnapshot<K, V>?>> getSnapshots(
      DatabaseClient databaseClient) async {
    var client = getClient(databaseClient);

    return client
        .getSembastStore(store)
        .txnGetRecordSnapshots(client.sembastTransaction, this);
  }

  /// Create records that don't exist.
  ///
  /// The list of [values] must match the list of keys.
  ///
  /// Returns a list of the keys, if not inserted, a key is null.
  Future<List<K?>> add(DatabaseClient databaseClient, List<V> values) {
    if (values.length != keys.length) {
      throw ArgumentError('the list of values must match the list of keys');
    }
    var client = getClient(databaseClient);
    return client.inTransaction((txn) async {
      return await client
          .getSembastStore(store)
          .txnAddAll<K, V>(txn, values, keys);
    });
  }

  /// Save multiple records, creating the one needed.
  ///
  /// if [merge] is true and the field exists, data is merged.
  ///
  /// The list of [values] must match the list of keys.
  ///
  /// Returns the updated values.
  Future<List<V>> put(DatabaseClient databaseClient, List<V> values,
      {bool? merge}) {
    if (values.length != keys.length) {
      throw ArgumentError('the list of values must match the list of keys');
    }
    var client = getClient(databaseClient);
    return client.inTransaction((txn) async {
      return (await client
              .getSembastStore(store)
              .txnPutAll(txn, values, keys, merge: merge))
          .cast<V>();
    });
  }

  /// Update multiple records.
  ///
  /// if value is a map, keys with dot values
  /// refer to a path in the map, unless the key is specifically escaped.
  ///
  /// The list of [values] must match the list of keys.
  ///
  /// Returns the list of updated values, a value being null if the record
  /// does not exist.
  Future<List<V?>> update(DatabaseClient databaseClient, List<V> values) {
    if (values.length != keys.length) {
      throw ArgumentError('the list of values must match the list of keys');
    }
    var client = getClient(databaseClient);
    return client.inTransaction((txn) async {
      return (await client
              .getSembastStore(store)
              .txnUpdateAll(txn, values, keys))
          .cast<V?>();
    });
  }

  /// Get all records values.
  Future<List<V?>> get(DatabaseClient client) async =>
      (await getSnapshots(client))
          .map((snapshot) => snapshot?.value)
          .toList(growable: false);
}

/// Records ref mixin.
mixin RecordsRefMixin<K, V> implements RecordsRef<K, V> {
  @override
  late StoreRef<K, V> store;
  @override
  late List<K> keys;

  @override
  RecordRef<K, V> operator [](int index) => store.record(keys[index]);

  @override
  String toString() => 'Records(${store.name}, $keys)';

  /// Cast if needed
  @override
  RecordsRef<RK, RV> cast<RK, RV>() {
    if (this is RecordsRef<RK, RV>) {
      return this as RecordsRef<RK, RV>;
    }
    return store.cast<RK, RV>().records(keys.cast<RK>());
  }
}

/// Records ref implementation.
class SembastRecordsRef<K, V> with RecordsRefMixin<K, V> {
  /// Records ref implementation.
  SembastRecordsRef(StoreRef<K, V> store, Iterable<K> keys) {
    this.store = store;
    this.keys = keys.toList(growable: false);
  }
}
