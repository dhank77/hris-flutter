import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/network/api_guard.dart';
import 'package:flutter_antigravity_starter_pack/core/network/dio_provider.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/models/face_profile.dart';

/// Data source HTTP untuk fitur Registrasi & Pengenalan Wajah (`/api/face`).
class FaceRecognitionApi {
  FaceRecognitionApi(this._dio);

  final Dio _dio;

  Future<FaceStatus> fetchStatus() => guardApi(() async {
    final response = await _dio.get<Object?>('/face');
    return FaceStatus.fromJson(asJsonObject(response.data));
  });

  Future<FaceRegisterResult> registerFace({
    required List<double> embedding,
    String modelVersion = 'mobilefacenet',
  }) => guardApi(() async {
    final response = await _dio.post<Object?>(
      '/face/register',
      data: {'embedding': embedding, 'model_version': modelVersion},
    );
    return FaceRegisterResult.fromJson(asJsonObject(response.data));
  });

  Future<FaceVerifyResult> verifyFace({required List<double> embedding}) =>
      guardApi(() async {
        final response = await _dio.post<Object?>(
          '/face/verify',
          data: {'embedding': embedding},
        );
        return FaceVerifyResult.fromJson(asJsonObject(response.data));
      });

  Future<String> deleteFace() => guardApi(() async {
    final response = await _dio.delete<Object?>('/face');
    final json = asJsonObject(response.data);
    return (json['message'] as String?) ?? 'Data wajah berhasil dihapus.';
  });
}

final faceRecognitionApiProvider = Provider<FaceRecognitionApi>(
  (ref) => FaceRecognitionApi(ref.watch(dioProvider)),
);
