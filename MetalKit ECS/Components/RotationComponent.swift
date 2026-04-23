import simd

struct RotationComponent {
    var value: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
}
