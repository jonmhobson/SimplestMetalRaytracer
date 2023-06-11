import SwiftUI
import MetalKit

class MetalViewInteractor {
    let renderer: Renderer
    let metalView = MTKView()

    init() {
        renderer = Renderer(metalView: metalView)
        metalView.device = renderer.metal.device
        metalView.delegate = renderer
    }
}

struct MetalViewRepresentable: NSViewRepresentable {
    let metalView: MTKView
    func makeNSView(context: Context) -> some NSView { metalView }
    func updateNSView(_ nsView: NSViewType, context: Context) {}
}

struct MetalView: View {
    var interactor = MetalViewInteractor()

    var body: some View {
        MetalViewRepresentable(metalView: interactor.metalView)
    }
}

#Preview {
    MetalView()
}
