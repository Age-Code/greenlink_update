import 'package:cloud_firestore/cloud_firestore.dart';

/// Deletes every document matched by [query] in batches, well under the
/// 500-write batch limit. Used when a user deletes their account.
Future<void> deleteAllDocuments(
  FirebaseFirestore firestore,
  Query<Map<String, dynamic>> query, {
  int chunk = 400,
}) async {
  while (true) {
    final snapshot = await query.limit(chunk).get();
    if (snapshot.docs.isEmpty) return;
    final batch = firestore.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
    if (snapshot.docs.length < chunk) return;
  }
}
