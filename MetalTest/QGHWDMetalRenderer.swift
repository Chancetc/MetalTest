//
//  QGHWDMetalRenderer.swift
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/13.
//  Copyright © 2018 Tencent. All rights reserved.
//

import MetalKit

extension matrix_float3x3 {
    init(_ columns:[Float]) {
        guard columns.count > 8 else { fatalError("Tried to initialize a 3x3 matrix with fewer than 9 values") }
        self.init([float3(columns[0],columns[1],columns[2]),float3(columns[3],columns[4],columns[5]),float3(columns[6],columns[7],columns[8])])
    }
}

class QGHWDMetalRenderer: NSObject {
    
    let hwdVertexFunctionName = "hwd_vertexShader"
    let hwdFragmentFunctionName = "hwd_fragmentShader"
    let hwdYUVFragmentFunctionName = "hwd_yuvFragmentShader"
    
    static var device: MTLDevice!
    
////    //QGHWDVertex
//    let quadVertices: [Float] = [
//        1.0, -1.0, 0.0, 1.0, 1.0, 0.0, 0.5, 0.0,
//        -1.0, -1.0, 0.0, 1.0, 0.5, 0.0, 0.0, 0.0,
//        -1.0, 1.0, 0.0, 1.0, 0.5, 1.0, 0, 1.0,
//        1.0, -1.0, 0.0, 1.0, 1.0, 0.0, 0.5, 0.0,
//        -1.0, 1.0, 0.0, 1.0, 0.5, 1.0, 0.0, 1.0,
//        1.0, 1.0, 0.0, 1.0, 1, 1.0, 0.5, 1.0
//    ]
    
    //QGHWDVertex
    let quadVertices: [Float] = [
        1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 0.5, 1.0,
        -1.0, -1.0, 0.0, 1.0, 0.5, 1.0, 0.0, 1.0,
        -1.0, 1.0, 0.0, 1.0, 0.5, 0.0, 0.0, 0.0,
        1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 0.5, 1.0,
        -1.0, 1.0, 0.0, 1.0, 0.5, 0.0, 0.0, 0.0,
        1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.5, 0.0
    ]
    
    public let colorConversionMatrix601FullRangeDefault = matrix_float3x3([
        1.0,    1.0,    1.0,
        0.0,    -0.343, 1.765,
        1.4,    -0.711, 0.0,
    ])
    
    var vertexBuffer: MTLBuffer!
    var yuvMatrixBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState! //This will keep track of the compiled render pipeline you’re about to create.
    var commandQueue: MTLCommandQueue!
    var vertexCount: Int!
    
    var videoTextureCache: CVMetalTextureCache?
    
    init(metalLayer: CAMetalLayer) {
        super.init()
        
        QGHWDMetalRenderer.device = MTLCreateSystemDefaultDevice()
        metalLayer.device = QGHWDMetalRenderer.device
        
        setupPipelineState()
    }
    
    func setupPipelineState() {
        
        //buffers
        let dataSize = quadVertices.count * MemoryLayout.size(ofValue: quadVertices[0])
        vertexBuffer = QGHWDMetalRenderer.device.makeBuffer(bytes: quadVertices, length: dataSize, options: [])
        vertexCount = MemoryLayout.size(ofValue: quadVertices[0])*quadVertices.count/MemoryLayout<QGHWDVertex>.stride
        
        let yuvMatrixs = [ColorParameters(yuvToRGB: colorConversionMatrix601FullRangeDefault)]
        
        let yuvMatrixsDataSize = yuvMatrixs.count * MemoryLayout.size(ofValue: yuvMatrixs[0])
        yuvMatrixBuffer = QGHWDMetalRenderer.device.makeBuffer(bytes: yuvMatrixs, length: yuvMatrixsDataSize, options: [])
        
        let defaultLibrary = QGHWDMetalRenderer.device.makeDefaultLibrary()
        let vertexProgram = defaultLibrary?.makeFunction(name: hwdVertexFunctionName)
        let fragmentProgram = defaultLibrary?.makeFunction(name: hwdYUVFragmentFunctionName)
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! QGHWDMetalRenderer.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueue = QGHWDMetalRenderer.device.makeCommandQueue()
        let err = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, QGHWDMetalRenderer.device, nil, &videoTextureCache)
        guard err == noErr else {
            return
        }
    }
    
    func render(pixelBuffer: CVPixelBuffer?, metalLayer:CAMetalLayer?) {
        
        
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
//        CVBufferRelease(yTextureRef!)
//        CVBufferRelease(uvTextureRef!)
        
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
        renderEncoder.setFragmentTexture(yTexture!, index: 0)
        renderEncoder.setFragmentTexture(uvTexture!, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func render(texture: MTLTexture?, metalLayer:CAMetalLayer?) {
        
        guard texture != nil && metalLayer != nil else {
            //no texture content
            return
        }
        //metalLayer.drawableSize = CGSize(width: metalLayer.contentsScale*metalLayer.frame.size.width, height: metalLayer.contentsScale*metalLayer.frame.size.height)
        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture //which returns the texture in which you need to draw in order for something to appear on the screen.
        renderPassDescriptor.colorAttachments[0].loadAction = .clear //“set the texture to the clear color before doing any drawing,”
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture!, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
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
            //此处也不需要释放？？
        }
        
        return texture
    }
    
    static func loadTexture(imageName: String) throws -> MTLTexture? {
        // 1
        let textureLoader = MTKTextureLoader(device: QGHWDMetalRenderer.device)
        
        // 2
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
            [.origin: MTKTextureLoader.Origin.bottomLeft,
             .SRGB: false,
             .generateMipmaps: NSNumber(booleanLiteral: true)]
        
        // 3
        let fileExtension =
            URL(fileURLWithPath: imageName).pathExtension.isEmpty ?
                "png" : nil
        
        // 4
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
    
    deinit {
        if videoTextureCache != nil {
            //此处release灰报错？
//            CFRelease(videoTextureCache!)
        }
    }
}
