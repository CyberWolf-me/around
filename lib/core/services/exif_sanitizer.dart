import 'dart:typed_data';

/// Pure-Dart utility for stripping EXIF camera & GPS metadata tags from raw image bytes (P8-02).
/// Enforces dual-layer privacy before image bytes are transmitted to Supabase Storage.
class ExifSanitizer {
  /// Strips raw EXIF metadata (specifically GPS coordinates and camera tags)
  /// from raw image bytes prior to transmission to cloud storage (P8-02).
  ///
  /// Supports:
  /// - JPEG: strips APP1 (0xFFE1) segments containing EXIF/GPS.
  /// - WebP: strips EXIF chunks from RIFF structure.
  /// - PNG: strips eXIf chunks.
  static Uint8List stripExif(Uint8List bytes) {
    if (bytes.length < 4) return bytes;

    // 1. JPEG Detection: 0xFF 0xD8
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return _stripJpegExif(bytes);
    }

    // 2. WebP Detection: "RIFF" .... "WEBP"
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return _stripWebpExif(bytes);
    }

    // 3. PNG Detection: \x89PNG\r\n\x1a\n
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
        bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A) {
      return _stripPngExif(bytes);
    }

    return bytes;
  }

  /// Strips APP1 (0xFFE1) markers from JPEG while keeping image payload intact.
  static Uint8List _stripJpegExif(Uint8List bytes) {
    final builder = BytesBuilder();
    // Write SOI (Start of Image)
    builder.add([0xFF, 0xD8]);

    int offset = 2;
    bool hasExifStripped = false;

    while (offset < bytes.length) {
      if (bytes[offset] != 0xFF) {
        // Unexpected format, copy remaining bytes safely
        builder.add(bytes.sublist(offset));
        break;
      }

      final marker = bytes[offset + 1];

      // End of Image marker
      if (marker == 0xD9) {
        builder.add([0xFF, 0xD9]);
        break;
      }

      // Standalone markers without length: RST0-RST7 (0xD0-0xD7), SOI (0xD8), TEM (0x01)
      if ((marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
        builder.add([0xFF, marker]);
        offset += 2;
        continue;
      }

      // Markers with payload length: read 2-byte length
      if (offset + 4 > bytes.length) {
        builder.add(bytes.sublist(offset));
        break;
      }

      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];

      // Marker 0xE1 is APP1 (EXIF / GPS / XMP)
      if (marker == 0xE1) {
        hasExifStripped = true;
        // Skip APP1 EXIF segment entirely!
        offset += 2 + length;
        continue;
      }

      // Marker 0xDA is SOS (Start of Scan) - rest of the file is entropy-coded scan data
      if (marker == 0xDA) {
        builder.add(bytes.sublist(offset));
        break;
      }

      // Retain all other valid JPEG markers (SOF0, DQT, DHT, APP0 JFIF, etc.)
      final end = offset + 2 + length;
      if (end <= bytes.length) {
        builder.add(bytes.sublist(offset, end));
        offset = end;
      } else {
        builder.add(bytes.sublist(offset));
        break;
      }
    }

    return hasExifStripped ? builder.toBytes() : bytes;
  }

  /// Strips 'EXIF' chunk from WebP RIFF file
  static Uint8List _stripWebpExif(Uint8List bytes) {
    if (bytes.length < 12) return bytes;

    final builder = BytesBuilder();
    // Copy RIFF header placeholder (will fix size at the end)
    builder.add(bytes.sublist(0, 12));

    int offset = 12;
    bool hasExifStripped = false;

    while (offset + 8 <= bytes.length) {
      final chunkFourCC = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = bytes[offset + 4] |
          (bytes[offset + 5] << 8) |
          (bytes[offset + 6] << 16) |
          (bytes[offset + 7] << 24);

      final paddedSize = chunkSize + (chunkSize % 2); // WebP chunks are 2-byte aligned

      if (chunkFourCC == 'EXIF') {
        hasExifStripped = true;
        offset += 8 + paddedSize;
        continue;
      }

      final end = offset + 8 + paddedSize;
      if (end <= bytes.length) {
        builder.add(bytes.sublist(offset, end));
        offset = end;
      } else {
        builder.add(bytes.sublist(offset));
        break;
      }
    }

    if (!hasExifStripped) return bytes;

    final result = builder.toBytes();
    // Update RIFF file size in header (total size - 8)
    final newFileSize = result.length - 8;
    result[4] = newFileSize & 0xFF;
    result[5] = (newFileSize >> 8) & 0xFF;
    result[6] = (newFileSize >> 16) & 0xFF;
    result[7] = (newFileSize >> 24) & 0xFF;
    return result;
  }

  /// Strips 'eXIf' chunk from PNG file
  static Uint8List _stripPngExif(Uint8List bytes) {
    if (bytes.length < 8) return bytes;

    final builder = BytesBuilder();
    builder.add(bytes.sublist(0, 8)); // PNG header

    int offset = 8;
    bool hasExifStripped = false;

    while (offset + 12 <= bytes.length) {
      final length = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      final chunkType = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));

      if (chunkType == 'eXIf') {
        hasExifStripped = true;
        offset += 12 + length; // 4 (len) + 4 (type) + length + 4 (crc)
        continue;
      }

      final end = offset + 12 + length;
      if (end <= bytes.length) {
        builder.add(bytes.sublist(offset, end));
        offset = end;
      } else {
        builder.add(bytes.sublist(offset));
        break;
      }
    }

    return hasExifStripped ? builder.toBytes() : bytes;
  }

  /// Inspects if raw JPEG or WebP bytes contain EXIF GPS markers
  static bool hasExifGps(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // Check JPEG APP1
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      int offset = 2;
      while (offset + 4 <= bytes.length) {
        if (bytes[offset] != 0xFF) break;
        final marker = bytes[offset + 1];
        if (marker == 0xDA || marker == 0xD9) break;
        if ((marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
          offset += 2;
          continue;
        }
        final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
        if (marker == 0xE1) {
          return true; // APP1 EXIF segment present
        }
        offset += 2 + length;
      }
    }

    // Check WebP EXIF chunk
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      int offset = 12;
      while (offset + 8 <= bytes.length) {
        final chunkFourCC = String.fromCharCodes(bytes.sublist(offset, offset + 4));
        if (chunkFourCC == 'EXIF') return true;
        final chunkSize = bytes[offset + 4] |
            (bytes[offset + 5] << 8) |
            (bytes[offset + 6] << 16) |
            (bytes[offset + 7] << 24);
        offset += 8 + chunkSize + (chunkSize % 2);
      }
    }

    return false;
  }
}
