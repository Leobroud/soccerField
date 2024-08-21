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
    
    let playerPositions: [SIMD3<Float>] = [
                SIMD3<Float>(0, 0.02, -0.3), // Goleiro
                SIMD3<Float>(-0.15, 0.02, -0.15), // Zagueiro esquerdo
                SIMD3<Float>( 0.15, 0.02,  -0.15), // Zagueiro direito
                SIMD3<Float>(-0.05, 0.02,  -0.2), // Zagueiro central esquerdo
                SIMD3<Float>( 0.05, 0.02,  -0.2), // Zagueiro central direito
                SIMD3<Float>(-0.15, 0.02,  0.05), // Meio-campista esquerdo
                SIMD3<Float>(-0.05, 0.02,  -0.05), // Meio-campista direita
                SIMD3<Float>( 0.05, 0.02,  -0.05), // Meio-campista meio esquerda
                SIMD3<Float>( 0.15, 0.02,  0.05), // Meio-campista meio direita
                SIMD3<Float>( -0.08, 0.02, 0.2), // Atacante esquerdo
                SIMD3<Float>( 0.08, 0.02,  0.2), // Atacante central
            ]
    
    func setup() {
        
        guard let arView = arView else { return }
        
        print("[debug] will create anchor")
        // Carregar o modelo do campo de futebol
        let anchor = AnchorEntity(plane: .horizontal)
        
        print("[debug] will create model")
        guard let fieldModelEntity = try? ModelEntity.load(named: "soccer") else {
            fatalError("Erro to build modelEntity")
        }
        
        // Ajustar a escala do campo
        fieldModelEntity.scale = SIMD3<Float>(repeating: 0.004)
        
        print("[debug] will create model")
        guard let dollModelEntity = try? ModelEntity.load(named: "flamengo") else {
            fatalError("Erro to build modelEntity")
        }
        
//        let rotation = simd_quatf(angle: -Float.pi/2, axis: SIMD3(x: 1, y: 0, z: 0))
//        dollModelEntity.transform.rotation *= rotation
        
        
        // Adicionar o campo à âncora
        anchor.addChild(fieldModelEntity)
        
        // Ajustar a escala do campo
        
        for position in playerPositions {
            print("[debug] will create model")
            guard let dollModelEntity = try? ModelEntity.load(named: "flamengo") else {
                fatalError("Erro to build modelEntity")
            }
            dollModelEntity.scale = SIMD3<Float>(repeating: 0.05)
            
            print("[debug] size", fieldModelEntity.transform.scale)
            dollModelEntity.position = position
            
            print("[debug] fieldAnchor: ", fieldModelEntity.anchor)
            anchor.addChild(dollModelEntity)
        }
        
        
        
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
