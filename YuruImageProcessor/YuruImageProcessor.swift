//
//  YuruImage.swift
//  YuruImageProcessor
//
//  Created by クワシマ・ユウキ on 2021/01/20.
//
import CoreGraphics

//public struct YuruImageProcessor {
//
//    public static func getRawPixelData(_ image: CGImage) -> ColorRaw? {
//        let totalBytes = image.height * image.width * 4
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        var pixelData = [UInt8](repeating: 0, count: totalBytes)
//        let context = CGContext(data: &pixelData, width: image.width, height: image.height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
//        context?.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
//        print("test")
//        print(pixelData[0])
//        print(pixelData[1])
//        print(pixelData[2])
//        print(pixelData[3])
//        print(pixelData[4])
//        return (pixelData, image.width, image.height)
//    }
//
//    public static func getPixelDataRGBA(_ image: CGImage) -> ColorRGBA? {
//        let rawPixelData = getRawPixelData(image)
//        var processedPixelData: ColorRGBA = []
//        for y in 0..<rawPixelData!.height{
//            var processedPixelDataRow: [(UInt8, UInt8, UInt8, UInt8)] = []
//            for x in 0..<rawPixelData!.width{
//                var onePixelData: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)
//                onePixelData.0 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4])!
//                onePixelData.1 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4 + 1])!
//                onePixelData.2 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4 + 2])!
//                onePixelData.3 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4 + 3])!
//                processedPixelDataRow.append(onePixelData)
//            }
//            processedPixelData.append(processedPixelDataRow)
//        }
//        return processedPixelData
//    }
//
//    public static func RGBAtoBGRA(_ colorData: ColorRGBA) -> ColorRGBA? {
//        var processedColorData = colorData
//        for y in 0..<colorData.count {
//            for x in 0..<colorData[y].count {
//                processedColorData[y][x].r = colorData[y][x].b
//                processedColorData[y][x].b = colorData[y][x].r
//            }
//        }
//        return processedColorData
//    }
//
//    public static func createRawFromColorRGBA(_ colorData: ColorRGBA) -> ColorRaw {
//        var rawPixelData: [UInt8] = []
//        for y in colorData{
//            for x in y{
//                rawPixelData.append(x.r)
//                rawPixelData.append(x.g)
//                rawPixelData.append(x.b)
//                rawPixelData.append(x.a)
//            }
//        }
//        return (rawPixelData, colorData[0].count, colorData.count)
//    }
//    public static func createImageFromRGBA(_ colorData: ColorRaw) -> CGImage? {
//        let releaseData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> Void in
//        }
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
////        let image = CGImage(width: colorData.width, height: colorData.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: colorData.width * 4, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: CGDataProvider(dataInfo: nil, data: colorData.pixelData, size: colorData.pixelData.count, releaseData: releaseData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
//        let image = CGDataProvider(dataInfo: nil, data: colorData.pixelData, size: colorData.pixelData.count){ _, _, _ in }.flatMap {
//            CGImage(width: colorData.width, height: colorData.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: colorData.width * 4, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: $0, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
//        }
//        return image
//    }
//}

//public typealias ColorRGBA = [[(r: UInt8, g: UInt8, b: UInt8, a: UInt8)]]
//public typealias ColorRaw = (pixelData: [UInt8], width: Int, height: Int)

