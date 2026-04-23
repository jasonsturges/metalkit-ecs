//
//  MetalKit_TestApp.swift
//  MetalKit Test
//
//  Created by Jason Sturges on 4/22/26.
//

import Metal
import SwiftUI

@main
struct MetalKit_TestApp: App {
    private let renderer = Renderer(device: MTLCreateSystemDefaultDevice()!)

    var body: some Scene {
        WindowGroup {
            ContentView(renderer: renderer)
        }
    }
}
