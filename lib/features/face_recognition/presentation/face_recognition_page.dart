import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/async_value_view.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/application/face_recognition_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/face_recognition/data/models/face_profile.dart';

enum _FaceMode { verify, register }

/// Halaman Registrasi Wajah & Pengenalan Wajah berbasis TFLite (MobileFaceNet) + ML Kit.
class FaceRecognitionPage extends ConsumerStatefulWidget {
  const FaceRecognitionPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isCameraInitializing = true;
      _cameraError = null;
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

      // Prioritaskan kamera depan untuk registrasi/pengenalan wajah.
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
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.jpeg,
    );

    _cameraController = controller;
    await previous?.dispose();

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _cameraError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Izin atau inisialisasi kamera gagal: $error';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCameraInitializing) return;
    setState(() => _isCameraInitializing = true);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _captureAndProcess(_FaceMode mode) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      context.showSnackBar('Kamera belum siap.', isError: true);
      return;
    }

    try {
      final photo = await controller.takePicture();
      final notifier = ref.read(faceRecognitionControllerProvider.notifier);

      if (mode == _FaceMode.register) {
        final message = await notifier.registerFromImagePath(photo.path);
        if (!mounted) return;
        setState(() => _selectedMode = _FaceMode.verify);
        context.showSnackBar(message);
      } else {
        final result = await notifier.verifyFromImagePath(photo.path);
        if (!mounted) return;
        context.showSnackBar(result.message, isError: !result.matched);
      }
    } catch (error) {
      if (!mounted) return;
      context.showSnackBar(describeError(error), isError: true);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Wajah?'),
        content: const Text(
          'Data embedding wajah yang tersimpan di server akan dihapus. Anda perlu registrasi ulang untuk pengenalan wajah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final message = await ref
          .read(faceRecognitionControllerProvider.notifier)
          .deleteFace();
      if (!mounted) return;
      setState(() => _selectedMode = _FaceMode.register);
      context.showSnackBar(message);
    } catch (error) {
      if (!mounted) return;
      context.showSnackBar(describeError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceRecognitionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengenalan Wajah'),
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
            onPressed: () =>
                ref.read(faceRecognitionControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: AsyncValueView(
        value: state,
        onRetry: () =>
            ref.read(faceRecognitionControllerProvider.notifier).refresh(),
        data: (viewState) {
          final mode =
              _selectedMode ??
              (viewState.isRegistered ? _FaceMode.verify : _FaceMode.register);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _FaceStatusBanner(viewState: viewState, onDelete: _confirmDelete),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<_FaceMode>(
                segments: [
                  const ButtonSegment(
                    value: _FaceMode.register,
                    icon: Icon(Icons.face_retouching_natural),
                    label: Text('Registrasi Wajah'),
                  ),
                  ButtonSegment(
                    value: _FaceMode.verify,
                    enabled: viewState.isRegistered,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Pengenalan Wajah'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  setState(() => _selectedMode = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _CameraPreviewCard(
                controller: _cameraController,
                isInitializing: _isCameraInitializing,
                error: _cameraError,
                isProcessing: viewState.isProcessing,
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
                        viewState.isProcessing)
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
                      : mode == _FaceMode.register
                      ? (viewState.isRegistered
                            ? 'Perbarui Registrasi Wajah'
                            : 'Ambil & Daftarkan Wajah')
                      : 'Verifikasi Wajah Sekarang',
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
  const _FaceStatusBanner({required this.viewState, required this.onDelete});

  final FaceRecognitionViewState viewState;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRegistered = viewState.isRegistered;
    final profile = viewState.status.faceProfile;

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
                  isRegistered
                      ? 'Wajah Sudah Terdaftar'
                      : 'Wajah Belum Terdaftar',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRegistered
                      ? 'Model: ${profile?.modelVersion ?? 'mobilefacenet'} '
                            '(${profile?.embedding.length ?? 0} dimensi)'
                      : 'Silakan daftarkan wajah Anda terlebih dahulu untuk menggunakan fitur pengenalan wajah.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isRegistered)
            IconButton(
              tooltip: 'Hapus data wajah',
              icon: Icon(Icons.delete_outline, color: colors.error),
              onPressed: viewState.isProcessing ? null : onDelete,
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
    required this.onRetryCamera,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? error;
  final bool isProcessing;
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
                // Panduan posisi wajah berbentuk oval.
                Center(
                  child: Container(
                    width: 210,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(140),
                      border: Border.all(
                        color: isProcessing
                            ? colors.primary
                            : Colors.white.withValues(alpha: 0.85),
                        width: 2.5,
                      ),
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text(
                      'Posisikan wajah di dalam bingkai oval dengan pencahayaan cukup',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
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
