//
//  QGHWDMetalRenderer.swift
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/13.
//  Copyright © 2018 Tencent. All rights reserved.
//

import MetalKit

class QGHWDMetalRenderer: NSObject {
    
    let hwdFragmentFunctionName = "hwd_fragmentShader"
    let hwdVertexFunctionName = "hwd_vertexShader"
    
    static var device: MTLDevice!
    
    //QGHWDVertex
    let quadVertices: [Float] = [
        1.0, -1.0, 0.0, 1.0, 1.0, 0.0, 0.5, 0.0,
        -1.0, -1.0, 0.0, 1.0, 0.5, 0.0, 0.0, 0.0,
        -1.0, 1.0, 0.0, 1.0, 0.5, 1.0, 0, 1.0,
        1.0, -1.0, 0.0, 1.0, 1.0, 0.0, 0.5, 0.0,
        -1.0, 1.0, 0.0, 1.0, 0.5, 1.0, 0.0, 1.0,
        1.0, 1.0, 0.0, 1.0, 1, 1.0, 0.5, 1.0
    ]
    
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState! //This will keep track of the compiled render pipeline you’re about to create.
    var commandQueue: MTLCommandQueue!
    var vertexCount: Int!
    
    init(metalLayer: CAMetalLayer) {
        super.init()
        
        QGHWDMetalRenderer.device = MTLCreateSystemDefaultDevice()
        metalLayer.device = QGHWDMetalRenderer.device
        
        let dataSize = quadVertices.count * MemoryLayout.size(ofValue: quadVertices[0])
        vertexBuffer = QGHWDMetalRenderer.device.makeBuffer(bytes: quadVertices, length: dataSize, options: [])
        vertexCount = MemoryLayout.size(ofValue: quadVertices[0])*quadVertices.count/MemoryLayout<QGHWDVertex>.stride
        
        let defaultLibrary = QGHWDMetalRenderer.device.makeDefaultLibrary()
        let vertexProgram = defaultLibrary?.makeFunction(name: hwdVertexFunctionName)
        let fragmentProgram = defaultLibrary?.makeFunction(name: hwdFragmentFunctionName)
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! QGHWDMetalRenderer.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueue = QGHWDMetalRenderer.device.makeCommandQueue()
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
    
}