import Foundation
import Metal

struct BoundingBox {
    let min: MTLPackedFloat3
    let max: MTLPackedFloat3
}

struct Sphere {
    let center: MTLPackedFloat3
    let radius: Float

    var boundingBox: BoundingBox {
        .init(min: MTLPackedFloat3Make(center.x - radius, center.y - radius, center.z - radius),
              max: MTLPackedFloat3Make(center.x + radius, center.y + radius, center.z + radius))
    }
}

private let spheres: [Sphere] = [
    .init(center: MTLPackedFloat3Make(0.0, -100.5, -1.0), radius: 100.0),
    .init(center: MTLPackedFloat3Make(0.0, 0.0, -1.0), radius: 0.5)
]

class RaytracingRenderPass {
    let renderPipeline: MTLRenderPipelineState
    let simplePrimitiveAccelStruct: SimplePrimitiveAccelerationStructure
    let intersectionFunctionTable: MTLIntersectionFunctionTable
    let sphereBuffer: MTLBuffer

    init(metal: MetalDevice,
         pixelFormat: MTLPixelFormat) {

        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = metal.library.makeFunction(name: "vertexShader")
        renderDescriptor.fragmentFunction = metal.library.makeFunction(name: "fragmentShader")
        renderDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        let intersectionFunction = metal.library.makeFunction(name: "sphereIntersectionFunction")!

        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = [intersectionFunction]

        renderDescriptor.fragmentLinkedFunctions = linkedFunctions

        sphereBuffer = metal.device.makeBuffer(bytes: spheres, length: MemoryLayout<Sphere>.stride * spheres.count)!

        self.renderPipeline = try! metal.device.makeRenderPipelineState(descriptor: renderDescriptor)

        self.simplePrimitiveAccelStruct = SimplePrimitiveAccelerationStructure(metal: metal, spheres: spheres)
        self.simplePrimitiveAccelStruct.build()

        let intersectionFunctionTableDescriptor = MTLIntersectionFunctionTableDescriptor()
        intersectionFunctionTableDescriptor.functionCount = 1
        self.intersectionFunctionTable = renderPipeline.makeIntersectionFunctionTable(descriptor: intersectionFunctionTableDescriptor, stage: .fragment)!

        self.intersectionFunctionTable.setBuffer(sphereBuffer, offset: 0, index: 0)

        let functionHandle = renderPipeline.functionHandle(function: intersectionFunction, stage: .fragment)
        intersectionFunctionTable.setFunction(functionHandle, index: 0)
    }

    func encode(into renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setFragmentAccelerationStructure(simplePrimitiveAccelStruct.accelerationStructure, bufferIndex: 0)
        renderEncoder.setFragmentIntersectionFunctionTable(intersectionFunctionTable, bufferIndex: 1)
        renderEncoder.setFragmentBuffer(sphereBuffer, offset: 0, index: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
