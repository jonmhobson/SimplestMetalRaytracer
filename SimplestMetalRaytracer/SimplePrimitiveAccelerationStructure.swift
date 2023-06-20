import Metal

class SimplePrimitiveAccelerationStructure {
    private let metal: MetalDevice

    let accelerationStructure: MTLAccelerationStructure

    private let accelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
    private let accelStructSizes: MTLAccelerationStructureSizes

    private let vertices: [MTLPackedFloat3] = [
        MTLPackedFloat3Make( 0.0,  1.0, 0.0),
        MTLPackedFloat3Make(-1.0, -1.0, 0.0),
        MTLPackedFloat3Make( 1.0, -1.0, 0.0)
    ]

    init(metal: MetalDevice) {
        self.metal = metal

        let vertexBuffer = metal.device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<MTLPackedFloat3>.stride * vertices.count
        )!

        let geometryDescriptor = MTLAccelerationStructureTriangleGeometryDescriptor()
        geometryDescriptor.vertexBuffer = vertexBuffer
        geometryDescriptor.triangleCount = 1
        geometryDescriptor.opaque = false
        geometryDescriptor.intersectionFunctionTableOffset = 0

        self.accelerationStructureDescriptor.geometryDescriptors = [geometryDescriptor]
        self.accelStructSizes = metal.device.accelerationStructureSizes(descriptor: accelerationStructureDescriptor)
        self.accelerationStructure = metal.device.makeAccelerationStructure(size: accelStructSizes.accelerationStructureSize)!
    }

    func build() {
        let scratchBuffer = metal.device.makeBuffer(length: accelStructSizes.buildScratchBufferSize, options: .storageModePrivate)!
        let commandBuffer = metal.commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeAccelerationStructureCommandEncoder()!

        commandEncoder.build(accelerationStructure: accelerationStructure,
                             descriptor: accelerationStructureDescriptor,
                             scratchBuffer: scratchBuffer,
                             scratchBufferOffset: 0)

        commandEncoder.endEncoding()
        commandBuffer.commit()
    }
}
