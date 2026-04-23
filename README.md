# MetalKit ECS

A 3D scene built on Apple's Metal GPU API using a custom Entity Component System (ECS) architecture.

<img width="900" height="632" alt="Screenshot 2026-04-23 at 12 33 24 AM" src="https://github.com/user-attachments/assets/c0ca4148-1f49-4098-9c25-3f672c08e841" />

## What It Is

Six rotating cubes — five colored outer cubes in a circular pattern, one larger central red cube — bouncing within a bounded space. A reference grid and wireframe bounding box are drawn as real line primitives. An auto-orbiting camera with drag-to-control and scroll-to-zoom completes the scene.

## Architecture

```
Components/     Pure data structs — position, velocity, rotation, bounce, renderable
ECS/            World: entity IDs and typed component dictionaries
Systems/        Free functions — movement, rotation, camera state machine
Entities/       Prefab factory functions
Renderer/       MTKViewDelegate, MSL shaders, mesh generation, matrix math
```

The ECS is plain Swift — no frameworks, no protocols required. Components are structs, systems are functions, entities are integers. The renderer asks the world for positions, rotations, and colors each frame, builds Metal draw calls, and hands everything to the GPU.

## Stack

- **MetalKit** — `MTKView` render loop
- **Metal** — GPU pipeline, command encoding, MSL shaders
- **simd** — vector and matrix math
- **SwiftUI + AppKit** — window, input (pan gesture, scroll wheel)

## What the GPU Actually Does

Everything visual goes through two shader pairs in `Shaders.metal`:

- `vertex_solid` / `fragment_solid` — transforms box geometry and applies Lambert diffuse lighting
- `vertex_line` / `fragment_line` — draws the grid and bounding box as unlit line primitives

The CPU runs the ECS, builds matrices, and records draw commands. The GPU executes the shaders.
