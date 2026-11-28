import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/logging/app_logger.dart';

/// Batas ukuran maksimum lampiran pengajuan cuti (4 MB, sesuai validasi API).
const int maxLeaveAttachmentBytes = 4 * 1024 * 1024;

/// Ekstensi file yang diizinkan oleh API pengajuan cuti.
const List<String> allowedLeaveAttachmentExtensions = [
  'jpg',
  'jpeg',
  'png',
  'pdf',
];

/// Data file lampiran yang dipilih pengguna sebelum diunggah ke server.
class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.sizeBytes,
    this.path,
    this.bytes,
  });

  final String name;
  final int sizeBytes;
  final String? path;
  final Uint8List? bytes;

  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  bool get isWithinSizeLimit => sizeBytes <= maxLeaveAttachmentBytes;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Kontrak pemilih file agar mudah di-mock pada unit & widget test.
abstract class AttachmentPicker {
  Future<PickedAttachment?> pickAttachment();
}

/// Implementasi `AttachmentPicker` menggunakan package `file_picker`.
class FilePickerAttachmentPicker implements AttachmentPicker {
  FilePickerAttachmentPicker(this._logger);

  final Logger _logger;

  @override
  Future<PickedAttachment?> pickAttachment() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Pilih Lampiran (JPG, PNG, PDF)',
        type: FileType.custom,
        allowedExtensions: allowedLeaveAttachmentExtensions,
      );
      if (file == null) return null;

      final path = file.path;
      final knownSize = file.lengthSync() ?? await file.length();

      // Pada Android content:// URI atau Web, path bisa null sehingga kita baca bytes-nya.
      Uint8List? bytes;
      if (path == null &&
          (knownSize == null || knownSize <= maxLeaveAttachmentBytes)) {
        bytes = await file.readAsBytes();
      }

      return PickedAttachment(
        name: file.name,
        sizeBytes: knownSize ?? bytes?.length ?? 0,
        path: path,
        bytes: bytes,
      );
    } on MissingPluginException catch (error, stackTrace) {
      _logger.e(
        'file_picker plugin belum terdaftar di native build',
        error: error,
        stackTrace: stackTrace,
      );
      throw const UnknownException(
        'Plugin pemilih file belum aktif. Hentikan aplikasi lalu jalankan ulang (full rebuild).',
      );
    } on PlatformException catch (error, stackTrace) {
      _logger.w(
        'Gagal memilih file dari perangkat',
        error: error,
        stackTrace: stackTrace,
      );
      final detail = error.message?.trim();
      throw UnknownException(
        detail != null && detail.isNotEmpty
            ? 'Gagal membuka pemilih file: $detail'
            : 'Gagal membuka pemilih file.',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Error tak terduga saat memilih lampiran',
        error: error,
        stackTrace: stackTrace,
      );
      throw const UnknownException(
        'Gagal memilih file lampiran. Silakan coba lagi.',
      );
    }
  }
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => FilePickerAttachmentPicker(ref.watch(loggerProvider)),
);
