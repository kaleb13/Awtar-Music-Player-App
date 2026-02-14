import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ImageProcessingService {
  // Constants for standard optimization
  static const int standardMaxSize = 1024;
  static const int standardTargetSize = 200 * 1024; // 200 KB
  static const int qualityStart = 80;
  static const int qualityMin = 60;
  static const int dimensionFloor = 512;

  /// Processes a picked image according to the adaptive pipeline:
  /// 1. Square crop (center-focus)
  /// 2. Initial resize to [maxSize]
  /// 3. Adaptive compression loop to reach [targetSize]
  /// 4. Dimension fallback if compression isn't enough
  static Future<File?> processImage(
    String inputPath, {
    int maxSize = standardMaxSize,
    int targetSize = standardTargetSize,
    bool forceSquare = true,
  }) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        debugPrint("Error: Could not decode image at $inputPath");
        return null;
      }

      img.Image image = decodedImage;

      // 1. Enforce Square Crop
      if (forceSquare && image.width != image.height) {
        int dimension = min(image.width, image.height);
        int x = (image.width - dimension) ~/ 2;
        int y = (image.height - dimension) ~/ 2;
        image = img.copyCrop(
          image,
          x: x,
          y: y,
          width: dimension,
          height: dimension,
        );
      }

      // 2. Initial Dimension Cap
      if (image.width > maxSize || image.height > maxSize) {
        image = img.copyResize(
          image,
          width: maxSize,
          height: maxSize,
          interpolation: img.Interpolation.linear,
        );
      }

      // 3. Adaptive Quality Loop
      int currentQuality = qualityStart;
      Uint8List compressedBytes;

      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String outputPath = '${tempDir.path}/$fileName';

      while (true) {
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: currentQuality),
        );

        // Break if we hit the size target OR we've reached our quality floor
        if (compressedBytes.length <= targetSize ||
            currentQuality <= qualityMin) {
          break;
        }

        currentQuality -= 5;
      }

      // 4. Dimension Fallback if still too large at minimum quality
      if (compressedBytes.length > targetSize) {
        int currentDim = maxSize;
        while (compressedBytes.length > targetSize &&
            currentDim > dimensionFloor) {
          currentDim -= 128;
          image = img.copyResize(image, width: currentDim, height: currentDim);
          compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: qualityMin),
          );
        }
      }

      // 5. Hard Reject check (Extreme case)
      // If it's still > 1MB even after all this, something is likely wrong with the file
      if (compressedBytes.length > 1024 * 1024) {
        debugPrint(
          "Warning: Image still unusually large (${compressedBytes.length} bytes) after optimization",
        );
      }

      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(compressedBytes);

      return outputFile;
    } catch (e) {
      debugPrint("Error in ImageProcessingService.processImage: $e");
      return null;
    }
  }

  /// Helper to get optimized pick options
  static Map<String, dynamic> getPickOptions() {
    return {
      'maxWidth':
          standardMaxSize.toDouble() * 2, // Allow some buffer for cropping
      'maxHeight': standardMaxSize.toDouble() * 2,
      'imageQuality': 85,
    };
  }
}
