//
//  PixelProcessor.swift
//  YuruImageProcessor
//
//  Created by クワシマ・ユウキ on 2021/01/21.
//

import CoreGraphics

public class Processable {
    
    private var data: PixelRGBA?
    
    public init(_ image: CGImage) {
        self.data = self.getPixelDataRGBA(image)
    }
    
    private func getPixelDataRaw(_ image: CGImage) -> PixelRaw? {
        let totalBytes = image.height * image.width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        let context = CGContext(data: &pixelData, width: image.width, height: image.height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        return (pixelData, image.width, image.height)
    }
    
    private func getPixelDataRGBA(_ image: CGImage) -> PixelRGBA? {
        let rawPixelData = getPixelDataRaw(image)
        var processedPixelData: PixelRGBA = []
        for y in 0..<rawPixelData!.height{
            var processedPixelDataRow: [(UInt8, UInt8, UInt8, UInt8)] = []
            for x in 0..<rawPixelData!.width{
                var onePixelData: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)
                onePixelData.0 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4])!
                onePixelData.1 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4 + 1])!
                onePixelData.2 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4 + 2])!
                onePixelData.3 = (rawPixelData?.pixelData[y * rawPixelData!.width * 4 + x * 4 + 3])!
                processedPixelDataRow.append(onePixelData)
            }
            processedPixelData.append(processedPixelDataRow)
        }
        return processedPixelData
    }
    
    private func createRawFromColorRGBA(_ colorData: PixelRGBA) -> PixelRaw {
        var rawPixelData: [UInt8] = []
        for y in colorData{
            for x in y{
                rawPixelData.append(x.r)
                rawPixelData.append(x.g)
                rawPixelData.append(x.b)
                rawPixelData.append(x.a)
            }
        }
        return (rawPixelData, colorData[0].count, colorData.count)
    }
    
    private func createImageFromRGBA(_ colorData: PixelRaw) -> CGImage? {
        let releaseData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> Void in
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let image = CGDataProvider(dataInfo: nil, data: colorData.pixelData, size: colorData.pixelData.count){ _, _, _ in }.flatMap {
            CGImage(width: colorData.width, height: colorData.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: colorData.width * 4, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: $0, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        }
        return image
    }
    
    public func getImage() -> CGImage {
        let rawData = self.createRawFromColorRGBA(self.data!)
        let image = self.createImageFromRGBA(rawData)
        return image!
    }
    
    // main process filters
    
    /// Channel Change
    @discardableResult
    public func RGBtoBGR() -> Processable? {
        var processedColorData = self.data!
        for y in 0..<self.data!.count {
            for x in 0..<self.data![y].count {
                processedColorData[y][x].r = self.data![y][x].b
                processedColorData[y][x].b = self.data![y][x].r
            }
        }
        self.data = processedColorData
        return self
    }
    
    
    /// Gray Scale
    ///
    /// grayscale = r * 0.2126 + g * 0.7152 + b * 0.0722
    @discardableResult
    public func GrayScale() -> Processable? {
        for y in 0..<self.data!.count {
            for x in 0..<self.data![y].count {
                let grayValueDouble = Double(self.data![y][x].r) * 0.2126 + Double(self.data![y][x].g) * 0.7152 + Double(self.data![y][x].b) * 0.0722
                let grayValue: UInt8 = UInt8(grayValueDouble.rounded())
                self.data![y][x] = (grayValue, grayValue, grayValue, grayValue)
            }
        }
        return self
    }
    
    /// Binarization
    ///
    /// 二値化
    @discardableResult
    public func Binarize(threshold: Int) -> Processable? {
        self.GrayScale()
        for y in 0..<self.data!.count {
            for x in 0..<self.data![y].count {
                if self.data![y][x].r < threshold {
                    self.data![y][x] = (0, 0, 0, 0)
                } else {
                    self.data![y][x] = (255, 255, 255, 255)
                }
            }
        }
        return self
    }
    
    /// Otsu Binarization
    ///
    /// 大津の二値化
    /// P_all : 全体の画素数
    /// P_0 : クラス0に含まれる画素数
    /// P_1 : クラス1に含まれる画素数
    /// R_0 : 全体におけるクラス0の割合
    /// R_1 : 全体におけるクラス1の割合
    ///
    /// R_0 = P_0/P_all
    /// R_1 = P_1/P_all
    ///
    /// M_all : 全ての画素の輝度の平均
    /// M_0 : クラス0内の画素の輝度の平均
    /// M_1 : クラス1内の画素の輝度の平均
    /// S_b^2 : クラス0とクラス1の離れ具合であるクラス間分散
    ///
    /// S_b^2 = R_0 * (M_0 - M_all)^2 + R_1 * (M_1 - M_all)^2
    ///       = R_0 * R_1 * (M_0 - M_1)^2
    ///
    /// S_0^2 : クラス0内の分散
    /// S_1^2 : クラス1内の分散
    /// S_in^2 : 各クラスごとの分散を総合的に評価したクラス内分散
    ///
    /// S_in^2 = R_0 * S_0^2 + R_1 * S_1^2
    ///
    /// より好ましい条件は、
    /// 1. クラス0とクラス1がより離れている
    /// 2. クラス毎にまとまっていたほうがよい
    ///
    /// 条件1 : クラス間分散S_b^2が大きければ満たせる
    /// 条件2 : クラス内分散S_in^2が小さければ満たせる
    ///
    /// よって、S_b^2 / S_in^2 が大きくなるほど良い閾値
    ///
    /// S_all : 全体の分散（定数）
    ///
    /// S_all = S_b^2 + S_in^2
    ///
    /// よって、S_in^2 = S_all - S_b^2
    ///
    /// よって、S_b^2/S_in^2 = S_b^2/(S_all - S_b^2)
    ///
    /// よって、S_b^2を大きくすればOK
    ///
    /// よって、最適な閾値tは、S_b^2 が最も大きくなるようなものである。
    ///
    /// 0~255の全ての閾値を選び、最も大きくなるものを閾値として選択する
    @discardableResult
    public func OtsuBinarize() -> Processable? {
        self.GrayScale()
        
        var currentMaxSb2: Double = 0
        var currentT = 0
        
        for t in 0...255 {
            let pAll: Double = Double(self.data!.count * self.data![0].count)
            var p0: Double = 0
            var p1: Double = 0
            var sum0: Double = 0
            var sum1: Double = 0
            for y in 0..<self.data!.count {
                for x in 0..<self.data![y].count {
                    if self.data![y][x].r < t {
                        p0 += 1
                        sum0 += Double(self.data![y][x].r)
                    } else {
                        p1 += 1
                        sum1 += Double(self.data![y][x].r)
                    }
                }
            }
            let r0: Double = p0 / pAll
            let r1: Double = p1 / pAll
            let m0: Double = sum0 / p0
            let m1: Double = sum1 / p1

            let sb2: Double = r0 * r1 * (m0 - m1).power(2)

            if sb2 > currentMaxSb2 {
                currentMaxSb2 = sb2
                currentT = t
            }
        }
        self.Binarize(threshold: currentT)
        return self
    }
    
    /// optimized version of Otsu Binarization
    @discardableResult
    public func OtsuBinarizeOptimized() -> Processable? {
        self.GrayScale()
        
        var currentMaxSb2: Double = 0
        var currentT = 0
        
        let tempData = self.data!.flatMap {
            $0.map {
                $0.r
            }
        }.sorted()
        
        let sumAll: Double = Double(tempData.reduce(0) { Int($0) + Int($1) })
        let pAll: Double = Double(tempData.count)
    
        var saveN = 0
        var sum0 = 0
        
        for t in 0...255 {
            var p0 = 0
            var p1: Double = 0
            
            for n in saveN..<tempData.count {
                if tempData[n] >= t {
                    p0 = n
                    saveN = n
                    break
                } else {
                    sum0 += Int(tempData[n])
                }
            }
            let sum1 = sumAll - Double(sum0)
            p1 = pAll - Double(p0)

            let r0: Double = Double(p0) / pAll
            let r1: Double = Double(p1) / pAll
            let m0: Double = Double(sum0) / Double(p0)
            let m1: Double = sum1 / p1

            let sb2: Double = r0 * r1 * (m0 - m1).power(2)

            if sb2 > currentMaxSb2 {
                currentMaxSb2 = sb2
                currentT = t
            }
        }
        self.Binarize(threshold: currentT)
        return self
    }
    
    @discardableResult
    public func RGBtoHSV() -> Processable? {
        self.data = self.data!.map {
            $0.map {
                let max = Int([$0.r, $0.g, $0.b].max()!)
                let min = Int([$0.r, $0.g, $0.b].min()!)
                var hue: Int = 0
                let tempR = Int($0.r)
                let tempG = Int($0.g)
                let tempB = Int($0.b)
                if max == min {
                    hue = 0
                } else if max == tempR {
                    hue = Int(60 * (Double(tempG - tempB) / Double(max - min)))
                } else if max == $0.g {
                    hue = Int(60 * (Double(tempB - tempR) / Double(max - min))) + 120
                } else if max == $0.b {
                    hue = Int(60 * (Double(tempR - tempG) / Double(max - min))) + 240
                }
                if hue < 0 {
                    hue += 360
                }
                
                return (r: UInt8(Double(hue) * 255 / 360), g: UInt8(Double(max - min) / Double(max) * 255), b: UInt8(max), a: $0.a)
            }
        }
        return self
    }
    
    @discardableResult
    public func HSVtoRGB() -> Processable? {
        self.data = self.data!.map {
            $0.map {
                let hue = Int(Double($0.r) * 360.0 / 255.0)
                let max: Int = Int($0.b)
                let min: Double = Double(max) - Double($0.g) / 255.0 * Double(max)
                var tempR = 0
                var tempG = 0
                var tempB = 0
                if hue <= 60 {
                    tempR = max
                    tempG = Int(Double(hue) / 60 * (Double(max) - min)) + Int(min)
                    tempB = Int(min)
                } else if hue <= 120 {
                    tempR = Int(Double(120 - Int(hue)) / 60.0 * (Double(max) - min) + min)
                    tempG = max
                    tempB = Int(min)
                } else if hue <= 180 {
                    tempR = Int(min)
                    tempG = max
                    tempB = Int(Double(Int(hue) - 120) / 60.0 * (Double(max) - min)) + Int(min)
                } else if hue <= 240 {
                    tempR = Int(min)
                    tempG = Int(Double(240 - Int(hue)) / 60 * (Double(max) - min)) + Int(min)
                    tempB = max
                } else if hue <= 300 {
                    tempR = Int(Double(240 - Int(hue)) / 60 * (Double(max) - min)) + Int(min)
                    tempG = Int(min)
                    tempB = max
                } else if hue <= 360 {
                    tempR = max
                    tempG = Int(min)
                    tempB = Int(Double(360 - Int(hue)) / 60 * (Double(max) - min)) + Int(min)
                }
                return (UInt8(tempR), UInt8(tempG), UInt8(tempB), $0.a)
            }
        }
        return self
    }
    
    @discardableResult
    public func ColorSubtract(division: Int) -> Processable? {
        var divided: [Int] = []
        for i in 0..<division {
            divided.append(Int(Double(i) * 255 / Double(division)))
        }
        divided.append(255)
        var tempRGB: [UInt8] = []
        self.data = self.data!.map {
            $0.map {
                
                tempRGB = [$0.r,$0.g,$0.b]
                for i in 0..<tempRGB.count {
                    for j in 1..<divided.count {
                        if tempRGB[i] <= divided[j] {
                            tempRGB[i] = UInt8(divided[j-1])
                            break
                        }
                    }
                }
                
                return (tempRGB[0], tempRGB[1], tempRGB[2], $0.a)
            }
        }
        return self
    }
    
    @discardableResult
    public func AveragePooling(rectSize: Int) -> Processable? {
        for y in stride(from: 0, to: self.data!.count - rectSize, by: rectSize) {
            for x in stride(from: 0, to: self.data![y].count - rectSize, by: rectSize) {
                var rgb: (Int, Int, Int) = (0, 0, 0)
                for smally in y..<y+rectSize {
                    for smallx in x..<x+rectSize {
                        rgb.0 += Int(self.data![smally][smallx].r)
                        rgb.1 += Int(self.data![smally][smallx].g)
                        rgb.2 += Int(self.data![smally][smallx].b)
                    }
                }
                rgb.0 = rgb.0 / (rectSize * rectSize)
                rgb.1 = rgb.1 / (rectSize * rectSize)
                rgb.2 = rgb.2 / (rectSize * rectSize)
                for smally in y..<y+rectSize {
                    for smallx in x..<x+rectSize {
                        self.data![smally][smallx] = (UInt8(rgb.0), UInt8(rgb.1), UInt8(rgb.2), self.data![smally][smallx].a)
                    }
                }
            }
        }
        return self
    }
    
    @discardableResult
    public func MaxPooling(rectSize: Int) -> Processable? {
        for y in stride(from: 0, to: self.data!.count - rectSize, by: rectSize) {
            for x in stride(from: 0, to: self.data![y].count - rectSize, by: rectSize) {
                var rgbMax: (UInt8, UInt8, UInt8) = (0, 0, 0)
                for smally in y..<y+rectSize {
                    for smallx in x..<x+rectSize {
                        if self.data![smally][smallx].r > rgbMax.0 {
                            rgbMax.0 = self.data![smally][smallx].r
                        } else if self.data![smally][smallx].g > rgbMax.1 {
                            rgbMax.1 = self.data![smally][smallx].g
                        } else if self.data![smally][smallx].b > rgbMax.2 {
                            rgbMax.2 = self.data![smally][smallx].b
                        }
                    }
                }
                for smally in y..<y+rectSize {
                    for smallx in x..<x+rectSize {
                        self.data![smally][smallx] = (rgbMax.0, rgbMax.1, rgbMax.2, self.data![smally][smallx].a)
                    }
                }
            }
        }
        return self
    }
    
    @discardableResult
    public func MedianFilter(rectSize: Int) -> Processable? {
        for y in stride(from: 0, to: self.data!.count - rectSize, by: rectSize) {
            for x in stride(from: 0, to: self.data![y].count - rectSize, by: rectSize) {
                var rgbMax: (UInt8, UInt8, UInt8) = (0, 0, 0)
                for smally in y..<y+rectSize {
                    for smallx in x..<x+rectSize {
                        if self.data![smally][smallx].r > rgbMax.0 {
                            rgbMax.0 = self.data![smally][smallx].r
                        } else if self.data![smally][smallx].g > rgbMax.1 {
                            rgbMax.1 = self.data![smally][smallx].g
                        } else if self.data![smally][smallx].b > rgbMax.2 {
                            rgbMax.2 = self.data![smally][smallx].b
                        }
                    }
                }
                for smally in y..<y+rectSize {
                    for smallx in x..<x+rectSize {
                        self.data![smally][smallx] = (rgbMax.0, rgbMax.1, rgbMax.2, self.data![smally][smallx].a)
                    }
                }
            }
        }
        return self
    }
}

extension Double {
    func power(_ num: Double) -> Double {
        return pow(self, num)
    }
}

public typealias PixelRGBA = [[(r: UInt8, g: UInt8, b: UInt8, a: UInt8)]]
public typealias PixelRaw = (pixelData: [UInt8], width: Int, height: Int)

//public struct ProcessableObject<Base> {
//    let base: Base
//    init(_ base: Base) {
//        self.base = base
//    }
//}
//
//public protocol ProcessableProtocol {
//    associatedtype Processable
//    var process: ProcessableObject<Processable> { get }
//}
//
//extension ProcessableProtocol {
//    public var process: ProcessableObject<Self> {
//        return ProcessableObject(self)
//    }
//}
