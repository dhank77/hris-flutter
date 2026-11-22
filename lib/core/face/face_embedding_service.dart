import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';

/// Kontrak layanan ekstraksi embedding wajah (ML Kit + TFLite) agar mudah di-fake di test.
abstract interface class FaceEmbeddingService {
  Future<void> initialize();

  /// Mendeteksi satu wajah pada [imagePath], melakukan crop & resize ke 112x112,
  /// lalu menghasilkan vektor embedding ter-normalisasi L2.
  Future<List<double>> extractEmbeddingFromFile(String imagePath);

  double cosineSimilarity(List<double> a, List<double> b);

  double euclideanDistance(List<double> a, List<double> b);

  void dispose();
}

/// Implementasi [FaceEmbeddingService] menggunakan Google ML Kit Face Detection
/// dan model TFLite MobileFaceNet (`assets/models/mobilefacenet.tflite`).
class TfliteFaceEmbeddingService implements FaceEmbeddingService {
  TfliteFaceEmbeddingService({
    this.modelAssetPath = 'assets/models/mobilefacenet.tflite',
    this.inputSize = 112,
  });

  final String modelAssetPath;
  final int inputSize;

  Interpreter? _interpreter;
  FaceDetector? _faceDetector;
  int _outputSize = 192;

  @override
  Future<void> initialize() async {
    if (_interpreter != null && _faceDetector != null) return;

    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter ??= await Interpreter.fromAsset(
        modelAssetPath,
        options: options,
      );
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      if (outputShape.isNotEmpty) {
        _outputSize = outputShape.last;
      }

      _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableTracking: false,
        ),
      );
    } catch (error) {
      throw UnknownException('Gagal memuat model pengenalan wajah: $error');
    }
  }

  @override
  Future<List<double>> extractEmbeddingFromFile(String imagePath) async {
    await initialize();
    final interpreter = _interpreter!;
    final detector = _faceDetector!;

    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await detector.processImage(inputImage);

    if (faces.isEmpty) {
      throw const UnknownException(
        'Wajah tidak terdeteksi. Pastikan wajah berada di dalam bingkai dengan pencahayaan cukup.',
      );
    }
    if (faces.length > 1) {
      throw const UnknownException(
        'Terdeteksi lebih dari satu wajah. Pastikan hanya wajah Anda di dalam kamera.',
      );
    }

    final face = faces.first;
    final yaw = face.headEulerAngleY?.abs() ?? 0;
    final roll = face.headEulerAngleZ?.abs() ?? 0;
    if (yaw > 25 || roll > 25) {
      throw const UnknownException(
        'Posisi wajah terlalu miring. Hadapkan wajah lurus ke kamera.',
      );
    }

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const UnknownException('Gagal membaca file gambar dari kamera.');
    }

    final oriented = img.bakeOrientation(decoded);
    final box = face.boundingBox;

    // Tambahkan sedikit margin agar dagu & dahi tidak terpotong terlalu ketat.
    final marginX = (box.width * 0.1).round();
    final marginY = (box.height * 0.1).round();

    final left = (box.left.round() - marginX).clamp(0, oriented.width - 1);
    final top = (box.top.round() - marginY).clamp(0, oriented.height - 1);
    final right = (box.right.round() + marginX).clamp(left + 1, oriented.width);
    final bottom = (box.bottom.round() + marginY).clamp(
      top + 1,
      oriented.height,
    );

    final cropWidth = right - left;
    final cropHeight = bottom - top;
    if (cropWidth < 40 || cropHeight < 40) {
      throw const UnknownException(
        'Ukuran wajah terlalu kecil. Dekatkan wajah ke kamera.',
      );
    }

    final cropped = img.copyCrop(
      oriented,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );
    final resized = img.copyResize(
      cropped,
      width: inputSize,
      height: inputSize,
    );

    final inputTensor = _imageToFloat32Tensor(resized, inputSize);
    final outputBuffer = List.generate(
      1,
      (_) => List<double>.filled(_outputSize, 0.0),
    );

    interpreter.run(
      inputTensor.reshape([1, inputSize, inputSize, 3]),
      outputBuffer,
    );

    return _l2Normalize(outputBuffer.first);
  }

  Float32List _imageToFloat32Tensor(img.Image image, int size) {
    final buffer = Float32List(size * size * 3);
    var index = 0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final pixel = image.getPixel(x, y);
        buffer[index++] = (pixel.r - 128.0) / 128.0;
        buffer[index++] = (pixel.g - 128.0) / 128.0;
        buffer[index++] = (pixel.b - 128.0) / 128.0;
      }
    }
    return buffer;
  }

  List<double> _l2Normalize(List<double> vector) {
    var sumSquares = 0.0;
    for (final v in vector) {
      sumSquares += v * v;
    }
    final norm = math.sqrt(sumSquares);
    if (norm <= 1e-12) {
      throw const UnknownException('Gagal mengekstrak fitur wajah yang valid.');
    }
    return vector.map((v) => v / norm).toList(growable: false);
  }

  @override
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || a.length != b.length) return 0.0;
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    return denom > 1e-12 ? dot / denom : 0.0;
  }

  @override
  double euclideanDistance(List<double> a, List<double> b) {
    if (a.isEmpty || a.length != b.length) return double.infinity;
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return math.sqrt(sum);
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    unawaited(_faceDetector?.close());
    _faceDetector = null;
  }
}

void unawaited(Future<void>? future) {
  if (future != null) {
    future.catchError((Object error, StackTrace stack) {
      debugPrint('FaceDetector close error: $error');
    });
  }
}

final faceEmbeddingServiceProvider = Provider<FaceEmbeddingService>((ref) {
  final service = TfliteFaceEmbeddingService();
  ref.onDispose(service.dispose);
  return service;
});
