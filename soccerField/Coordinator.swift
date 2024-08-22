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
    let name: String
}


class Coordinator: NSObject, ARSessionDelegate {
    
    private var lastPanLocation: CGPoint = .zero
    
    var arView: ARView?
    
    let goleiro = PlayerModel(id: 0, position: SIMD3<Float>(0, 0.005, -0.3), positionName: "Goleiro", name: "Diego Alves")
    let players: [PlayerModel] = [
        PlayerModel(id: 1, position: SIMD3<Float>(-0.15, 0.005, -0.15), positionName: "Zagueiro esquerdo", name: "Ayrton Lucas"),
        PlayerModel(id: 2, position: SIMD3<Float>(0.15, 0.005, -0.15), positionName: "Zagueiro direito", name: "Varela"),
        PlayerModel(id: 3, position: SIMD3<Float>(-0.05, 0.005, -0.2), positionName: "Zagueiro central esquerdo", name: "Léo Pereira"),
        PlayerModel(id: 4, position: SIMD3<Float>(0.05, 0.005, -0.2), positionName: "Zagueiro central direito", name: "Fabricio Bruno"),
        PlayerModel(id: 5, position: SIMD3<Float>(-0.15, 0.005, 0.05), positionName: "Meio-campista esquerdo", name: "Cebolinha"),
        PlayerModel(id: 6, position: SIMD3<Float>(-0.05, 0.005, -0.05), positionName: "Meio-campista central esquerda", name: "De la Cruz"),
        PlayerModel(id: 7, position: SIMD3<Float>(0.05, 0.005, -0.05), positionName: "Meio-campista central direita", name: "Pulgar"),
        PlayerModel(id: 8, position: SIMD3<Float>(0.15, 0.005, 0.05), positionName: "Meio-campista direita", name: "Luiz Araújo"),
        PlayerModel(id: 9, position: SIMD3<Float>(-0.08, 0.005, 0.2), positionName: "Atacante esquerdo", name: "Pedro"),
        PlayerModel(id: 10, position: SIMD3<Float>(0.08, 0.005, 0.2), positionName: "Atacante central", name: "Arrascaeta")
    ]
    
    var lastCardEntity: ModelEntity?
    var fieldEntity: ModelEntity?
    var playersEntities: [(PlayerModel, ModelEntity)] = []
    var anchor: AnchorEntity?
    
    func setup() {
        
        guard let arView = arView else { return }
        
        // Carregar o modelo do campo de futebol
        self.anchor = AnchorEntity(plane: .horizontal)
        
        guard let fieldModelEntity = try? ModelEntity.loadModel(named: "soccer") else {
            fatalError("Erro to build modelEntity")
        }
        
        // Ajustar a escala do campo
        fieldModelEntity.scale = SIMD3<Float>(repeating: 0.004)
        
        // Adicionar o campo à âncora
        self.anchor?.addChild(fieldModelEntity)
        fieldEntity = fieldModelEntity
        
        guard let trophyEntity = try? ModelEntity.loadModel(named: "yourewinner") else {
            fatalError("Erro to build modelEntity")
        }
        
        // Ajustar a escala do campo
        trophyEntity.scale = SIMD3<Float>(repeating: 0.07)
        let rotation = simd_quatf(angle: -Float.pi/2, axis: SIMD3(x: 1, y: 0, z: 0))
        let position = SIMD3<Float>(0, 0.005, -0.6)
        trophyEntity.transform.rotation = rotation
        trophyEntity.position = position
        
        // Adicionar o campo à âncora
        self.anchor?.addChild(trophyEntity)
        
        // Add goleiro
        createPlayer(goleiro, field: fieldModelEntity)
        
        // Add Players
        for player in players {
            createPlayer(player, field: fieldModelEntity)
        }
        
        self.anchor?.generateCollisionShapes(recursive: true)
        // Adicionar a âncora à cena
        arView.scene.anchors.append(self.anchor ?? AnchorEntity(plane: .horizontal))
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
                lastCardEntity?.removeFromParent()
                lastCardEntity = nil
            } else {
                for player in playersEntities {
                    if hit.first?.entity == player.1 {
                        print("[debug] tocou no jogador ", player.0.id)
                        
                        lastCardEntity?.removeFromParent()
                        
                        let material: Material = SimpleMaterial(color: .systemPink, isMetallic: true)
                        guard let cardModelEntity = try? ModelEntity(mesh: MeshResource.generateBox(size: 1.0), materials: [material]) else {
                            fatalError("Erro ao construir o modelEntity")
                        }
                        
                        cardModelEntity.scale = SIMD3<Float>(repeating: 0.5)
                        cardModelEntity.position = SIMD3<Float>(-0.015, 0.03, 2.5)
                        
                        player.1.addChild(cardModelEntity, preservingWorldTransform: false)
                        
                        lastCardEntity = cardModelEntity
                    }
                }
            }
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

// MARK: Helpers
extension Coordinator {
    private func createPlayer(_ player: PlayerModel, field: ModelEntity) {
        guard let playerModelEntity = try? ModelEntity.loadModel(named: "flamengo") else {
            fatalError("Erro to build modelEntity")
        }
        playerModelEntity.scale = SIMD3<Float>(repeating: 0.05)
        playerModelEntity.position = player.position
        field.addChild(playerModelEntity, preservingWorldTransform: true)
        playersEntities.append((player, playerModelEntity))
        
        let material: Material = SimpleMaterial(color: .red, isMetallic: false)
        guard let cardModelEntity = try? ModelEntity(mesh: MeshResource.generateText(player.name, font: .systemFont(ofSize: 14), alignment: .center), materials: [material]) else {
            fatalError("Erro to build modelEntity")
        }
        
        cardModelEntity.scale = SIMD3<Float>(repeating: 0.0015)
        var position = player.position
        position.y = 0.01
        position.x -= 0.05
        cardModelEntity.position = position
        field.addChild(cardModelEntity, preservingWorldTransform: true)
    }
}
