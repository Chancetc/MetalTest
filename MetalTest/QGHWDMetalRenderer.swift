//
//  QGHWDMetalRenderer.swift
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/13.
//  Copyright © 2018 Tencent. All rights reserved.
//

import MetalKit

// BT.601, which is the standard for SDTV.
public let colorConversionMatrix601Default = matrix_float3x3([
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0
    ])

/*矩阵形式！！！
  1.0 0.0 1.4
 [1.0 -0.343 -0.711 ]
  1.0 1.765 0.0
 */
//ITU BT.601 Full Range
public let colorConversionMatrix601FullRangeDefault = matrix_float3x3([
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
    ])

// BT.709, which is the standard for HDTV.
public let colorConversionMatrix709Default = matrix_float3x3([
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
    ])

//QGHWDVertex  顶点坐标+纹理坐标（rdb+alpha）
private let quadVerticesConstants: [[Float]] = [
    //左侧alpha
    [-1.0, -1.0, 0.0, 1.0, 0.5, 1.0, 0.0, 1.0, 0.0, 1.0,
     -1.0, 1.0, 0.0, 1.0, 0.5, 0.0, 0.0, 0.0,  0.0, 0.0,
     1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 0.5, 1.0,  1.0, 1.0,
     1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.5, 0.0,   1.0,0.0],
    //右侧alpha
    [-1.0, -1.0, 0.0, 1.0, 0.0, 1.0, 0.5, 1.0, 0.0, 1.0,
     -1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0,
     1.0, -1.0, 0.0, 1.0, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0,
     1.0, 1.0, 0.0, 1.0, 0.5, 0.0, 1.0, 0.0,   1.0,0.0],
    //顶部alpha
    [-1.0, -1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.5, 0.0, 1.0,
     -1.0, 1.0, 0.0, 1.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0,
     1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.5, 1.0, 1.0,
     1.0, 1.0, 0.0, 1.0, 1.0, 0.5, 1.0, 0.0,   1.0,0.0],
    //底部alpha
    [-1.0, -1.0, 0.0, 1.0, 0.0, 0.5, 0.0, 1.0, 0.0, 1.0,
     -1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0,
     1.0, -1.0, 0.0, 1.0, 1.0, 0.5, 1.0, 1.0,1.0, 1.0,
     1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.5,   1.0,0.0],
]

extension matrix_float3x3 {
    init(_ columns:[Float]) {
        guard columns.count > 8 else { fatalError("Tried to initialize a 3x3 matrix with fewer than 9 values") }
        self.init([float3(columns[0],columns[1],columns[2]),float3(columns[3],columns[4],columns[5]),float3(columns[6],columns[7],columns[8])])
    }
}

class QGHWDMetalRenderer: NSObject {
    
    // - MARK: CONSTANTS
    let hwdVertexFunctionName = "hwd_vertexShader"
    let hwdYUVFragmentFunctionName = "hwd_yuvFragmentShader"

    // - MARK: VARS
    static var device: MTLDevice!
    var blendMode: QGHWDTextureBlendMode
    var vertexBuffer: MTLBuffer!
    var yuvMatrixBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState! //This will keep track of the compiled render pipeline you’re about to create.
    var commandQueue: MTLCommandQueue!
    var vertexCount: Int!
    var videoTextureCache: CVMetalTextureCache?
    
    init(metalLayer: CAMetalLayer) {
        
        blendMode = .alphaLeft
        super.init()
        QGHWDMetalRenderer.device = MTLCreateSystemDefaultDevice()
        metalLayer.device = QGHWDMetalRenderer.device
        setupPipelineState(metalLayer)
    }
    
