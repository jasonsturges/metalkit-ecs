import Metal
import MetalKit
import QuartzCore
import simd

// Must mirror Shaders.metal exactly
struct FrameUniforms {
    var view:       float4x4
    var projection: float4x4
    var lightDir:   SIMD4<Float>  // w unused; float3 in MSL pads to 16 bytes, use float4 to match
}

struct ObjectUniforms {
    var model:        float4x4
    var normalMatrix: float4x4
    var color:        SIMD4<Float>
}

struct LineUniforms {
    var model: float4x4
    var color: SIMD4<Float>
}

final class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var solidPipeline: MTLRenderPipelineState!
    private var linePipeline:  MTLRenderPipelineState!
    private var depthState:    MTLDepthStencilState!

    private var boxMesh:         BoxMesh!
    private var gridMesh:        LineMesh!
    private var boundingBoxMesh: LineMesh!

    let world  = World()
    var camera = CameraState()

    private var lastTime: CFTimeInterval = 0

    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()!
        super.init()
        buildPipelines()
        buildMeshes()
        buildScene()
    }

    // MARK: – Setup

    private func buildPipelines() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("No default Metal library — add a .metal file to the target")
        }

        // Solid vertex descriptor: position (float3) at 0, normal (float3) at stride 16
        let solidVD = MTLVertexDescriptor()
        solidVD.attributes[0].format     = .float3
        solidVD.attributes[0].offset     = 0
        solidVD.attributes[0].bufferIndex = 0
        solidVD.attributes[1].format     = .float3
        solidVD.attributes[1].offset     = MemoryLayout<SIMD3<Float>>.stride
        solidVD.attributes[1].bufferIndex = 0
        solidVD.layouts[0].stride        = MemoryLayout<MeshVertex>.stride

        let solidPD = MTLRenderPipelineDescriptor()
        solidPD.vertexFunction                  = library.makeFunction(name: "vertex_solid")
        solidPD.fragmentFunction                = library.makeFunction(name: "fragment_solid")
        solidPD.vertexDescriptor                = solidVD
        solidPD.colorAttachments[0].pixelFormat = .bgra8Unorm
        solidPD.depthAttachmentPixelFormat      = .depth32Float
        solidPipeline = try! device.makeRenderPipelineState(descriptor: solidPD)

        // Line vertex descriptor: position (float3) only
        let lineVD = MTLVertexDescriptor()
        lineVD.attributes[0].format     = .float3
        lineVD.attributes[0].offset     = 0
        lineVD.attributes[0].bufferIndex = 0
        lineVD.layouts[0].stride        = MemoryLayout<LineVertex>.stride

        let linePD = MTLRenderPipelineDescriptor()
        linePD.vertexFunction                  = library.makeFunction(name: "vertex_line")
        linePD.fragmentFunction                = library.makeFunction(name: "fragment_line")
        linePD.vertexDescriptor                = lineVD
        linePD.colorAttachments[0].pixelFormat = .bgra8Unorm
        linePD.depthAttachmentPixelFormat      = .depth32Float
        linePipeline = try! device.makeRenderPipelineState(descriptor: linePD)

        let dd = MTLDepthStencilDescriptor()
        dd.depthCompareFunction = .less
        dd.isDepthWriteEnabled  = true
        depthState = device.makeDepthStencilState(descriptor: dd)
    }

    private func buildMeshes() {
        boxMesh         = BoxMesh(device: device)
        gridMesh        = LineMesh.makeGrid(device: device)
        boundingBoxMesh = LineMesh.makeBoundingBox(device: device)
    }

    private func buildScene() {
        let outerColors: [SIMD4<Float>] = [
            [1.00, 0.39, 0.20, 1],
            [0.84, 0.51, 0.27, 1],
            [0.69, 0.63, 0.35, 1],
            [0.55, 0.75, 0.43, 1],
            [0.39, 0.87, 0.51, 1],
        ]
        for i in 0..<5 {
            let angle = (Float(i) / 5.0) * 2 * .pi
            let r: Float = 5.0
            let x = cos(angle) * r
            let z = sin(angle) * r
            makeRotatingObject(world: world,
                               position: [x, 0, z],
                               velocity: [-z * 0.5, 0, x * 0.5],
                               rotationSpeed: [Float(30 + i * 20), 60, 90],
                               size: 1.5,
                               color: outerColors[i])
        }
        // Central cube
        makeRotatingObject(world: world,
                           position: [0, 0, 0],
                           velocity: [0, 0, 0],
                           rotationSpeed: [45, 90, 30],
                           size: 2.5,
                           color: [1, 0.1, 0.1, 1])
    }

    // MARK: – MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt  = lastTime == 0 ? 0.016 : Float(now - lastTime)
        lastTime = now

        MovementSystem.update(world: world, dt: dt)
        RotationSystem.update(world: world, dt: dt)
        CameraSystem.update(camera: &camera, dt: dt)

        guard let drawable   = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let cmdBuf     = commandQueue.makeCommandBuffer(),
              let encoder    = cmdBuf.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        let lightDir = simd_normalize(SIMD3<Float>(1, 2, 1))
        var frame  = FrameUniforms(
            view:       makeLookAt(eye: camera.eye, center: .zero),
            projection: makePerspective(fovYDegrees: camera.fovDegrees,
                                        aspect: aspect, near: 0.1, far: 200),
            lightDir:   SIMD4<Float>(lightDir.x, lightDir.y, lightDir.z, 0)
        )

        encoder.setDepthStencilState(depthState)
        encoder.setCullMode(.none)

        // ── Solid boxes ────────────────────────────────────────────────────
        encoder.setRenderPipelineState(solidPipeline)
        encoder.setVertexBuffer(boxMesh.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&frame,  length: MemoryLayout<FrameUniforms>.stride, index: 1)
        encoder.setFragmentBytes(&frame, length: MemoryLayout<FrameUniforms>.stride, index: 1)

        for id in world.renderables.keys {
            guard let pos       = world.positions[id],
                  let rot       = world.rotations[id],
                  let renderable = world.renderables[id] else { continue }

            let model = makeModelMatrix(position: pos.value, rotation: rot.value)
            var obj   = ObjectUniforms(model: model,
                                       normalMatrix: makeNormalMatrix(from: model),
                                       color: renderable.color)
            encoder.setVertexBytes(&obj, length: MemoryLayout<ObjectUniforms>.stride, index: 2)
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: boxMesh.indexCount,
                                          indexType: .uint16,
                                          indexBuffer: boxMesh.indexBuffer,
                                          indexBufferOffset: 0)
        }

        // ── Lines (grid + bounding box) ────────────────────────────────────
        encoder.setRenderPipelineState(linePipeline)
        encoder.setVertexBytes(&frame, length: MemoryLayout<FrameUniforms>.stride, index: 1)

        let identity = matrix_identity_float4x4
        var gridLine = LineUniforms(model: identity, color: [0.5, 0.5, 0.5, 1])
        encoder.setVertexBuffer(gridMesh.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&gridLine, length: MemoryLayout<LineUniforms>.stride, index: 2)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: gridMesh.vertexCount)

        var bbLine = LineUniforms(model: identity, color: [0.4, 0.4, 0.4, 1])
        encoder.setVertexBuffer(boundingBoxMesh.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&bbLine, length: MemoryLayout<LineUniforms>.stride, index: 2)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: boundingBoxMesh.vertexCount)

        encoder.endEncoding()
        cmdBuf.present(drawable)
        cmdBuf.commit()
    }
}
