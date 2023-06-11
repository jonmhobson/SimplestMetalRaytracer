import Foundation
import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    let metal: MetalDevice
    let raytracingRenderPass: RaytracingRenderPass

    init(metalView: MTKView) {
        guard let metal = MetalDevice() else { fatalError("Failed to initialize Metal") }
        self.metal = metal
        self.raytracingRenderPass = RaytracingRenderPass(
            metal: metal,
            pixelFormat: metalView.colorPixelFormat
        )
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = metal.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        raytracingRenderPass.encode(into: renderEncoder)

        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }

        commandBuffer.commit()
    }
}
