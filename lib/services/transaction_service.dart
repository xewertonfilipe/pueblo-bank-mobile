import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';

class TransactionPage {
  const TransactionPage({required this.items, required this.cursor});

  final List<TransactionModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
}

class TransactionService {
  TransactionService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _collection(userId).orderBy('date', descending: true);
    if (startDate != null) query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    if (endDate != null) query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    if (category != null) query = query.where('category', isEqualTo: category.name);
    if (cursor != null) query = query.startAfterDocument(cursor);

    final snapshot = await query.limit(limit).get();
    return TransactionPage(
      items: snapshot.docs.map(TransactionModel.fromDocument).toList(),
      cursor: snapshot.docs.isEmpty ? cursor : snapshot.docs.last,
    );
  }

  Future<String> create(String userId, TransactionModel transaction) async {
    final reference = transaction.id.isEmpty ? _collection(userId).doc() : _collection(userId).doc(transaction.id);
    await reference.set(transaction.toFirestore());
    return reference.id;
  }

  Future<void> update(String userId, TransactionModel transaction) {
    return _collection(userId).doc(transaction.id).update(transaction.toFirestore());
  }

  Future<void> delete(String userId, String transactionId) {
    return _collection(userId).doc(transactionId).delete();
  }
}
