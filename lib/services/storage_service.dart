import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class UploadedReceipt {
  const UploadedReceipt({required this.url, required this.path});

  final String url;
  final String path;
}

class StorageService {
  StorageService({FirebaseStorage? storage}) : _customStorage = storage;

  final FirebaseStorage? _customStorage;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  Future<UploadedReceipt> uploadReceipt({
    required String userId,
    required String transactionId,
    required File file,
  }) async {
    final name = file.path.split(RegExp(r'[/\\]')).last;
    final reference = _storage.ref('receipts/$userId/$transactionId/$name');
    await reference.putFile(file);
    return UploadedReceipt(
        url: await reference.getDownloadURL(), path: reference.fullPath);
  }

  Future<void> deleteReceipt(String url) => _storage.refFromURL(url).delete();

  Future<void> deleteReceiptByPath(String path) => _storage.ref(path).delete();
}
