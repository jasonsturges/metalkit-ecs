import AppKit
import Metal
import MetalKit
import SwiftUI
import simd

// MTKView subclass so we can intercept scroll wheel events directly.
final class MetalMTKView: MTKView {
    weak var coordinator: MetalView.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func scrollWheel(with event: NSEvent) {
        coordinator?.handleScroll(event)
    }
}

struct MetalView: NSViewRepresentable {
    let renderer: Renderer

    func makeCoordinator() -> Coordinator { Coordinator(renderer: renderer) }

    func makeNSView(context: Context) -> MetalMTKView {
        let view = MetalMTKView()
        view.device                   = renderer.device
        view.delegate                 = renderer
        view.colorPixelFormat         = .bgra8Unorm
        view.depthStencilPixelFormat  = .depth32Float
        view.clearColor               = MTLClearColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.coordinator              = context.coordinator

        let pan = NSPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }

    func updateNSView(_ view: MetalMTKView, context: Context) {}

    // MARK: – Coordinator (input → camera)

    final class Coordinator: NSObject {
        let renderer: Renderer
        private var lastTranslation: CGPoint = .zero

        init(renderer: Renderer) { self.renderer = renderer }

        @objc func handlePan(_ g: NSPanGestureRecognizer) {
            let t = g.translation(in: g.view)

            switch g.state {
            case .began:
                lastTranslation = .zero
                // Capture spherical position for a seamless transition to manual mode
                var cam = renderer.camera
                if cam.mode == .autoOrbit {
                    let pos  = cam.eye
                    let dist = simd_length(pos)
                    cam.manualAngleH = atan2(pos.z, pos.x) * (180 / .pi)
                    cam.manualAngleV = dist > 0.001
                        ? asin(max(-1, min(1, pos.y / dist))) * (180 / .pi)
                        : 30
                    cam.manualRadius = max(5, dist)
                    cam.mode = .manual
                }
                renderer.camera = cam

            case .changed:
                let dx = Float(t.x - lastTranslation.x)
                let dy = Float(t.y - lastTranslation.y)
                lastTranslation = t
                renderer.camera.manualAngleH += dx * 0.3
                renderer.camera.manualAngleV  = max(-89, min(89, renderer.camera.manualAngleV - dy * 0.3))

            case .ended, .cancelled:
                lastTranslation = .zero
                if renderer.camera.mode == .manual {
                    renderer.camera.mode           = .returning
                    renderer.camera.returnProgress = 0
                    renderer.camera.returnStartPos  = renderer.camera.eye
                    let rad = renderer.camera.orbitAngle * .pi / 180
                    renderer.camera.returnTargetPos = SIMD3(
                        cos(rad) * renderer.camera.orbitRadius,
                        renderer.camera.orbitHeight,
                        sin(rad) * renderer.camera.orbitRadius
                    )
                }
            default: break
            }
        }

        func handleScroll(_ event: NSEvent) {
            let scale: Float = event.hasPreciseScrollingDeltas ? 0.2 : 1.0
            let delta = Float(event.scrollingDeltaY) * scale
            renderer.camera.orbitRadius  = max(5, min(50, renderer.camera.orbitRadius  - delta))
            renderer.camera.manualRadius = max(5, min(50, renderer.camera.manualRadius - delta))
        }
    }
}

struct ContentView: View {
    let renderer: Renderer

    var body: some View {
        MetalView(renderer: renderer)
            .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView(renderer: Renderer(device: MTLCreateSystemDefaultDevice()!))
}
