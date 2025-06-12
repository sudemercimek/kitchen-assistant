import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

Future<String?> uploadImage(Uint8List fileBytes, String fileName) async {
  try {
    final ref = FirebaseStorage.instance.ref().child('recipes/$fileName');
    final uploadTask = await ref.putData(fileBytes);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  } catch (e) {
    print('Image upload error: $e');
    return null;
  }
}
