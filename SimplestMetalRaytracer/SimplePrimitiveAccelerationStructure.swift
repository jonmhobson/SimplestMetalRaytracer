import Metal

class SimplePrimitiveAccelerationStructure {
    private let metal: MetalDevice

    let accelerationStructure: MTLAccelerationStructure

    private let accelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
    private let accelStructSizes: MTLAccelerationStructureSizes

    init(metal: MetalDevice, spheres: [Sphere]) {
        self.metal = metal

        let boundingBoxes = spheres.map(\.boundingBox)

        let boundingBoxBuffer = metal.device.makeBuffer(
            bytes: boundingBoxes,
            length: MemoryLayout<BoundingBox>.stride * spheres.count
        )

        let geometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
        geometryDescriptor.boundingBoxBuffer = boundingBoxBuffer
        geometryDescriptor.boundingBoxCount = spheres.count
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
