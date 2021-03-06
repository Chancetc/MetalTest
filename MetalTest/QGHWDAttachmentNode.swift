//
//  QGHWDAttachmentNode.swift
//  MetalTest
//
//  Created by Chanceguo on 2018/12/19.
//  Copyright © 2018 Tencent. All rights reserved.
//

import Foundation
import MetalKit

let hwdAttachmentVertexFunctionName = "hwdAttachment_vertexShader"
let hwdAttachmentSourceInFragmentFunctionName = "hwdAttachment_fragmentShader_srcIn"
let hwdAttachmentSourceOutFragmentFunctionName = "hwdAttachment_fragmentShader_srcOut"
let hwdAttachmentSourceMixFragmentFunctionName = "hwdAttachment_fragmentShader_srcMix"

let attachmentOriginVertices: [Float] = [-1.0, -1.0, 0.0, 1.0,-1.0, 1.0, 0.0, 1.0,1.0, -1.0, 0.0, 1.0,1.0, 1.0, 0.0, 1.0]
let attachmentOriginTextureCoordinates: [Float] = [0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]

extension float4x4 {
    
    init(_ rowDirection:[Float]) {
        guard rowDirection.count > 16 else { fatalError("Tried to initialize a 3x3 matrix with fewer than 16 values") }
        let data = rowDirection
        self.init(rows: [float4(data[0],data[1],data[2],data[3]), float4(data[4],data[5],data[6],data[7]), float4(data[8],data[9],data[10],data[11]), float4(data[12],data[13],data[14],data[15])])
    }
}

extension float2x4 {
    
    init(_ rowDirection:[Float]) {
        guard rowDirection.count > 8 else { fatalError("Tried to initialize a 3x3 matrix with fewer than 8 values") }
        let data = rowDirection
        self.init(rows: [float2(data[0],data[1]), float2(data[2],data[3]), float2(data[4],data[5]), float2(data[6],data[7])])
    }
}

class QGHWDAttachmentNode: NSObject {
    
    var containerWidth: Float!
    var containerHeight: Float!
    
    var model: QGAdvancedGiftAttachmentModel!
    var frameIndex: Int!
    
    var _sourceTexture: MTLTexture?
    
    
    var device: MTLDevice!
    var size: CGSize {
        return model.size
    }
    var origin: CGPoint {
        return model.origin
    }
    var vertexCount: Int {
        return 4
    }
    
    override init() {
        super.init()
        containerHeight = 0.0
        containerWidth = 0.0
    }
    
    var maskTexture: MTLTexture? {
        if let maskImage = model.maskModel.maskImageForFrame(frameIndex, directory: "./MetalTest/resource/752_1344") {
            if let texture = try? QGHWDMetalRenderer.loadTexture(image: maskImage) {
                return texture
            }
        }
        return nil
    }
    
    var vertices: [Float] {
        
        guard containerHeight > 0, containerWidth > 0 else { return attachmentOriginVertices }
        let originX = -1+2*Float(origin.x)/containerWidth
        let originY = 1-2*Float(origin.y)/containerHeight
        let width = 2*Float(size.width)/containerWidth
        let height = 2*Float(size.height)/containerHeight
        let vertices: [Float] = [originX, originY, 0.0, 1.0, originX, originY-height, 0.0, 1.0, originX+width, originY, 0.0, 1.0 , originX+width, originY-height, 0.0, 1.0]

        return vertices
    }
    
    var maskCoordinates: [Float] {
        
        //todo 这里需要根据实际纹理分布来取值
        guard containerHeight > 0, containerWidth > 0 else { return attachmentOriginVertices }
        let orginX = Float(origin.x)/containerWidth/2.0
        let originY = Float(origin.y)/containerHeight
        let width = Float(size.width)/containerWidth/2.0
        let height = Float(size.height)/containerHeight
        let coordinates: [Float] = [orginX, originY, orginX, originY+height, orginX+width, originY, orginX+width, originY+height]
        return coordinates
    }
    
    var vertexBuffer: MTLBuffer? {
        
        let colunmCountForVertices = 4
        let colunmCountForCoordinate = 2
        let vertices = self.vertices
        let sourceCoordinates = attachmentOriginTextureCoordinates
        let maskCoordinates = self.maskCoordinates
        
        var vertexData: [Float] = Array.init()
        for (index, element) in vertices.enumerated() {
            vertexData.append(element)
            let row = Int(index/colunmCountForVertices)
            if index%colunmCountForVertices == colunmCountForVertices-1 {
                vertexData.append(sourceCoordinates[row*colunmCountForCoordinate])
                vertexData.append(sourceCoordinates[row*colunmCountForCoordinate+1])
                vertexData.append(maskCoordinates[row*colunmCountForCoordinate])
                vertexData.append(maskCoordinates[row*colunmCountForCoordinate+1])
            }
        }
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        guard let buffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: []) else {
            return nil
        }
        return buffer
    }
    
    var attachmentParamsBuffer: MTLBuffer? {
        
        var maskType = 0
        switch model.maskModel.maskType {
        case .SrcOut:
            maskType = 0
        case .SrceIn:
            maskType = 1
        case .SrcMix:
            maskType = 2
        }
        let alpha = model.alpha
        let params = [QGHWDAttachmentFragmentParameter(maskType: UInt32(maskType), alpha: alpha, matrix: colorConversionMatrix601FullRangeDefault, offset: packed_float2(0.5, 0.5))]
        let paramsDataSize = params.count * MemoryLayout.size(ofValue: params[0])
        guard let buffer = device.makeBuffer(bytes: params, length: paramsDataSize, options: []) else {
            return nil
        }
        return buffer
    }
    
    convenience init(device: MTLDevice, model: QGAdvancedGiftAttachmentModel, frameIndex:Int) {
        self.init()
        self.device = device
        self.model = model
        self.frameIndex = frameIndex
    }
}
