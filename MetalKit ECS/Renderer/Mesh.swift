import Metal
import simd

struct MeshVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
}

struct BoxMesh {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int

    init(device: MTLDevice) {
        let h: Float = 0.5

        var vertices: [MeshVertex] = []
        var indices: [UInt16] = []

        func addFace(verts: [SIMD3<Float>], normal: SIMD3<Float>) {
            let base = UInt16(vertices.count)
            for v in verts { vertices.append(MeshVertex(position: v, normal: normal)) }
            indices += [base, base+1, base+2, base, base+2, base+3]
        }

        // +X
        addFace(verts: [[ h,-h, h],[ h,-h,-h],[ h, h,-h],[ h, h, h]], normal: [ 1, 0, 0])
        // -X
        addFace(verts: [[-h,-h,-h],[-h,-h, h],[-h, h, h],[-h, h,-h]], normal: [-1, 0, 0])
        // +Y
        addFace(verts: [[-h, h,-h],[ h, h,-h],[ h, h, h],[-h, h, h]], normal: [ 0, 1, 0])
        // -Y
        addFace(verts: [[-h,-h, h],[ h,-h, h],[ h,-h,-h],[-h,-h,-h]], normal: [ 0,-1, 0])
        // +Z
        addFace(verts: [[-h,-h, h],[ h,-h, h],[ h, h, h],[-h, h, h]], normal: [ 0, 0, 1])
        // -Z
        addFace(verts: [[ h,-h,-h],[-h,-h,-h],[-h, h,-h],[ h, h,-h]], normal: [ 0, 0,-1])

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<MeshVertex>.stride * vertices.count,
            options: .storageModeShared)!
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: MemoryLayout<UInt16>.stride * indices.count,
            options: .storageModeShared)!
        indexCount = indices.count
    }
}

struct LineVertex {
    var position: SIMD3<Float>
}

struct LineMesh {
    let vertexBuffer: MTLBuffer
    let vertexCount: Int

    init(device: MTLDevice, points: [SIMD3<Float>]) {
        var verts = points.map { LineVertex(position: $0) }
        vertexBuffer = device.makeBuffer(
            bytes: &verts,
            length: MemoryLayout<LineVertex>.stride * verts.count,
            options: .storageModeShared)!
        vertexCount = verts.count
    }

    static func makeGrid(device: MTLDevice, size: Float = 20, divisions: Int = 20) -> LineMesh {
        let half = size / 2.0
        let step = size / Float(divisions)
        var pts: [SIMD3<Float>] = []
        for i in 0...divisions {
            let t = -half + Float(i) * step
            pts += [[-half, 0, t], [half, 0, t]]
            pts += [[t, 0, -half], [t, 0, half]]
        }
        return LineMesh(device: device, points: pts)
    }

    static func makeBoundingBox(device: MTLDevice, size: Float = 20) -> LineMesh {
        let h = size / 2.0
        var pts: [SIMD3<Float>] = []
        func edge(_ a: SIMD3<Float>, _ b: SIMD3<Float>) { pts += [a, b] }

        // Bottom square
        edge([-h,-h,-h], [ h,-h,-h]); edge([ h,-h,-h], [ h,-h, h])
        edge([ h,-h, h], [-h,-h, h]); edge([-h,-h, h], [-h,-h,-h])
        // Top square
        edge([-h, h,-h], [ h, h,-h]); edge([ h, h,-h], [ h, h, h])
        edge([ h, h, h], [-h, h, h]); edge([-h, h, h], [-h, h,-h])
        // Verticals
        edge([-h,-h,-h], [-h, h,-h]); edge([ h,-h,-h], [ h, h,-h])
        edge([ h,-h, h], [ h, h, h]); edge([-h,-h, h], [-h, h, h])

        return LineMesh(device: device, points: pts)
    }
}
