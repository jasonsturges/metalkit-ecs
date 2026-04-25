//
//  MetalKit_ECSApp.swift
//  MetalKit ECS
//
//  Created by Jason Sturges on 4/22/26.
//

import Metal
import SwiftUI

@main
struct MetalKit_ECSApp: App {
    private let renderer = Renderer(device: MTLCreateSystemDefaultDevice()!)

    var body: some Scene {
        WindowGroup {
            ContentView(renderer: renderer)
        }
    }
}