    func setupPipelineState(_ metalLayer: CAMetalLayer) {
        
        //buffers
        let vertices = suitableQuadVertices
        let dataSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        vertexBuffer = QGHWDMetalRenderer.device.makeBuffer(bytes: vertices, length: dataSize, options: [])
        vertexCount = MemoryLayout.size(ofValue: vertices[0])*vertices.count/MemoryLayout<QGHWDVertex>.stride
        
        let yuvMatrixs = [ColorParameters(matrix: colorConversionMatrix601FullRangeDefault, offset: packed_float2(0.5, 0.5))]
        let yuvMatrixsDataSize = yuvMatrixs.count * MemoryLayout.size(ofValue: yuvMatrixs[0])
        yuvMatrixBuffer = QGHWDMetalRenderer.device.makeBuffer(bytes: yuvMatrixs, length: yuvMatrixsDataSize, options: [])
        
        let defaultLibrary = QGHWDMetalRenderer.device.makeDefaultLibrary()
        let vertexProgram = defaultLibrary?.makeFunction(name: hwdVertexFunctionName)
        let fragmentProgram = defaultLibrary?.makeFunction(name: hwdYUVFragmentFunctionName)
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        
        pipelineState = try! QGHWDMetalRenderer.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueue = QGHWDMetalRenderer.device.makeCommandQueue()
        let err = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, QGHWDMetalRenderer.device, nil, &videoTextureCache)
        guard err == noErr else {
            return
        }
    }
    
    func render(pixelBuffer: CVPixelBuffer?, metalLayer:CAMetalLayer?, attachment: QGAdvancedGiftAttachmentsFrameModel?) {
        
        guard let pixelBuffer = pixelBuffer else { return }
        var yTextureRef: CVMetalTexture?
        let yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        //注意格式！r8Unorm
        let yStatus = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache!, pixelBuffer, nil, .r8Unorm, yWidth, yHeight, 0, &yTextureRef);
        
        var uvTextureRef: CVMetalTexture?
        let uvWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let uvHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        //注意格式！rg8Unorm
        let uvStatus = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache!, pixelBuffer, nil, .rg8Unorm, uvWidth, uvHeight, 1, &uvTextureRef);
        
        guard yStatus == kCVReturnSuccess && uvStatus == kCVReturnSuccess else {
            return
        }
        
        let yTexture = CVMetalTextureGetTexture(yTextureRef!)
        let uvTexture = CVMetalTextureGetTexture(uvTextureRef!)
        
        guard yTexture != nil && uvTexture != nil && metalLayer != nil else {
            //no texture content
            return
        }
        
        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture //which returns the texture in which you need to draw in order for something to appear on the screen.
        renderPassDescriptor.colorAttachments[0].loadAction = .clear //“set the texture to the clear color before doing any drawing,”
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(yuvMatrixBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(yTexture!, index: Int(QGHWDYUVFragmentTextureIndexLuma.rawValue))
        renderEncoder.setFragmentTexture(uvTexture!, index: Int(QGHWDYUVFragmentTextureIndexChroma.rawValue))
        var count = UInt32(2)
        if let attachment = attachment, let attachmentObj = attachment.attachments.last, let maskImage = attachmentObj.maskModel.maskImageForFrame(attachment.index, directory: "./MetalTest/resource/752_1344") {
            
            if let texture = try? QGHWDMetalRenderer.loadTexture(image: maskImage) {
                renderEncoder.setFragmentTexture(texture, index: 2)
                count = UInt32(3)
            }
        }
        
        renderEncoder.setFragmentBytes(&count,
                                       length: MemoryLayout<UInt32>.stride, index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension QGHWDMetalRenderer {
    
    var suitableQuadVertices: [Float] {
        
        switch blendMode {
        case .alphaLeft:
            return quadVerticesConstants[0]
        case .alphaRight:
            return quadVerticesConstants[1]
        case .alphaTop:
            return quadVerticesConstants[2]
        case .alphaBottom:
            return quadVerticesConstants[3]
        default:
            return quadVerticesConstants[0]
        }
    }
    
    func pixelBufferToMTLTexture(pixelBuffer:CVPixelBuffer) -> MTLTexture {
        
        var texture:MTLTexture!
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let format:MTLPixelFormat = .bgra8Unorm
        var textureRef : CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                               videoTextureCache!,
                                                               pixelBuffer,
                                                               nil,
                                                               format,
                                                               width,
                                                               height,
                                                               0,
                                                               &textureRef)
        
        if(status == kCVReturnSuccess)
        {
            texture = CVMetalTextureGetTexture(textureRef!)
        }
        return texture
    }
    
    static func loadTexture(image: UIImage) throws -> MTLTexture? {
        
        let textureLoader = MTKTextureLoader(device: QGHWDMetalRenderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
            [.origin: MTKTextureLoader.Origin.bottomLeft,
             .SRGB: false,
             .generateMipmaps: NSNumber(booleanLiteral: true)]
        guard let cgImage = image.cgImage else { return nil }
        let texture = try textureLoader.newTexture(cgImage: cgImage, options: textureLoaderOptions)
        return texture
    }
    
    static func loadTexture(imageName: String) throws -> MTLTexture? {
        
        let textureLoader = MTKTextureLoader(device: QGHWDMetalRenderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
            [.origin: MTKTextureLoader.Origin.bottomLeft,
             .SRGB: false,
             .generateMipmaps: NSNumber(booleanLiteral: true)]
        
        let fileExtension =
            URL(fileURLWithPath: imageName).pathExtension.isEmpty ?
                "png" : nil
        
        guard let url = Bundle.main.url(forResource: imageName,
                                        withExtension: fileExtension)
            else {
                print("Failed to load \(imageName)\n - loading from Assets Catalog")
                return try textureLoader.newTexture(name: imageName, scaleFactor: 1.0,
                                                    bundle: Bundle.main, options: nil)
        }
        
        let texture = try textureLoader.newTexture(URL: url,
                                                   options: textureLoaderOptions)
        print("loaded texture: \(url.lastPathComponent)")
        return texture
    }
}
