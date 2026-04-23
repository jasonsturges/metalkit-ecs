import simd

enum CameraMode {
    case autoOrbit, manual, returning
}

struct CameraState {
    var mode: CameraMode = .autoOrbit
    var orbitAngle: Float = 45.0
    var orbitSpeed: Float = 15.0
    var orbitRadius: Float = 25.0
    var orbitHeight: Float = 15.0
    var manualAngleH: Float = 0.0
    var manualAngleV: Float = 30.0
    var manualRadius: Float = 25.0
    var returnProgress: Float = 0.0
    var returnStartPos: SIMD3<Float> = .zero
    var returnTargetPos: SIMD3<Float> = .zero
    var fovDegrees: Float = 45.0
    var eye: SIMD3<Float> = .zero

    init() {
        let r = 45.0 * Float.pi / 180.0
        eye = SIMD3(cos(r) * orbitRadius, orbitHeight, sin(r) * orbitRadius)
    }
}

enum CameraSystem {
    static func update(camera: inout CameraState, dt: Float) {
        switch camera.mode {
        case .autoOrbit:
            camera.orbitAngle += camera.orbitSpeed * dt
            if camera.orbitAngle >= 360 { camera.orbitAngle -= 360 }
            let rad = camera.orbitAngle * .pi / 180
            camera.eye = SIMD3(cos(rad) * camera.orbitRadius, camera.orbitHeight, sin(rad) * camera.orbitRadius)

        case .manual:
            let radH = camera.manualAngleH * .pi / 180
            let radV = camera.manualAngleV * .pi / 180
            camera.eye = SIMD3(
                cos(radH) * cos(radV) * camera.manualRadius,
                sin(radV) * camera.manualRadius,
                sin(radH) * cos(radV) * camera.manualRadius
            )

        case .returning:
            camera.returnProgress += dt * 2.0
            if camera.returnProgress >= 1.0 {
                camera.returnProgress = 1.0
                camera.mode = .autoOrbit
            }
            let t = camera.returnProgress
            let eased = 1.0 - (1.0 - t) * (1.0 - t)

            camera.orbitAngle += camera.orbitSpeed * dt
            if camera.orbitAngle >= 360 { camera.orbitAngle -= 360 }
            let rad = camera.orbitAngle * .pi / 180
            camera.returnTargetPos = SIMD3(
                cos(rad) * camera.orbitRadius,
                camera.orbitHeight,
                sin(rad) * camera.orbitRadius
            )
            camera.eye = camera.returnStartPos + (camera.returnTargetPos - camera.returnStartPos) * eased
        }
    }
}
