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
    
    private var imageData: PG_IMAGE_DATA!
    
    private var device: MTLDevice!
    private var library: MTLLibrary!
    private var commandQueue: MTLCommandQueue!
    private var computePipelineState: MTLComputePipelineState!
    
    public init(_ image: CGImage, device: MTLDevice, library: MTLLibrary) {
        self.imageData = self.getPixelDataRGBA(image)
        
        self.device = device
        self.library = library
        commandQueue = self.device.makeCommandQueue()!
    }
    
    private func RunGPU(functionName: String) -> PG_IMAGE_DATA {

        let inputData = self.createPixelArrayFromRGBA(self.imageData)
        var outputData = [PG_PIXEL_RGBA](repeating: PG_PIXEL_RGBA(0, 0, 0, 0), count: inputData.count)

        let function = library.makeFunction(name: functionName)!
        computePipelineState = try! device.makeComputePipelineState(function: function)

        let start = Date().timeIntervalSince1970

        let inputBuffer = device.makeBuffer(bytes: inputData, length: MemoryLayout<PG_PIXEL_RGBA>.stride * inputData.count, options: [])
        let outputBuffer = device.makeBuffer(bytes: outputData, length: MemoryLayout<PG_PIXEL_RGBA>.stride * outputData.count, options: [])

        let commandBuffer = commandQueue.makeCommandBuffer()!

        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        computeCommandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)

        let width = computePipelineState.threadExecutionWidth
        let threadgroupsPerGrid = MTLSize(width: (outputData.count + width - 1) / width, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: width, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        computeCommandEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let resultData = Data(bytesNoCopy: outputBuffer!.contents(), count: MemoryLayout<PG_PIXEL_RGBA>.stride * outputData.count, deallocator: .none)
        outputData = resultData.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: PG_PIXEL_RGBA.self ), count: $0.count / MemoryLayout<PG_PIXEL_RGBA>.size)) }

        let end = Date().timeIntervalSince1970
        print("GPU || time: " + String(format: "%.5f ms", (end - start) * 1000))
        
        

        return self.getPixelDataRGBAFromRaw2((outputData, self.imageData[0].count, self.imageData.count))!
    }
    
    private func RunGPUWith1Option(functionName: String, optionData: UInt8) -> PG_IMAGE_DATA {
        let inputData = self.createPixelArrayFromRGBA(self.imageData)
        var outputData = [PG_PIXEL_RGBA](repeating: PG_PIXEL_RGBA(0, 0, 0, 0), count: inputData.count)

        let function = library.makeFunction(name: functionName)!
        computePipelineState = try! device.makeComputePipelineState(function: function)

        let start = Date().timeIntervalSince1970
        
        let optionData: [UInt8] = [optionData]

        let inputBuffer = device.makeBuffer(bytes: inputData, length: MemoryLayout<PG_PIXEL_RGBA>.stride * inputData.count, options: [])
        let outputBuffer = device.makeBuffer(bytes: outputData, length: MemoryLayout<PG_PIXEL_RGBA>.stride * outputData.count, options: [])
        let optionBuffer = device.makeBuffer(bytes: optionData, length: MemoryLayout<[UInt8]>.stride, options: [])

        let commandBuffer = commandQueue.makeCommandBuffer()!

        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        computeCommandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        computeCommandEncoder.setBuffer(optionBuffer, offset: 0, index: 2)

        let width = computePipelineState.threadExecutionWidth
        let threadgroupsPerGrid = MTLSize(width: (outputData.count + width - 1) / width, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: width, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        computeCommandEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let resultData = Data(bytesNoCopy: outputBuffer!.contents(), count: MemoryLayout<PG_PIXEL_RGBA>.stride * outputData.count, deallocator: .none)
        outputData = resultData.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: PG_PIXEL_RGBA.self ), count: $0.count / MemoryLayout<PG_PIXEL_RGBA>.size)) }

        let end = Date().timeIntervalSince1970
        print("GPU || time: " + String(format: "%.5f ms", (end - start) * 1000))
        
        

        return self.getPixelDataRGBAFromRaw2((outputData, self.imageData[0].count, self.imageData.count))!
    }
    
    //done
    private func getPixelDataRawFromImage(_ image: CGImage) -> PG_PIXEL_RAW? {
        let totalBytes = image.height * image.width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        let context = CGContext(data: &pixelData, width: image.width, height: image.height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        return (pixelData, image.width, image.height)
    }
    
    //done
    private func getPixelDataRGBA(_ image: CGImage) -> PG_IMAGE_DATA? {
        let rawPixelData = getPixelDataRawFromImage(image)
        return self.getPixelDataRGBAFromRaw(rawPixelData)
    }
    
    //done
    private func getPixelDataRGBAFromRaw(_ rawPixelData: PG_PIXEL_RAW?) -> PG_IMAGE_DATA? {
        var processedPixelData: PG_IMAGE_DATA = []
        for y in 0..<rawPixelData!.height{
            var processedPixelDataRow: [PG_PIXEL_RGBA] = []
            for x in 0..<rawPixelData!.width{
                var onePixelData: PG_PIXEL_RGBA = PG_PIXEL_RGBA(0, 0, 0, 0)
                let index = y * rawPixelData!.width * 4 + x * 4
                onePixelData.x = (rawPixelData?.pixelRawData[index])!
                onePixelData.y = (rawPixelData?.pixelRawData[index + 1])!
                onePixelData.z = (rawPixelData?.pixelRawData[index + 2])!
                onePixelData.w = (rawPixelData?.pixelRawData[index + 3])!
                processedPixelDataRow.append(onePixelData)
            }
            processedPixelData.append(processedPixelDataRow)
        }
        return processedPixelData
    }
    
    //done
    private func getPixelDataRGBAFromRaw2(_ rawPixelData: (pixelRawData: [PG_PIXEL_RGBA], width: Int, height: Int)? ) -> PG_IMAGE_DATA? {
        var processedPixelData: PG_IMAGE_DATA = []
        for y in 0..<rawPixelData!.height{
            var processedPixelDataRow: [PG_PIXEL_RGBA] = []
            for x in 0..<rawPixelData!.width{
                let index = y * rawPixelData!.width + x
                processedPixelDataRow.append((rawPixelData?.pixelRawData[index])!)
            }
            processedPixelData.append(processedPixelDataRow)
        }
        return processedPixelData
    }
    
    
    //done
    private func createPixelArrayFromRGBA(_ colorData: PG_IMAGE_DATA) -> [PG_PIXEL_RGBA] {
        var rawPixelData: [PG_PIXEL_RGBA] = []
        for y in colorData{
            for x in y{
                var tempPixel: PG_PIXEL_RGBA = PG_PIXEL_RGBA(0, 0, 0, 0)
                tempPixel.x = x.x
                tempPixel.y = x.y
                tempPixel.z = x.z
                tempPixel.w = x.w
                rawPixelData.append(tempPixel)
            }
        }
        return rawPixelData
    }
    
    //done
    private func createImageFromRGBA(_ colorData: PG_IMAGE_DATA) -> CGImage? {
        let rawArray = self.createPixelArrayFromRGBA(colorData)
        var raw_uint8_array: [UInt8] = []
        for r in rawArray {
            raw_uint8_array.append(r.x)
            raw_uint8_array.append(r.y)
            raw_uint8_array.append(r.z)
            raw_uint8_array.append(r.w)
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let image = CGDataProvider(dataInfo: nil, data: raw_uint8_array, size: raw_uint8_array.count){ _, _, _ in }.flatMap {
            CGImage(width: colorData[0].count, height: colorData.count, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: colorData[0].count * 4, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: $0, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        }
        return image
    }
    
    //done
    public func getImage() -> CGImage {
        let image = self.createImageFromRGBA(self.imageData!)
        return image!
    }
    
    // process functions
    
    @discardableResult
    public func RGBtoBGR() -> ProcessableGraphics? {
        self.imageData = self.RunGPU(functionName: "RGBtoBGR")
        return self
    }
    
    @discardableResult
    public func GrayScale() -> ProcessableGraphics? {
        self.imageData = self.RunGPU(functionName: "GrayScale")
        return self
    }
    
    @discardableResult
    public func Binarize(threshold: UInt8) -> ProcessableGraphics? {
        self.imageData = self.RunGPUWith1Option(functionName: "Binarize", optionData: threshold)
        return self
    }
    
    
}

typealias PG_PIXEL_RGBA = SIMD4<UInt8>
typealias PG_IMAGE_DATA = [[PG_PIXEL_RGBA]]
typealias PG_PIXEL_RAW = (pixelRawData: [UInt8], width: Int, height: Int)
