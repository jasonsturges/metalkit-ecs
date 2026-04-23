import simd

enum MovementSystem {
    static func update(world: World, dt: Float) {
        for id in world.velocities.keys {
            guard var vel = world.velocities[id],
                  var pos = world.positions[id],
                  let bounce = world.bounces[id] else { continue }

            pos.value += vel.value * dt

            let b = bounce.boundary
            let h = bounce.halfSize

            if pos.value.x - h < -b || pos.value.x + h > b {
                vel.value.x *= -1
                pos.value.x = pos.value.x < 0 ? -b + h : b - h
            }
            if pos.value.y - h < -b || pos.value.y + h > b {
                vel.value.y *= -1
                pos.value.y = pos.value.y < 0 ? -b + h : b - h
            }
            if pos.value.z - h < -b || pos.value.z + h > b {
                vel.value.z *= -1
                pos.value.z = pos.value.z < 0 ? -b + h : b - h
            }

            world.positions[id] = pos
            world.velocities[id] = vel
        }
    }
}
