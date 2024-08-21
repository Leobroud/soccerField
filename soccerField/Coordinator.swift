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

struct PlayerModel {
    let id: Int
    let position: SIMD3<Float>
    let positionName: String
}


class Coordinator: NSObject, ARSessionDelegate {
    
    private var lastPanLocation: CGPoint = .zero
    
    var arView: ARView?
    
    let goalKeeperPosition = SIMD3<Float>(0, 0.005, -0.3) // Goleiro
    
    let playerPositions: [SIMD3<Float>] = [
                SIMD3<Float>(-0.15, 0.005, -0.15), // Zagueiro esquerdo
                SIMD3<Float>( 0.15, 0.005,  -0.15), // Zagueiro direito
                SIMD3<Float>(-0.05, 0.005,  -0.2), // Zagueiro central esquerdo
                SIMD3<Float>( 0.05, 0.005,  -0.2), // Zagueiro central direito
                SIMD3<Float>(-0.15, 0.005,  0.05), // Meio-campista esquerdo
                SIMD3<Float>(-0.05, 0.005,  -0.05), // Meio-campista direita
                SIMD3<Float>( 0.05, 0.005,  -0.05), // Meio-campista meio esquerda
                SIMD3<Float>( 0.15, 0.005,  0.05), // Meio-campista meio direita
                SIMD3<Float>( -0.08, 0.005, 0.2), // Atacante esquerdo
                SIMD3<Float>( 0.08, 0.005,  0.2), // Atacante central
            ]
    let playerPositionNames: [String] = [
                "Zagueiro esquerdo",
                "Zagueiro direito",
                "Zagueiro central esquerdo",
                "Zagueiro central direito",
                "Meio-campista esquerdo",
                "Meio-campista central esquerda",
                "Meio-campista central direita",
                "Meio-campista direita",
                "Atacante esquerdo",
                "Atacante direita"
            ]
    
    
    var fieldEntity: ModelEntity?
    var playersEntities: [(PlayerModel, ModelEntity)] = []
    
    func setup() {
        
        guard let arView = arView else { return }
        
        // Carregar o modelo do campo de futebol
        let anchor = AnchorEntity(plane: .horizontal)
        
        guard let fieldModelEntity = try? ModelEntity.loadModel(named: "soccer") else {
            fatalError("Erro to build modelEntity")
        }
        
        // Ajustar a escala do campo
        fieldModelEntity.scale = SIMD3<Float>(repeating: 0.004)
        
        // Adicionar o campo à âncora
        anchor.addChild(fieldModelEntity)
        fieldEntity = fieldModelEntity
        
        // Ajustar a escala do campo
        
        // Add goleiro
        guard let playerModelEntity = try? ModelEntity.loadModel(named: "flamengo_goleiro") else {
            fatalError("Erro to build modelEntity")
        }
        playerModelEntity.scale = SIMD3<Float>(repeating: 0.05)
        playerModelEntity.position = goalKeeperPosition
        fieldModelEntity.addChild(playerModelEntity, preservingWorldTransform: true)
        playersEntities.append((PlayerModel(id: 0, position: goalKeeperPosition, positionName: "Goleiro"), playerModelEntity))
        
        // Add Players
        for index in 0..<playerPositions.count {
            guard let playerModelEntity = try? ModelEntity.loadModel(named: "flamengo") else {
                fatalError("Erro to build modelEntity")
            }
            playerModelEntity.scale = SIMD3<Float>(repeating: 0.05)
            playerModelEntity.position = playerPositions[index]
            fieldModelEntity.addChild(playerModelEntity, preservingWorldTransform: true)
            playersEntities.append((PlayerModel(id: index+1, position: playerPositions[index], positionName: playerPositionNames[index]), playerModelEntity))
        }
        
        
        anchor.generateCollisionShapes(recursive: true)
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
                let rotation = simd_quatf(angle: deltaX, axis: [0, 0, 1])
                entity.transform.rotation *= rotation
            }
            
            lastPanLocation = currentPanLocation
        default:
            break
        }
    }
    
    @objc func touchModel(_ gesture: UITapGestureRecognizer) {
        guard let arView = gesture.view as? ARView else { return }
        let hit = arView.hitTest(gesture.location(in: gesture.view))
        
        if hit.count != 0 {
            if hit.first?.entity == fieldEntity {
                print("[debug] tocou no campo")
            } else {
                for player in playersEntities {
                    if hit.first?.entity == player.1 {
                        print("[debug] tocou no jogador ", player.0.id)
                        let material: Material = SimpleMaterial(color: .systemPink, isMetallic: true)
                        guard let cardModelEntity = try? ModelEntity(mesh: MeshResource.generateBox(size: 1.0), materials: [material]) else {
                            fatalError("Erro to build modelEntity")
                        }
                        
                        print("[debug] fieldEntity:", fieldEntity?.position)
                        
                        cardModelEntity.scale = SIMD3<Float>(repeating: 0.05)
                        cardModelEntity.position = goalKeeperPosition
                        fieldEntity?.addChild(cardModelEntity, preservingWorldTransform: true)
                        
                    }
                }
            }
        }
        
//        switch gesture.state {
//        case .began:
//            lastPanLocation = gesture.location(in: arView)
//        case .changed:
//            let currentPanLocation = gesture.location(in: arView)
//            let deltaX = Float(currentPanLocation.x - lastPanLocation.x) * 0.01 // Fator de rotação horizontal
//            
//            if let entity = arView.scene.anchors.first?.children.first {
//                let rotation = simd_quatf(angle: deltaX, axis: [0, 0, 0.5])
//                entity.transform.rotation *= rotation
//            }
//            
//            lastPanLocation = currentPanLocation
//        default:
//            break
//        }
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
