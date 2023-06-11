import Foundation
import Metal

// A simple wrapper for the "core" Metal objects, so it's easier to pass them around.
class MetalDevice {
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else {
            return nil
        }

        self.device = device
        self.library = library
        self.commandQueue = commandQueue
    }
}
