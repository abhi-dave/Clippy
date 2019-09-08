//
//  AgentController.swift
//  Clippy macOS
//
//  Created by Devran on 07.09.19.
//  Copyright © 2019 Devran. All rights reserved.
//

import Cocoa
import AVKit
import SpriteKit

class AgentController {
    var isMuted = false
    var player: AVPlayer = {
        return AVPlayer()
    }()
    
    var agent: AgentCharacterDescription?
    var agentView: AgentView?
    
    var delegate: AgentControllerDelegate?
    
    init() {
    }
    
    convenience init(agentView: AgentView) {
        self.init()
        self.agentView = agentView
    }
    
    func run(name: String, withInitialAnimation animated: Bool = true) throws {
        print(name)
        guard let agent = AgentCharacterDescription(resourceName: name) else { return }
        delegate?.willRunAgent(agent: agent)
        self.agent = agent
        if animated, let animation = agent.findAnimation("Show") {
            play(animation: animation)
        } else {
            showInitialFrame()
        }
        delegate?.didRunAgent(agent: agent)
    }
    
    func audioActionForFrame(frame: AgentFrame) -> SKAction? {
        guard let agent = agent, let soundNumber = frame.soundNumber else { return nil }
        let soundURL = agent.basePath.appendingPathComponent("sounds").appendingPathComponent("\(agent.resourceName)_\(soundNumber).mp3")
        let action = SKAction.run {
            let playerItem = AVPlayerItem(url: soundURL)
            self.player.replaceCurrentItem(with: playerItem)
            self.player.play()
            self.player.volume = self.isMuted ? 0 : 1.0
        }
        return action
    }
    
    func animate() {
        guard let agent = agent else { return }
        let animation = agent.animations.randomElement()!
        play(animation: animation)
    }
    
    func showInitialFrame() {
        guard let agent = agent else { return }
        self.agentView?.agentSprite.texture = SKTexture(cgImage: try! agent.textureAtIndex(index: 0))
    }
    
    func play(animation: AgentAnimation, withSoundEnabled soundEnabled: Bool = true) {
        guard let agent = agent else { return }
        print(animation.name)
        
        DispatchQueue.global(qos: .background).async {
            var actions: [SKAction] = []
            
            for frame in animation.frames {
                if soundEnabled, let audioAction = self.audioActionForFrame(frame: frame) {
                    actions.append(audioAction)
                }
                
                let textures = [SKTexture(cgImage: agent.imageForFrame(frame))]
                let action = SKAction.animate(with: textures, timePerFrame: frame.durationInSeconds)
                actions.append(action)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.agentView?.agentSprite.removeAllActions()
                self.agentView?.agentSprite.run(SKAction.sequence(actions))
            })
        }
    }
}
