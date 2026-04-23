import simd

enum RotationSystem {
    static func update(world: World, dt: Float) {
        for id in world.rotationSpeeds.keys {
            guard let speed = world.rotationSpeeds[id],
                  var rot = world.rotations[id] else { continue }

            let dRot = simd_quatf(angle: speed.x * dt * .pi / 180, axis: [1, 0, 0])
                     * simd_quatf(angle: speed.y * dt * .pi / 180, axis: [0, 1, 0])
                     * simd_quatf(angle: speed.z * dt * .pi / 180, axis: [0, 0, 1])

            rot.value = simd_normalize(rot.value * dRot)
            world.rotations[id] = rot
        }
    }
}
