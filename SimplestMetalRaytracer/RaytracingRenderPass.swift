import Foundation
import Metal

class RaytracingRenderPass {
    let renderPipeline: MTLRenderPipelineState
    let simplePrimitiveAccelStruct: SimplePrimitiveAccelerationStructure
    let intersectionFunctionTable: MTLIntersectionFunctionTable

    init(metal: MetalDevice,
         pixelFormat: MTLPixelFormat) {

        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = metal.library.makeFunction(name: "vertexShader")
        renderDescriptor.fragmentFunction = metal.library.makeFunction(name: "fragmentShader")
        renderDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        let intersectionFunction = metal.library.makeFunction(name: "customIntersectionFunction")!

        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = [intersectionFunction]

        renderDescriptor.fragmentLinkedFunctions = linkedFunctions

        self.renderPipeline = try! metal.device.makeRenderPipelineState(descriptor: renderDescriptor)

        self.simplePrimitiveAccelStruct = SimplePrimitiveAccelerationStructure(metal: metal)
        self.simplePrimitiveAccelStruct.build()

        let intersectionFunctionTableDescriptor = MTLIntersectionFunctionTableDescriptor()
        intersectionFunctionTableDescriptor.functionCount = 1
        self.intersectionFunctionTable = renderPipeline.makeIntersectionFunctionTable(descriptor: intersectionFunctionTableDescriptor, stage: .fragment)!

        let functionHandle = renderPipeline.functionHandle(function: intersectionFunction, stage: .fragment)
        intersectionFunctionTable.setFunction(functionHandle, index: 0)
    }

    func encode(into renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setFragmentAccelerationStructure(simplePrimitiveAccelStruct.accelerationStructure, bufferIndex: 0)
        renderEncoder.setFragmentIntersectionFunctionTable(intersectionFunctionTable, bufferIndex: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
