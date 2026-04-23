import simd

func makeRotatingObject(
    world: World,
    position: SIMD3<Float>,
    velocity: SIMD3<Float>,
    rotationSpeed: SIMD3<Float>,
    size: Float,
    color: SIMD4<Float>
) {
    let id = world.createEntity()
    world.positions[id]      = PositionComponent(value: position)
    world.velocities[id]     = VelocityComponent(value: velocity)
    world.rotations[id]      = RotationComponent()
    world.rotationSpeeds[id] = RotationSpeedComponent(x: rotationSpeed.x, y: rotationSpeed.y, z: rotationSpeed.z)
    world.bounces[id]        = BounceComponent(boundary: 10.0, halfSize: size / 2.0)
    world.renderables[id]    = RenderableComponent(color: color, scale: size)
}
