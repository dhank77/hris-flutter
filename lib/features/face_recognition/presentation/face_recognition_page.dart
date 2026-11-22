import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/async_value_view.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/application/face_recognition_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/models/face_profile.dart';

enum _FaceMode { verify, register }

enum _LivenessStage { searchingFace, waitingBlink, eyesClosed, blinkVerified }

/// Halaman Registrasi Wajah & Pengenalan Wajah berbasis TFLite (MobileFaceNet) + ML Kit.
///
/// Mewajibkan deteksi kedipan mata (liveness check) sebelum proses registrasi maupun
/// verifikasi wajah untuk absensi.
class FaceRecognitionPage extends ConsumerStatefulWidget {
  const FaceRecognitionPage({this.attendanceVerifyMode = false, super.key});

  final bool attendanceVerifyMode;

  @override
  ConsumerState<FaceRecognitionPage> createState() =>
      _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends ConsumerState<FaceRecognitionPage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitializing = true;
  String? _cameraError;
  _FaceMode? _selectedMode;

  late final FaceDetector _livenessDetector;
  bool _isProcessingFrame = false;
  _LivenessStage _livenessStage = _LivenessStage.searchingFace;

  @override
  void initState() {
    super.initState();
    _livenessDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true,
      ),
    );
    _initCamera();
  }

  @override
  void dispose() {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream().catchError((_) {});
      }
      controller.dispose();
    }
    _livenessDetector.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isCameraInitializing = true;
      _cameraError = null;
      _livenessStage = _LivenessStage.searchingFace;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isCameraInitializing = false;
          _cameraError = 'Kamera tidak tersedia pada perangkat ini.';
        });
        return;
      }

      final frontIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIndex = frontIndex >= 0 ? frontIndex : 0;
      await _startCameraController(_cameras[_selectedCameraIndex]);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Gagal membuka kamera: $error';
      });
    }
  }

  Future<void> _startCameraController(CameraDescription description) async {
    final previous = _cameraController;
    if (previous != null) {
      if (previous.value.isStreamingImages) {
        await previous.stopImageStream().catchError((_) {});
      }
      await previous.dispose();
    }

    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _cameraError = null;
        _livenessStage = _LivenessStage.searchingFace;
      });
      await _startLivenessStream();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Izin atau inisialisasi kamera gagal: $error';
      });
    }
  }

  Future<void> _startLivenessStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    await controller.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame ||
        !mounted ||
        _livenessStage == _LivenessStage.blinkVerified) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      final faces = await _livenessDetector.processImage(inputImage);
      if (!mounted) return;

      if (faces.length != 1) {
        if (_livenessStage != _LivenessStage.searchingFace) {
          setState(() => _livenessStage = _LivenessStage.searchingFace);
        }
        return;
      }

      final face = faces.first;
      final leftOpen = face.leftEyeOpenProbability;
      final rightOpen = face.rightEyeOpenProbability;
      if (leftOpen == null || rightOpen == null) return;

      const openThreshold = 0.65;
      const closedThreshold = 0.30;

      if (_livenessStage == _LivenessStage.searchingFace) {
        if (leftOpen > openThreshold && rightOpen > openThreshold) {
          setState(() => _livenessStage = _LivenessStage.waitingBlink);
        }
      } else if (_livenessStage == _LivenessStage.waitingBlink) {
        if (leftOpen < closedThreshold && rightOpen < closedThreshold) {
          setState(() => _livenessStage = _LivenessStage.eyesClosed);
        }
      } else if (_livenessStage == _LivenessStage.eyesClosed) {
        if (leftOpen > openThreshold && rightOpen > openThreshold) {
          setState(() => _livenessStage = _LivenessStage.blinkVerified);
        }
      }
    } catch (_) {
      // Abaikan frame yang gagal diproses sementara stream berjalan.
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    if (_cameras.isEmpty) return null;
    final camera = _cameras[_selectedCameraIndex];
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final rawFormat = image.format.raw;
    if (rawFormat is! int) return null;
    final format = InputImageFormatValue.fromRawValue(rawFormat);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

    if (image.planes.isEmpty) return null;
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCameraInitializing) return;
    setState(() => _isCameraInitializing = true);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startCameraController(_cameras[_selectedCameraIndex]);
  }

  void _resetLiveness() {
    if (!mounted) return;
    setState(() => _livenessStage = _LivenessStage.searchingFace);
    _startLivenessStream();
  }

  Future<void> _captureAndProcess(_FaceMode mode) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      context.showSnackBar('Kamera belum siap.', isError: true);
      return;
    }
    if (_livenessStage != _LivenessStage.blinkVerified) {
      context.showSnackBar(
        'Silakan kedipkan mata terlebih dahulu sebelum memproses wajah.',
        isError: true,
      );
      return;
    }

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final photo = await controller.takePicture();
      final notifier = ref.read(faceRecognitionControllerProvider.notifier);

      if (mode == _FaceMode.register) {
        final message = await notifier.registerFromImagePath(photo.path);
        if (!mounted) return;
        setState(() => _selectedMode = _FaceMode.verify);
        context.showSnackBar(message);
        _resetLiveness();
      } else {
        final outcome = await notifier.verifyFromImagePath(photo.path);
        if (!mounted) return;
        if (widget.attendanceVerifyMode && outcome.result.matched) {
          Navigator.of(context).pop<List<double>>(outcome.embedding);
          return;
        }
        context.showSnackBar(
          outcome.result.message,
          isError: !outcome.result.matched,
        );
        _resetLiveness();
      }
    } catch (error) {
      if (!mounted) return;
      context.showSnackBar(describeError(error), isError: true);
      _resetLiveness();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceRecognitionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attendanceVerifyMode
              ? 'Verifikasi Wajah Absensi'
              : 'Pengenalan Wajah',
        ),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              tooltip: 'Ganti kamera',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: _switchCamera,
            ),
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(faceRecognitionControllerProvider.notifier).refresh();
              _resetLiveness();
            },
          ),
        ],
      ),
      body: AsyncValueView(
        value: state,
        onRetry: () =>
            ref.read(faceRecognitionControllerProvider.notifier).refresh(),
        data: (viewState) {
          final mode = !viewState.isRegistered
              ? _FaceMode.register
              : (!viewState.canRegister
                    ? _FaceMode.verify
                    : (_selectedMode ?? _FaceMode.verify));
          final isBlinkVerified =
              _livenessStage == _LivenessStage.blinkVerified;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _FaceStatusBanner(
                viewState: viewState,
                attendanceVerifyMode: widget.attendanceVerifyMode,
              ),
              const SizedBox(height: AppSpacing.md),
              if (viewState.canRegister && viewState.isRegistered) ...[
                SegmentedButton<_FaceMode>(
                  segments: const [
                    ButtonSegment(
                      value: _FaceMode.register,
                      icon: Icon(Icons.face_retouching_natural),
                      label: Text('Registrasi Ulang'),
                    ),
                    ButtonSegment(
                      value: _FaceMode.verify,
                      icon: Icon(Icons.verified_user_outlined),
                      label: Text('Pengenalan Wajah'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedMode = selection.first);
                    _resetLiveness();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _CameraPreviewCard(
                controller: _cameraController,
                isInitializing: _isCameraInitializing,
                error: _cameraError,
                isProcessing: viewState.isProcessing,
                livenessStage: _livenessStage,
                onRetryCamera: _initCamera,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                key: Key(
                  mode == _FaceMode.register
                      ? 'face.registerButton'
                      : 'face.verifyButton',
                ),
                onPressed:
                    (_isCameraInitializing ||
                        _cameraError != null ||
                        viewState.isProcessing ||
                        !isBlinkVerified)
                    ? null
                    : () => _captureAndProcess(mode),
                icon: viewState.isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        mode == _FaceMode.register
                            ? Icons.camera_alt_rounded
                            : Icons.face_rounded,
                      ),
                label: Text(
                  viewState.isProcessing
                      ? 'Memproses wajah...'
                      : !isBlinkVerified
                      ? 'Kedipkan Mata Terlebih Dahulu'
                      : mode == _FaceMode.register
                      ? (viewState.isRegistered
                            ? 'Perbarui Registrasi Wajah'
                            : 'Ambil & Daftarkan Wajah')
                      : (widget.attendanceVerifyMode
                            ? 'Verifikasi Wajah & Lanjutkan Absensi'
                            : 'Verifikasi Wajah Sekarang'),
                ),
              ),
              if (viewState.lastVerifyResult != null) ...[
                const SizedBox(height: AppSpacing.md),
                _VerifyResultCard(
                  result: viewState.lastVerifyResult!,
                  localSimilarity: viewState.localSimilarity,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FaceStatusBanner extends StatelessWidget {
  const _FaceStatusBanner({
    required this.viewState,
    required this.attendanceVerifyMode,
  });

  final FaceRecognitionViewState viewState;
  final bool attendanceVerifyMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRegistered = viewState.isRegistered;
    final canRegister = viewState.canRegister;
    final profile = viewState.status.faceProfile;

    final String title;
    final String subtitle;

    if (!isRegistered) {
      title = 'Wajah Belum Terdaftar';
      subtitle = attendanceVerifyMode
          ? 'Anda harus mendaftarkan wajah terlebih dahulu sebelum melakukan absensi.'
          : 'Registrasi wajah hanya dapat dilakukan 1 kali. Pastikan pencahayaan baik.';
    } else if (canRegister) {
      title = 'Registrasi Ulang Diizinkan Admin';
      subtitle =
          'Model: ${profile?.modelVersion ?? 'mobilefacenet'} • Anda dapat memperbarui data wajah satu kali.';
    } else {
      title = 'Wajah Sudah Terdaftar';
      subtitle = attendanceVerifyMode
          ? 'Posisikan wajah di bingkai oval dan kedipkan mata untuk verifikasi absensi.'
          : 'Registrasi terkunci (1x). Hubungi admin jika perlu izin registrasi ulang.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isRegistered
            ? colors.primaryContainer.withValues(alpha: 0.45)
            : colors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isRegistered ? colors.primary : colors.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRegistered
                ? Icons.verified_user_rounded
                : Icons.face_retouching_off_rounded,
            color: isRegistered ? colors.primary : colors.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  const _CameraPreviewCard({
    required this.controller,
    required this.isInitializing,
    required this.error,
    required this.isProcessing,
    required this.livenessStage,
    required this.onRetryCamera,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? error;
  final bool isProcessing;
  final _LivenessStage livenessStage;
  final VoidCallback onRetryCamera;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 360,
        color: colors.surfaceContainerHighest,
        child: Builder(
          builder: (context) {
            if (isInitializing) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null ||
                controller == null ||
                !controller!.value.isInitialized) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_off_rounded,
                        size: 40,
                        color: colors.error,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        error ?? 'Kamera tidak tersedia.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: onRetryCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final (hintText, badgeColor) = switch (livenessStage) {
              _LivenessStage.searchingFace => (
                'Posisikan wajah di dalam bingkai oval',
                Colors.black.withValues(alpha: 0.65),
              ),
              _LivenessStage.waitingBlink => (
                'Wajah terdeteksi — Kedipkan mata Anda sekarang',
                Colors.orange.shade800.withValues(alpha: 0.85),
              ),
              _LivenessStage.eyesClosed => (
                'Mata tertutup — Buka mata kembali',
                Colors.orange.shade800.withValues(alpha: 0.85),
              ),
              _LivenessStage.blinkVerified => (
                'Kedipan terdeteksi ✓ Silakan lanjutkan',
                Colors.green.shade700.withValues(alpha: 0.9),
              ),
            };

            return Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller!.value.previewSize?.height ?? 300,
                    height: controller!.value.previewSize?.width ?? 400,
                    child: CameraPreview(controller!),
                  ),
                ),
                // Area di luar bingkai oval wajah berwarna hijau semi-transparan.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FaceOvalOverlayPainter(
                      ovalWidth: 210,
                      ovalHeight: 260,
                      outsideColor: Colors.green.withValues(alpha: 0.45),
                      borderColor: isProcessing
                          ? colors.primary
                          : livenessStage == _LivenessStage.blinkVerified
                          ? Colors.lightGreenAccent
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.sm,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      hintText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Painter untuk memberi warna hijau di luar bingkai oval wajah.
class _FaceOvalOverlayPainter extends CustomPainter {
  const _FaceOvalOverlayPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.outsideColor,
    required this.borderColor,
  });

  final double ovalWidth;
  final double ovalHeight;
  final Color outsideColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: ovalWidth,
      height: ovalHeight,
    );

    final overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(ovalRect);

    canvas.drawPath(overlayPath, Paint()..color = outsideColor);

    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_FaceOvalOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.outsideColor != outsideColor ||
      oldDelegate.ovalWidth != ovalWidth ||
      oldDelegate.ovalHeight != ovalHeight;
}

class _VerifyResultCard extends StatelessWidget {
  const _VerifyResultCard({required this.result, this.localSimilarity});

  final FaceVerifyResult result;
  final double? localSimilarity;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final matched = result.matched;
    final bg = matched ? colors.primaryContainer : colors.errorContainer;
    final fg = matched ? colors.onPrimaryContainer : colors.onErrorContainer;
    final percent = (result.similarity * 100).clamp(0, 100).toStringAsFixed(1);
    final thresholdPercent = (result.threshold * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            matched ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: fg,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matched ? 'Wajah Dikenali' : 'Wajah Tidak Cocok',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.message,
                  style: context.textTheme.bodySmall?.copyWith(color: fg),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kemiripan: $percent% (minimum $thresholdPercent%)'
                  '${localSimilarity != null ? ' • Lokal: ${(localSimilarity! * 100).toStringAsFixed(1)}%' : ''}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
