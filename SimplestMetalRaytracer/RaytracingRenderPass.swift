import Foundation
import Metal

class RaytracingRenderPass {
    let renderPipeline: MTLRenderPipelineState
    let simplePrimitiveAccelStruct: SimplePrimitiveAccelerationStructure

    init(metal: MetalDevice,
         pixelFormat: MTLPixelFormat) {

        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = metal.library.makeFunction(name: "vertexShader")
        renderDescriptor.fragmentFunction = metal.library.makeFunction(name: "fragmentShader")
        renderDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        self.renderPipeline = try! metal.device.makeRenderPipelineState(descriptor: renderDescriptor)

        self.simplePrimitiveAccelStruct = SimplePrimitiveAccelerationStructure(metal: metal)
        self.simplePrimitiveAccelStruct.build()
    }

    func encode(into renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setFragmentAccelerationStructure(simplePrimitiveAccelStruct.accelerationStructure, bufferIndex: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
