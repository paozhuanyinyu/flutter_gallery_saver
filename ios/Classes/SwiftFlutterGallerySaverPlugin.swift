import Flutter
import UIKit
import Photos

public class SwiftFlutterGallerySaverPlugin: NSObject, FlutterPlugin {
  var flutterResult: FlutterResult?
  var localId: String?
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "kaige.com/gallery_saver", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterGallerySaverPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.flutterResult = result
    if call.method == "saveImageToGallery" {
      let arguments = call.arguments as? [String: Any] ?? [String: Any]()
      guard let imageData = (arguments["imageBytes"] as? FlutterStandardTypedData)?.data,
          let image = UIImage(data: imageData),
          let quality = arguments["quality"] as? Int ,
          let albumName = arguments["albumName"]
          else { return }
      let newImage = image.jpegData(compressionQuality: CGFloat(quality / 100))!
        saveImageInAlbum(image: UIImage(data: newImage) ?? image , albumName: albumName as? String ?? getAppName())
    } else if (call.method == "saveFileToGallery") {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        guard let path = arguments["filePath"] as? String,
            let albumName = arguments["albumName"]
            else { return }
        saveFileInAlbum(filePath: path, albumName: albumName as? String ?? getAppName())
    } else if(call.method == "galleryFileExists"){
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        guard let uri = arguments["uri"] as? String
            else { return }
        fileExists(uri: uri)
    }
    else {
      result(FlutterMethodNotImplemented)
    }
  }
  func getAppName() -> String{
    return Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "flutter_gallery_saver"
  }
  func isImageFile(filename: String) -> Bool {
    let imageType = Data.detectImageType(with: filename)
    return imageType != Data.ImageType.unknown
  }
 func fileExists(uri: String){
    let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [uri],options: nil)
    if(assetResult.count == 0){
        var resultDict = [String: Any]()
        resultDict["isExists"] = false
        resultDict["msg"] = uri + " not found"
        resultDict["uri"] = ""
        self.flutterResult?(resultDict)
        return
    }
    let asset = assetResult[0]
    let mediatype = (asset as PHAsset).mediaType
    if(mediatype == PHAssetMediaType.video){
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (asset, mix, nil) in
            let myAsset = asset as? AVURLAsset
            let fileUrl = (myAsset?.url)!.absoluteString
            print("video fileUrl：",fileUrl)
            let filePath = (myAsset?.url)!.path
            print("video filePath：",filePath)
            let fileManager = FileManager.default
            let isExists = fileManager.fileExists(atPath: filePath, isDirectory: nil)
            print("video isExists: ", isExists)
            var resultDict = [String: Any]()
            resultDict["isExists"] = isExists
            resultDict["msg"] = "success"
            resultDict["uri"] = fileUrl
            self.flutterResult?(resultDict)
        })
    }else if(mediatype == PHAssetMediaType.image){
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData)
            -> Bool in
            return true
        }
        //获取保存的图片路径
        asset.requestContentEditingInput(with: options, completionHandler: {
            (contentEditingInput:PHContentEditingInput?, info: [AnyHashable : Any]) in
            let fileUrl = contentEditingInput!.fullSizeImageURL!.absoluteString
            print("image fileUrl：",fileUrl)
            let filePath = contentEditingInput!.fullSizeImageURL!.path
            print("image filePath：",filePath)
            let fileManager = FileManager.default
            let isExists = fileManager.fileExists(atPath: filePath, isDirectory: nil)
            print("isExists: ", isExists)
            var resultDict = [String: Any]()
            resultDict["isExists"] = isExists
            resultDict["msg"] = "success"
            resultDict["uri"] = fileUrl
            self.flutterResult?(resultDict)
        })
    }else{
        var resultDict = [String: Any]()
        resultDict["isExists"] = false
        resultDict["msg"] = "neither image nor video：" +  "\(mediatype.rawValue)"
        resultDict["uri"] = ""
        self.flutterResult?(resultDict)
    }
 }
  //保存图片到相册
  func saveImageInAlbum(image: UIImage, albumName: String = "") {
        var assetAlbum: PHAssetCollection?
        //如果没有传相册的名字，则保存到相机胶卷。（否则保存到指定相册）
        if albumName.isEmpty {
            print("没有传相册的名字")
        }else {
            print("相册：", albumName)
            //看保存的指定相册是否存在
            let list = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            
            list.enumerateObjects({ (album, index, stop) in
                let assetCollection = album
                if albumName == assetCollection.localizedTitle {
                    assetAlbum = assetCollection
                    stop.initialize(to: true)
                }
            })
            //不存在的话则创建该相册
            if assetAlbum == nil {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest
                        .creationRequestForAssetCollection(withTitle: albumName)
                }, completionHandler: { (isSuccess, error) in
                    self.saveImageInAlbum(image: image, albumName: albumName)
                })
                return
            }
        }
        //保存图片
        PHPhotoLibrary.shared().performChanges({
            //添加的相机胶卷
            let result = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = result.placeholderForCreatedAsset
            //保存标志符
            self.localId = assetPlaceholder?.localIdentifier
            //是否要添加到相簿
            if !albumName.isEmpty {
                let albumChangeRequset = PHAssetCollectionChangeRequest(for:
                    assetAlbum!)
                albumChangeRequset!.addAssets([assetPlaceholder!]  as NSArray)
            }
        }) { (isSuccess: Bool, error: Error?) in
            if isSuccess {
                print("保存成功!")
                self.flutterResult?(self.localId)
            } else{
                print("保存失败：",error!.localizedDescription)
                self.flutterResult?("")
            }
        }
    }
    //保存文件到相册
    func saveFileInAlbum(filePath: String, albumName: String = "") {
        var assetAlbum: PHAssetCollection?
        //如果没有传相册的名字，则保存到相机胶卷。（否则保存到指定相册）
        if albumName.isEmpty {
            print("没有传相册的名字")
        }else {
            print("相册：", albumName)
            //看保存的指定相册是否存在
            let list = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            list.enumerateObjects({ (album, index, stop) in
                let assetCollection = album
                if albumName == assetCollection.localizedTitle {
                    assetAlbum = assetCollection
                    stop.initialize(to: true)
                }
            })
            //不存在的话则创建该相册
            if assetAlbum == nil {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest
                        .creationRequestForAssetCollection(withTitle: albumName)
                }, completionHandler: { (isSuccess, error) in
                    self.saveFileInAlbum(filePath: filePath, albumName: albumName)
                })
                return
            }
        }
        //保存图片
        PHPhotoLibrary.shared().performChanges({
            //添加的相机胶卷
            var result: PHAssetChangeRequest? = nil
            if(self.isImageFile(filename: filePath)){
                result = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL (fileURLWithPath: filePath))
            }else{
                result = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL (fileURLWithPath: filePath))
            }
            let assetPlaceholder = result?.placeholderForCreatedAsset
            //保存标志符
            self.localId = assetPlaceholder?.localIdentifier
            //是否要添加到相簿
            if !albumName.isEmpty {
                let albumChangeRequset = PHAssetCollectionChangeRequest(for:
                    assetAlbum!)
                albumChangeRequset!.addAssets([assetPlaceholder!]  as NSArray)
            }
        }) { (isSuccess: Bool, error: Error?) in
            if isSuccess {
                print("保存成功!")
                self.flutterResult?(self.localId)
            } else{
                print("保存失败：",error!.localizedDescription)
                self.flutterResult?("")
            }
        }
    }
}

