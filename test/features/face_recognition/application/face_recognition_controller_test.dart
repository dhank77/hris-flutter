import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/face/face_embedding_service.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/application/face_recognition_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/face_recognition_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/models/face_profile.dart';

class _MockFaceRecognitionRepository extends Mock
    implements FaceRecognitionRepository {}

class _FakeFaceEmbeddingService implements FaceEmbeddingService {
  _FakeFaceEmbeddingService(this.embeddingToReturn);

  final List<double> embeddingToReturn;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<double>> extractEmbeddingFromFile(String imagePath) async =>
      embeddingToReturn;

  @override
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || a.length != b.length) return 0.0;
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }

  @override
  double euclideanDistance(List<double> a, List<double> b) => 0.0;

  @override
  void dispose() {}
}

void main() {
  late _MockFaceRecognitionRepository repo;
  final sampleEmbedding = List<double>.filled(192, 0.0)..[0] = 1.0;

  setUp(() {
    repo = _MockFaceRecognitionRepository();
  });

  test('build loads unregistered face status', () async {
    when(
      () => repo.getStatus(),
    ).thenAnswer((_) async => const FaceStatus(registered: false));

    final container = ProviderContainer.test(
      overrides: [
        faceRecognitionRepositoryProvider.overrideWithValue(repo),
        faceEmbeddingServiceProvider.overrideWithValue(
          _FakeFaceEmbeddingService(sampleEmbedding),
        ),
      ],
    );

    final state = await container.read(
      faceRecognitionControllerProvider.future,
    );
    expect(state.isRegistered, isFalse);
  });

  test('registerFromImagePath extracts embedding and updates status', () async {
    when(
      () => repo.getStatus(),
    ).thenAnswer((_) async => const FaceStatus(registered: false));
    when(() => repo.registerFace(embedding: sampleEmbedding)).thenAnswer(
      (_) async => FaceRegisterResult(
        message: 'Registrasi wajah berhasil disimpan.',
        registered: true,
        faceProfile: FaceProfile(
          id: 1,
          modelVersion: 'mobilefacenet',
          registeredAt: '2026-11-22T21:30:00Z',
          embedding: sampleEmbedding,
        ),
      ),
    );

    final container = ProviderContainer.test(
      overrides: [
        faceRecognitionRepositoryProvider.overrideWithValue(repo),
        faceEmbeddingServiceProvider.overrideWithValue(
          _FakeFaceEmbeddingService(sampleEmbedding),
        ),
      ],
    );

    await container.read(faceRecognitionControllerProvider.future);
    final message = await container
        .read(faceRecognitionControllerProvider.notifier)
        .registerFromImagePath('/tmp/face.jpg');

    expect(message, 'Registrasi wajah berhasil disimpan.');
    final updated = container
        .read(faceRecognitionControllerProvider)
        .asData
        ?.value;
    expect(updated?.isRegistered, isTrue);
    expect(updated?.status.faceProfile?.embedding.length, 192);
  });

  test(
    'verifyFromImagePath computes local similarity and verifies via API',
    () async {
      when(() => repo.getStatus()).thenAnswer(
        (_) async => FaceStatus(
          registered: true,
          faceProfile: FaceProfile(id: 1, embedding: sampleEmbedding),
        ),
      );
      when(() => repo.verifyFace(embedding: sampleEmbedding)).thenAnswer(
        (_) async => const FaceVerifyResult(
          matched: true,
          similarity: 0.99,
          distance: 0.1,
          threshold: 0.75,
          message: 'Wajah cocok dan berhasil diverifikasi.',
        ),
      );

      final container = ProviderContainer.test(
        overrides: [
          faceRecognitionRepositoryProvider.overrideWithValue(repo),
          faceEmbeddingServiceProvider.overrideWithValue(
            _FakeFaceEmbeddingService(sampleEmbedding),
          ),
        ],
      );

      await container.read(faceRecognitionControllerProvider.future);
      final result = await container
          .read(faceRecognitionControllerProvider.notifier)
          .verifyFromImagePath('/tmp/verify.jpg');

      expect(result.matched, isTrue);
      final updated = container
          .read(faceRecognitionControllerProvider)
          .asData
          ?.value;
      expect(updated?.lastVerifyResult?.matched, isTrue);
      expect(updated?.localSimilarity, closeTo(1.0, 0.001));
    },
  );

  test('deleteFace resets registration status', () async {
    when(() => repo.getStatus()).thenAnswer(
      (_) async => FaceStatus(
        registered: true,
        faceProfile: FaceProfile(id: 1, embedding: sampleEmbedding),
      ),
    );
    when(
      () => repo.deleteFace(),
    ).thenAnswer((_) async => 'Data wajah berhasil dihapus.');

    final container = ProviderContainer.test(
      overrides: [
        faceRecognitionRepositoryProvider.overrideWithValue(repo),
        faceEmbeddingServiceProvider.overrideWithValue(
          _FakeFaceEmbeddingService(sampleEmbedding),
        ),
      ],
    );

    await container.read(faceRecognitionControllerProvider.future);
    final msg = await container
        .read(faceRecognitionControllerProvider.notifier)
        .deleteFace();

    expect(msg, 'Data wajah berhasil dihapus.');
    final updated = container
        .read(faceRecognitionControllerProvider)
        .asData
        ?.value;
    expect(updated?.isRegistered, isFalse);
  });
}
