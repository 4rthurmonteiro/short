import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_link_api/src/exceptions.dart';

/// {@template firestore_link_api}
/// Firestore data provider for short links.
///
/// Links are stored as `links/{code}` with a `url` and a server-set
/// `createdAt`.
/// {@endtemplate}
class FirestoreLinkApi {
  /// {@macro firestore_link_api}
  new({required this._firestore});

  final FirebaseFirestore _firestore;

  /// How long a request may take before it fails.
  ///
  /// On web, a write made while offline otherwise never resolves.
  static const timeout = Duration(seconds: 10);

  CollectionReference<Map<String, dynamic>> get _links =>
      _firestore.collection('links');

  /// Writes `links/{code}` with [url] and a server timestamp.
  ///
  /// Throws a [LinkCodeTakenException] when the write is denied, and a
  /// [LinkApiException] on any other error, including a timeout.
  Future<void> createLink({required String code, required String url}) async {
    try {
      await _links
          .doc(code)
          .set({'url': url, 'createdAt': FieldValue.serverTimestamp()})
          .timeout(timeout);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw LinkCodeTakenException(code);
      }
      throw LinkApiException(error);
    } on Exception catch (error) {
      throw LinkApiException(error);
    }
  }

  /// Returns the URL stored for [code], or `null` if there is none.
  ///
  /// Throws a [LinkApiException] on error, including a timeout.
  Future<String?> getUrl(String code) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _links.doc(code).get().timeout(timeout);
    } on Exception catch (error) {
      throw LinkApiException(error);
    }
    final url = snapshot.data()?['url'];
    return url is String ? url : null;
  }
}
