// lib/services/storage_service.dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _picker = ImagePicker();

  /// Galeriden foto seçtirir, Firebase Storage'a yükler, download URL döndürür.
  /// Kullanıcı iptal ederse null döner.
  Future<String?> pickAndUpload({required ImageSource source}) async {
    final XFile? picked = await _picker.pickImage(
      source: source, // ← parametreyi kullan, sabit değil
      maxWidth: 1280,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final Uint8List bytes = await picked.readAsBytes();
    final fileName = 'uploads/${DateTime.now().millisecondsSinceEpoch}.png';
    final ref = FirebaseStorage.instance.ref().child(fileName);

    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    return await ref.getDownloadURL();
  }
}
