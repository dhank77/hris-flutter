import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/face_recognition_api.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/models/face_profile.dart';

/// Repository fitur Registrasi & Pengenalan Wajah.
class FaceRecognitionRepository {
  FaceRecognitionRepository(this._api);

  final FaceRecognitionApi _api;

  Future<FaceStatus> getStatus() => _api.fetchStatus();

  Future<FaceRegisterResult> registerFace({
    required List<double> embedding,
    String modelVersion = 'mobilefacenet',
  }) => _api.registerFace(embedding: embedding, modelVersion: modelVersion);

  Future<FaceVerifyResult> verifyFace({required List<double> embedding}) =>
      _api.verifyFace(embedding: embedding);

  Future<String> deleteFace() => _api.deleteFace();
}

final faceRecognitionRepositoryProvider = Provider<FaceRecognitionRepository>(
  (ref) => FaceRecognitionRepository(ref.watch(faceRecognitionApiProvider)),
);
