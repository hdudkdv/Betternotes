import 'package:firebase_storage/firebase_storage.dart';

import 'cloud_store.dart';
import 'firebase_cloud_store.dart';
import 'r2_cloud_store.dart';

CloudStore createCloudStore({
  required String uid,
  FirebaseStorage? storage,
}) {
  const accountId = String.fromEnvironment('CLOUD_R2_ACCOUNT_ID');
  if (accountId.isNotEmpty) {
    return R2CloudStore(uid: uid);
  }
  return FirebaseCloudStore(uid: uid, storage: storage);
}
