import SwiftUI

@main
struct SimplestMetalRaytracerApp: App {
    var body: some Scene {
        Window("SimplestRaytracer", id: "simplest-metal-raytracer") {
            MetalView()
        }
    }
}
