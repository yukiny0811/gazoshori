//
//  ProcessableGraphics.swift
//  YuruImageProcessor
//
//  Created by クワシマ・ユウキ on 2021/01/21.
//

import MetalKit
import CoreGraphics
import simd

public class ProcessableGraphics {
    
    private var data: PixelRGBA?
    
    private var device: MTLDevice!
    private var library: MTLLibrary!
    private var commandQueue: MTLCommandQueue!
    private var computePipelineState: MTLComputePipelineState!
    
    public init(_ image: CGImage, device: MTLDevice, library: MTLLibrary) {
        self.data = self.getPixelDataRGBA(image)
        
//        device = MTLCreateSystemDefaultDevice()!
        self.device = device
        
//        self.library = self.device.makeDefaultLibrary()
        self.library = library
        commandQueue = self.device.makeCommandQueue()!
    }
    
    private func startGPU() -> PixelRaw {
        
        let inputData = self.createRawFromColorRGBA(self.data!).pixelData
        var outputData = [UInt8](repeating: 0, count: inputData.count)
        
        let function = library.makeFunction(name: "test_function")!
        computePipelineState = try! device.makeComputePipelineState(function: function)

        let start = Date().timeIntervalSince1970

        // (5) 入力バッファと出力バッファの生成
        let inputBuffer = device.makeBuffer(bytes: inputData, length: MemoryLayout<UInt8>.stride * inputData.count, options: [])
        let outputBuffer = device.makeBuffer(bytes: outputData, length: MemoryLayout<UInt8>.stride * outputData.count, options: [])

        // (6) MTLCommandBufferの生成
        let commandBuffer = commandQueue.makeCommandBuffer()!

        // (7) MTLComputeCommandEncoderの生成
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        computeCommandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)

        // (8) スレッドグループ数、スレッドの数の設定
        let width = computePipelineState.threadExecutionWidth
        let threadgroupsPerGrid = MTLSize(width: (outputData.count + width - 1) / width, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: width, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        // (9) エンコードの終了
        computeCommandEncoder.endEncoding()

        // (10) コマンドバッファを実行
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // (11) 結果の取得
        let resultData = Data(bytesNoCopy: outputBuffer!.contents(), count: MemoryLayout<UInt8>.stride * outputData.count, deallocator: .none)
        outputData = resultData.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: UInt8.self ), count: $0.count / MemoryLayout<UInt8>.size)) }

        let end = Date().timeIntervalSince1970
        print("GPU || outputData.first: \(outputData.first ?? 0), outputData.last: \(outputData.last ?? 0), time: " + String(format: "%.5f ms", (end - start) * 1000))
        
        return (outputData, self.data![0].count, self.data!.count)
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
    
    private func getPixelDataRGBAFromRaw(_ rawPixelData: PixelRaw?) -> PixelRGBA? {
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
    
    // process functions
    
    @discardableResult
    public func RGBtoBGR() -> ProcessableGraphics? {
//        var processedColorData = self.data!
//        for y in 0..<self.data!.count {
//            for x in 0..<self.data![y].count {
//                processedColorData[y][x].r = self.data![y][x].b
//                processedColorData[y][x].b = self.data![y][x].r
//            }
//        }
//        self.data = processedColorData
        
        let rawData = startGPU()
        self.data = self.getPixelDataRGBAFromRaw(rawData)
        return self
    }
}

typealias PG_PIXEL_RGBA = SIMD4<UInt8>
typealias PG = <#type expression#>
