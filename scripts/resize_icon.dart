import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/icons/swaply.png');
  final image = img.decodePng(file.readAsBytesSync())!;

  int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a > 0) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < minX || maxY < minY) {
    print('No opaque pixels found');
    return;
  }

  final cropped = img.copyCrop(image, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

  final targetSize = 1024;
  final scale = targetSize / (cropped.width > cropped.height ? cropped.width : cropped.height);
  final newW = (cropped.width * scale).toInt();
  final newH = (cropped.height * scale).toInt();
  final resized = img.copyResize(cropped, width: newW, height: newH);

  final canvas = img.Image(width: targetSize, height: targetSize);
  final dx = (targetSize - newW) ~/ 2;
  final dy = (targetSize - newH) ~/ 2;
  img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

  file.writeAsBytesSync(img.encodePng(canvas));
  print('Icon resized: ${cropped.width}x${cropped.height} -> ${newW}x${newH} centered on ${targetSize}x${targetSize}');
}
