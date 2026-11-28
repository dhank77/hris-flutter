import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  Future<PickedAttachment?> pickAttachment() async {
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
  }
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (_) => FilePickerAttachmentPicker(),
);
