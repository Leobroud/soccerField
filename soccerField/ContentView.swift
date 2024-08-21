//
//  ContentView.swift
//  soccerField
//
//  Created by LEONARDO BARBOSA on 12/07/24.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        context.coordinator.arView = arView
        context.coordinator.setup()
        
        // Gestos para rotacionar e escalar
        let panGesture = UIPanGestureRecognizer(target: context.coordinator,
                                                action: #selector(context.coordinator.rotateModel(_:)))
        arView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator,
                                                    action: #selector(context.coordinator.scaleModel(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
