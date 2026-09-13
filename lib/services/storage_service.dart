import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _customStorage = storage;

  final FirebaseStorage? _customStorage;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  Future<String> uploadReceipt({
    required String userId,
    required String transactionId,
    required File file,
  }) async {
    final name = file.path.split(RegExp(r'[/\\]')).last;
    final reference = _storage.ref('receipts/$userId/$transactionId/$name');
    await reference.putFile(file);
    return reference.getDownloadURL();
  }

  Future<void> deleteReceipt(String url) => _storage.refFromURL(url).delete();
}
