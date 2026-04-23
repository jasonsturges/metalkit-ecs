import simd

typealias EntityID = UInt64

final class World {
    private var nextID: EntityID = 0

    var positions:      [EntityID: PositionComponent]      = [:]
    var velocities:     [EntityID: VelocityComponent]      = [:]
    var rotations:      [EntityID: RotationComponent]      = [:]
    var rotationSpeeds: [EntityID: RotationSpeedComponent] = [:]
    var bounces:        [EntityID: BounceComponent]        = [:]
    var renderables:    [EntityID: RenderableComponent]    = [:]

    func createEntity() -> EntityID {
        let id = nextID
        nextID += 1
        return id
    }
}
