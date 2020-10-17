# flutter_gallery_saver

We use the `image_picker` plugin to select images from the Android and iOS image library, but it can't save images to the gallery. This plugin can provide this feature.

## Usage

To use this plugin, add `flutter_gallery_saver` as a dependency in your pubspec.yaml file. For example:
```yaml
dependencies:
  flutter_gallery_saver: '^0.0.7'
```

## iOS
Your project need create with swift.
Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist:
 * NSPhotoLibraryAddUsageDescription - describe why your app needs permission for the photo library. This is called Privacy - Photo Library Additions Usage Description in the visual editor
 * NSPhotoLibraryUsageDescription - describe why your app needs permission for the photo library. This is called Privacy - Photo Library Usage Description in the visual editor

 ##  Android
 You need to ask for storage permission to save an image to the gallery. You can handle the storage permission using [flutter_permission_handler](https://github.com/BaseflowIT/flutter-permission-handler).
 
 If you target Android 10 (API level 29) or higher, set the value of requestLegacyExternalStorage to true in your app's manifest file:
 ```
 <manifest ... >
<!-- This attribute is "false" by default on apps targeting
     Android 10 or higher. -->
  <application android:requestLegacyExternalStorage="true" ... >
    ...
  </application>
</manifest>
 ```
 see [document](https://developer.android.com/training/data-storage/use-cases#opt-out-scoped-storage)

## Example
Saving an image from the internet, quality and name is option
``` dart
_save() async {
   var response = await Dio().get(
        "https://ss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=a62e824376d98d1069d40a31113eb807/838ba61ea8d3fd1fc9c7b6853a4e251f94ca5f46.jpg",
        options: Options(responseType: ResponseType.bytes));
    final result = await FlutterGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        albumName: "hello");
    print("saveImage result: " + result);//这个result文件存储地址
    Fluttertoast.showToast(msg: result, toastLength: Toast.LENGTH_LONG);
  }
```

Saving file(ig: video/gif/others) from the internet
``` dart
_saveVideo() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/temp.mp4";
    String fileUrl =
        "https://txmov2.a.yximgs.com/upic/2020/09/06/09/BMjAyMDA5MDYwOTQ1MzZfMTQ4NDI1ODY0XzM1NTk2NTg3NTcyXzFfMw==_b_B3580181bdf842990debc043eb9b5d0bd.mp4?clientCacheKey=3x3a54h46ppw6r9_b.mp4";
    await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) {
      print((count / total * 100).toStringAsFixed(0) + "%");
    });
    final result = await FlutterGallerySaver.saveFile(savePath);
    print("saveFile result: " + result);//这个result是文件存储地址
    Fluttertoast.showToast(msg: result, toastLength: Toast.LENGTH_LONG);
 }
```

