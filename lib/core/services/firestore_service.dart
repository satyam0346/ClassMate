import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Generic Firestore CRUD + pagination helpers.
/// All methods use the offline-persistent Firestore instance
/// (persistence enabled in main.dart).
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> col(String path) =>
      _db.collection(path);

  DocumentReference<Map<String, dynamic>> doc(String path) =>
      _db.doc(path);

  // ── Stream (real-time) ────────────────────────────────────

  /// Stream a single document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(String path) =>
      _db.doc(path).snapshots();

  /// Stream a collection with optional ordering and limit.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String       collection,
    List<QueryFilter>     filters   = const [],
    String?               orderBy,
    bool                  descending = false,
    int?                  limit,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    for (final f in filters) {
      query = query.where(f.field, isEqualTo: f.value);
    }
    if (orderBy != null) query = query.orderBy(orderBy, descending: descending);
    if (limit   != null) query = query.limit(limit);
    return query.snapshots();
  }

  // ── Paginated queries ─────────────────────────────────────

  /// Fetch the next page of documents after [lastDoc].
  Future<QuerySnapshot<Map<String, dynamic>>> fetchPage({
    required String   collection,
    required String   orderField,
    bool              descending = false,
    int               pageSize   = 20,
    DocumentSnapshot? lastDoc,
    List<QueryFilter> filters    = const [],
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(collection)
        .orderBy(orderField, descending: descending)
        .limit(pageSize);

    for (final f in filters) {
      query = query.where(f.field, isEqualTo: f.value);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.get();
  }

  // ── One-time reads ────────────────────────────────────────

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String path) =>
      _db.doc(path).get();

  // ── Writes ────────────────────────────────────────────────

  /// Create a new document with auto-generated ID.
  Future<DocumentReference<Map<String, dynamic>>> add(
    String                collection,
    Map<String, dynamic>  data,
  ) =>
      _db.collection(collection).add(data);

  /// Set (create or overwrite) a document at a known path.
  Future<void> set(
    String               path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) =>
      _db.doc(path).set(data, SetOptions(merge: merge));

  /// Update specific fields of an existing document.
  Future<void> update(
    String               path,
    Map<String, dynamic> data,
  ) =>
      _db.doc(path).update(data);

  /// Delete a document.
  Future<void> delete(String path) => _db.doc(path).delete();

  // ── Batch ─────────────────────────────────────────────────

  WriteBatch batch() => _db.batch();

  // ── Server timestamp ──────────────────────────────────────
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  // ── Paginated stream  ─────────────────────────────────────
  /// Stream collection filtered by a field value.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamWhere({
    required String collection,
    required String field,
    required dynamic isEqualTo,
    String?  orderBy,
    bool     descending = false,
    int?     limit,
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection(collection).where(field, isEqualTo: isEqualTo);
    if (orderBy != null) query = query.orderBy(orderBy, descending: descending);
    if (limit   != null) query = query.limit(limit);
    return query.snapshots();
  }
}

/// Simple field filter for Firestore queries.
class QueryFilter {
  final String  field;
  final dynamic value;
  const QueryFilter(this.field, this.value);
}
