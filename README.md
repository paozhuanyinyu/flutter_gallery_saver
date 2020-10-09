# flutter_gallery_saver

We use the `image_picker` plugin to select images from the Android and iOS image library, but it can't save images to the gallery. This plugin can provide this feature.

## Usage

To use this plugin, add `image_gallery_saver` as a dependency in your pubspec.yaml file. For example:
```yaml
dependencies:
  image_gallery_saver: '^0.0.1'
```

## iOS
Your project need create with swift.
Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist:
 * NSPhotoLibraryAddUsageDescription - describe why your app needs permission for the photo library. This is called Privacy - Photo Library Additions Usage Description in the visual editor
 * NSPhotoLibraryUsageDescription - describe why your app needs permission for the photo library. This is called Privacy - Photo Library Usage Description in the visual editor

 ##  Android
 You need to ask for storage permission to save an image to the gallery. You can handle the storage permission using [flutter_permission_handler](https://github.com/BaseflowIT/flutter-permission-handler).

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
           name: "hello");
   print(result);
  }
```

Saving file(ig: video/gif/others) from the internet
``` dart
_saveVideo() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/temp.mp4";
    await Dio().download("http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4", savePath);
    final result = await FlutterGallerySaver.saveFile(savePath);
    print(result);
 }
```