extension Data {
    enum ImageType {
        case unknown
        case jpeg
        case jpeg2000
        case tiff
        case bmp
        case icns
        case gif
        case png
        case webp
        case heic
        case heif
    }
    
    func detectImageType() -> Data.ImageType {
        if self.count < 16 { return .unknown }
        
        var value = [UInt8](repeating:0, count:1)
        
        self.copyBytes(to: &value, count: 1)
        
        switch value[0] {
        case 0x4D, 0x49:
            return .tiff
        case 0x69:
            return .icns
        case 0x47:
            return .gif
        case 0x89:
            return .png
        case 0xFF:
            return .jpeg
        case 0x42:
            return .bmp
        case 0x52:
            let subData = self.subdata(in: Range(NSMakeRange(0, 12))!)
            if let infoString = String(data: subData, encoding: .ascii) {
                if infoString.hasPrefix("RIFF") && infoString.hasSuffix("WEBP") {
                    return .webp
                }
            }
            break
        case 0x00 where self.count >= 12:
            if let str = String(data: self[8...11], encoding: .ascii) {
                let HEICBitMaps = Set(["heic", "heis", "heix", "hevc", "hevx"])
                if HEICBitMaps.contains(str) {
                    return .heic
                }
                let HEIFBitMaps = Set(["mif1", "msf1"])
                if HEIFBitMaps.contains(str) {
                    return .heif
                }
            }
            break
        default:
            break
        }
        return .unknown
    }
    
    static func detectImageType(with data: Data) -> Data.ImageType {
        return data.detectImageType()
    }
    
    static func detectImageType(with url: URL) -> Data.ImageType {
        if let data = try? Data(contentsOf: url) {
            return data.detectImageType()
        } else {
            return .unknown
        }
    }
    
    static func detectImageType(with filePath: String) -> Data.ImageType {
        let pathUrl = URL(fileURLWithPath: filePath)
        if let data = try? Data(contentsOf: pathUrl) {
            return data.detectImageType()
        } else {
            return .unknown
        }
    }
    
    static func detectImageType(with imageName: String, bundle: Bundle = Bundle.main) -> Data.ImageType? {
        
        guard let path = bundle.path(forResource: imageName, ofType: "") else { return nil }
        let pathUrl = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: pathUrl) {
            return data.detectImageType()
        } else {
            return nil
        }
    }
    
    
}
