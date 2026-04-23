import simd

func makePerspective(fovYDegrees: Float, aspect: Float, near: Float, far: Float) -> float4x4 {
    let fovY = fovYDegrees * .pi / 180.0
    let yScale = 1.0 / tan(fovY / 2.0)
    let xScale = yScale / aspect
    let zRange = far - near
    return float4x4(columns: (
        SIMD4(xScale, 0, 0, 0),
        SIMD4(0, yScale, 0, 0),
        SIMD4(0, 0, -(far + near) / zRange, -1),
        SIMD4(0, 0, -2 * far * near / zRange, 0)
    ))
}

func makeLookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float> = [0, 1, 0]) -> float4x4 {
    let z = simd_normalize(eye - center)
    let x = simd_normalize(simd_cross(up, z))
    let y = simd_cross(z, x)
    return float4x4(columns: (
        SIMD4(x.x, y.x, z.x, 0),
        SIMD4(x.y, y.y, z.y, 0),
        SIMD4(x.z, y.z, z.z, 0),
        SIMD4(-simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye), 1)
    ))
}

func makeModelMatrix(position: SIMD3<Float>, rotation: simd_quatf, scale: Float = 1) -> float4x4 {
    var m = float4x4(rotation)
    m.columns.0 *= scale
    m.columns.1 *= scale
    m.columns.2 *= scale
    m.columns.3 = SIMD4(position.x, position.y, position.z, 1)
    return m
}

// For objects with no non-uniform scale, the normal matrix equals the rotation part.
func makeNormalMatrix(from model: float4x4) -> float4x4 {
    var m = model
    m.columns.3 = [0, 0, 0, 1]
    return m
}
