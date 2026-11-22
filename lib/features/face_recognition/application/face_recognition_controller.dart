import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/face/face_embedding_service.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/face_recognition_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/models/face_profile.dart';

/// State UI untuk halaman Registrasi & Pengenalan Wajah.
class FaceRecognitionViewState {
  const FaceRecognitionViewState({
    required this.status,
    this.isProcessing = false,
    this.lastVerifyResult,
    this.localSimilarity,
  });

  final FaceStatus status;
  final bool isProcessing;
  final FaceVerifyResult? lastVerifyResult;
  final double? localSimilarity;

  bool get isRegistered => status.registered && status.faceProfile != null;
  bool get canRegister => !isRegistered || status.canReregister;

  FaceRecognitionViewState copyWith({
    FaceStatus? status,
    bool? isProcessing,
    FaceVerifyResult? lastVerifyResult,
    bool clearVerifyResult = false,
    double? localSimilarity,
    bool clearLocalSimilarity = false,
  }) {
    return FaceRecognitionViewState(
      status: status ?? this.status,
      isProcessing: isProcessing ?? this.isProcessing,
      lastVerifyResult: clearVerifyResult
          ? null
          : (lastVerifyResult ?? this.lastVerifyResult),
      localSimilarity: clearLocalSimilarity
          ? null
          : (localSimilarity ?? this.localSimilarity),
    );
  }
}

/// Controller untuk registrasi embedding wajah dan verifikasi pengenalan wajah.
class FaceRecognitionController
    extends AsyncNotifier<FaceRecognitionViewState> {
  @override
  Future<FaceRecognitionViewState> build() async {
    final repo = ref.watch(faceRecognitionRepositoryProvider);
    final status = await repo.getStatus();
    return FaceRecognitionViewState(status: status);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Ekstrak embedding wajah dari file foto [imagePath] dengan TFLite lalu simpan ke Laravel.
  Future<String> registerFromImagePath(String imagePath) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Status wajah belum siap.');
    }

    state = AsyncData(
      current.copyWith(
        isProcessing: true,
        clearVerifyResult: true,
        clearLocalSimilarity: true,
      ),
    );

    try {
      final faceService = ref.read(faceEmbeddingServiceProvider);
      final embedding = await faceService.extractEmbeddingFromFile(imagePath);

      final repo = ref.read(faceRecognitionRepositoryProvider);
      final result = await repo.registerFace(embedding: embedding);

      if (!ref.mounted) return result.message;

      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          status: FaceStatus(
            registered: result.registered,
            canReregister: result.canReregister,
            faceProfile: result.faceProfile,
          ),
          isProcessing: false,
        ),
      );
      return result.message;
    } catch (_) {
      if (ref.mounted) {
        final latest = state.asData?.value ?? current;
        state = AsyncData(latest.copyWith(isProcessing: false));
      }
      rethrow;
    }
  }

  /// Ekstrak embedding wajah dari [imagePath], hitung kemiripan lokal, dan verifikasi ke Laravel.
  Future<({FaceVerifyResult result, List<double> embedding})>
  verifyFromImagePath(String imagePath) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Status wajah belum siap.');
    }

    state = AsyncData(current.copyWith(isProcessing: true));

    try {
      final faceService = ref.read(faceEmbeddingServiceProvider);
      final embedding = await faceService.extractEmbeddingFromFile(imagePath);

      final storedEmbedding = current.status.faceProfile?.embedding;
      final localSimilarity =
          (storedEmbedding != null &&
              storedEmbedding.length == embedding.length)
          ? faceService.cosineSimilarity(storedEmbedding, embedding)
          : null;

      final repo = ref.read(faceRecognitionRepositoryProvider);
      final result = await repo.verifyFace(embedding: embedding);

      if (!ref.mounted) return (result: result, embedding: embedding);

      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isProcessing: false,
          lastVerifyResult: result,
          localSimilarity: localSimilarity,
        ),
      );
      return (result: result, embedding: embedding);
    } catch (_) {
      if (ref.mounted) {
        final latest = state.asData?.value ?? current;
        state = AsyncData(latest.copyWith(isProcessing: false));
      }
      rethrow;
    }
  }
}

final faceRecognitionControllerProvider =
    AsyncNotifierProvider.autoDispose<
      FaceRecognitionController,
      FaceRecognitionViewState
    >(FaceRecognitionController.new);
