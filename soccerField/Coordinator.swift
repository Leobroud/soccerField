//
//  Coordinator.swift
//  soccerField
//
//  Created by LEONARDO BARBOSA on 12/07/24.
//

import Foundation
import ARKit
import RealityKit
import Combine
import UIKit

class Coordinator: NSObject, ARSessionDelegate {
    
    private var lastPanLocation: CGPoint = .zero
    
    var arView: ARView?
    
    func setup() {
        
        guard let arView = arView else { return }
        
        // Carregar o modelo do campo de futebol
        let anchor = AnchorEntity(plane: .horizontal)
        
        guard let modelEntity = try? ModelEntity.load(named: "soccer") else {
            fatalError("Erro to build modelEntity")
        }
        
        // Ajustar a escala do campo
        modelEntity.scale = SIMD3<Float>(repeating: 0.004)
        
        // Adicionar o campo à âncora
        anchor.addChild(modelEntity)
        
        // Adicionar a âncora à cena
        arView.scene.anchors.append(anchor)
    }
    
    @objc func rotateModel(_ gesture: UIPanGestureRecognizer) {
        guard let arView = gesture.view as? ARView else { return }
        
        switch gesture.state {
        case .began:
            lastPanLocation = gesture.location(in: arView)
        case .changed:
            let currentPanLocation = gesture.location(in: arView)
            let deltaX = Float(currentPanLocation.x - lastPanLocation.x) * 0.01 // Fator de rotação horizontal
            
            if let entity = arView.scene.anchors.first?.children.first {
                let rotation = simd_quatf(angle: deltaX, axis: [0, 0, 0.5])
                entity.transform.rotation *= rotation
            }
            
            lastPanLocation = currentPanLocation
        default:
            break
        }
    }
    
    @objc func scaleModel(_ gesture: UIPinchGestureRecognizer) {
        guard let arView = gesture.view as? ARView else { return }
        guard gesture.numberOfTouches == 2 else { return }
        
        switch gesture.state {
        case .changed:
            let scale = gesture.scale
            if let entity = arView.scene.anchors.first?.children.first {
                entity.scale *= SIMD3<Float>(repeating: Float(scale))
            }
            gesture.scale = 1.0 // Reset the scale gesture
        default:
            break
        }
    }
}
