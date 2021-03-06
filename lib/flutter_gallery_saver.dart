
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class FlutterGallerySaver {
  static const MethodChannel _channel =
      const MethodChannel('kaige.com/gallery_saver');
  /// save image to Gallery
  /// imageBytes can't null
  static Future saveImage(Uint8List imageBytes, {int quality = 80, String albumName}) async {
    assert(imageBytes != null);
    final result =
    await _channel.invokeMethod('saveImageToGallery', <String, dynamic> {
      'imageBytes': imageBytes,
      'quality': quality,
      'albumName': albumName
    });
    return result;
  }

  /// Save the PNG，JPG，JPEG image or video located at [file] to the local device media gallery.
  static Future saveFile(String filePath, {String albumName}) async {
    assert(filePath != null);
    final result =
    await _channel.invokeMethod('saveFileToGallery',  <String, dynamic> {
      'filePath': filePath,
      'albumName': albumName
    });
    return result;
  }
}
