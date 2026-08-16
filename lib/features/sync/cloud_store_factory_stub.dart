import 'package:firebase_storage/firebase_storage.dart';

import 'cloud_store.dart';
import 'firebase_cloud_store.dart';

CloudStore createCloudStore({
  required String uid,
  FirebaseStorage? storage,
}) {
  return FirebaseCloudStore(uid: uid, storage: storage);
}
