import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gallery_saver/flutter_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Save image to gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _requestPermission();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Save image to gallery"),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.red,
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: RaisedButton(
                  onPressed: _saveScreen,
                  child: Text("Save Local Image"),
                ),
                width: 200,
                height: 44,
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: RaisedButton(
                  onPressed: _getHttp,
                  child: Text("Save network image"),
                ),
                width: 200,
                height: 44,
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: RaisedButton(
                  onPressed: _saveVideo,
                  child: Text("Save network video"),
                ),
                width: 200,
                height: 44,
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: RaisedButton(
                  onPressed: _saveGif,
                  child: Text("Save Gif to gallery"),
                ),
                width: 200,
                height: 44,
              ),
            ],
          ),
        ));
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
    _toastInfo(info);
  }

  _saveScreen() async {
    RenderRepaintBoundary boundary =
    _globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final result =
    await FlutterGallerySaver.saveImage(byteData.buffer.asUint8List());
    print(result);
    _toastInfo(result.toString());
  }

  _getHttp() async {
    var response = await Dio().get(
        "https://ss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=a62e824376d98d1069d40a31113eb807/838ba61ea8d3fd1fc9c7b6853a4e251f94ca5f46.jpg",
        options: Options(responseType: ResponseType.bytes));
    final result = await FlutterGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        albumName: "hello");
    print(result);
    _toastInfo("$result");
  }

  _saveGif() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/temp.gif";
    String fileUrl =
        "https://hyjdoc.oss-cn-beijing.aliyuncs.com/hyj-doc-flutter-demo-run.gif";
    await Dio().download(fileUrl, savePath);
    print("gif下载完成");
    final result = await FlutterGallerySaver.saveFile(savePath);
    print(result);
    _toastInfo("$result");
  }

  _saveVideo() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/temp.mp4";
    String fileUrl =
        "https://txmov2.a.yximgs.com/upic/2020/09/06/09/BMjAyMDA5MDYwOTQ1MzZfMTQ4NDI1ODY0XzM1NTk2NTg3NTcyXzFfMw==_b_B3580181bdf842990debc043eb9b5d0bd.mp4?clientCacheKey=3x3a54h46ppw6r9_b.mp4";
    await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) {
      print((count / total * 100).toStringAsFixed(0) + "%");
    });
    final result = await FlutterGallerySaver.saveFile(savePath);
    print(result);
    _toastInfo("$result");
  }

  _toastInfo(String info) {
    Fluttertoast.showToast(msg: info, toastLength: Toast.LENGTH_LONG);
  }
}
