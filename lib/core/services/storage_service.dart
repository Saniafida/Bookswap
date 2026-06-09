import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Handles all Supabase Storage interactions for BookSwap.
class StorageService {
  StorageService._();

  static const String _bucket = 'book_covers';

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Uploads a single image [bytes] to [filePath] in the book_covers bucket.
  /// Returns the public URL on success, or throws on failure.
  static Future<String> uploadImage(
    Uint8List bytes,
    String filePath,
    String mimeType,
  ) async {
    await SupabaseService.storage.from(_bucket).uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );

    return SupabaseService.storage.from(_bucket).getPublicUrl(filePath);
  }

  /// Uploads multiple images and returns a list of their public URLs.
  /// Skips any image that fails to upload (logs to console).
  /// The first URL in the returned list corresponds to [imageFiles][0].
  static Future<List<String>> uploadMultipleImages(
    List<({Uint8List bytes, String name})> imageFiles,
    String userId,
  ) async {
    final urls = <String>[];

    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      try {
        final ext = _extension(file.name);
        final mime = _mimeType(ext);
        final unique =
            '${DateTime.now().millisecondsSinceEpoch}_${i}_${file.name}';
        final path = '$userId/$unique';
        final url = await uploadImage(file.bytes, path, mime);
        urls.add(url);
      } catch (e) {
        debugPrint('[StorageService] Failed to upload image ${file.name}: $e');
        rethrow;
      }
    }

    return urls;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Deletes a file from the bucket given its [publicUrl].
  /// Silently ignores failures (the file may already be gone).
  static Future<void> deleteImageByUrl(String publicUrl) async {
    try {
      // Extract path relative to the bucket from the full URL
      final uri = Uri.parse(publicUrl);
      // Path is everything after /storage/v1/object/public/<bucket>/
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf(_bucket);
      if (bucketIdx == -1 || bucketIdx + 1 >= segments.length) return;
      final filePath =
          segments.sublist(bucketIdx + 1).join('/');
      await SupabaseService.storage.from(_bucket).remove([filePath]);
    } catch (e) {
      debugPrint('[StorageService] Failed to delete image: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _extension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'jpg';
  }

  static String _mimeType(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
