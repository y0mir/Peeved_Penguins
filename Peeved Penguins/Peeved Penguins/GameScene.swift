//
//  GameScene.swift
//  Peeved Penguins
//
//  Created by Ethan on 6/22/17.
//  Copyright © 2017 Ethan. All rights reserved.
//

import SpriteKit

/*  func - clamp
    This function takes in any comparable of Type T for value, lower, and upper.
    It returns a Type T that is the maximum value between the value and the lower value, 
    and the minimum value between that and the upper value.
    In short this function can take in any type, including CGFloat! */

func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
}

extension CGVector {
    public func length() -> CGFloat {
        return CGFloat(sqrt(dx*dx + dy*dy))
    }
}



class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /*Game object connections */
    var catapultArm: SKSpriteNode!
    var catapult: SKSpriteNode!
    var cantileverNode: SKSpriteNode!
    var touchNode: SKSpriteNode!
    
    

    /* Physics helper */
    var touchJoint: SKPhysicsJointSpring?
    var penguinJoint: SKPhysicsJointPin?
    
    /* Define a var to hold camera */
    var cameraNode: SKCameraNode!
    
    /* Add an optional camera target */
    var cameraTarget: SKSpriteNode?
    
    /* Declare a var for buttonRestart */
    var buttonRestart: MSButtonNode!
    
    override func didMove(to view: SKView) {
        /* Reference to catapultArm node*/
        catapultArm = childNode(withName: "catapultArm") as! SKSpriteNode
        
        /* Reference to catapult node */
        catapult = childNode(withName: "catapult") as! SKSpriteNode
        
        /* Reference to cantileverNode node */
        cantileverNode = childNode(withName: "cantileverNode") as! SKSpriteNode
        
        /* Reference to touchNode */
        touchNode = childNode(withName: "touchNode") as! SKSpriteNode
        
        /* Create a new camera */
        cameraNode = childNode(withName: "cameraNode") as! SKCameraNode
        self.camera = cameraNode
        
        /* Reference to buttonRestart node don't quite understand*/
        buttonRestart = childNode(withName: "//buttonRestart") as! MSButtonNode
        
        /* Reset the game when buttonRestart is tapped */
        buttonRestart.selectedHandler = {
            guard let scene = GameScene.level(1) else {
                print("Level 1 is missing?")
                    return
            }
            scene.scaleMode = .aspectFit
            view.presentScene(scene)
            
        }
        
        /* Call setupCatapult func */
        setupCatapult()
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        
    }
    
    /* Implementing a delegate method - method that will inform you of any valid collision contacts. */
    func didBegin(_ contact: SKPhysicsContact) {
        /* Physics contact delegate implementation */
        /* Get references to the bodies involved in the collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        /* Get references to the physics body parent SKSpriteNode */
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        /* Check if either physics bodies was a seal */
        if contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2 {
            /* if the collision was more than a gentle nudge, remove seal! */
            if contact.collisionImpulse > 2.0 {
                if contactA.categoryBitMask == 2 { removeSeal(node: nodeA) }
                if contactB.categoryBitMask == 2 { removeSeal(node: nodeB) }
            }
            
        }
    }

    
    /* Remove seal method */
    func removeSeal(node:SKNode) {
        /* Load our particle effect */
        let particles = SKEmitterNode(fileNamed: "Poof")!
        /* Position particles at the Seal node, this will need to be node.convert
         (node.position, to: self), not node.position */
        particles.position = node.position
        
        /* Play SFX */
        let sound = SKAction.playSoundFileNamed("sfx_seal", waitForCompletion: false)
        self.run(sound)
        
        /* Add particles to scene */
        addChild(particles)
        let wait = SKAction.wait(forDuration: 2)
        let removeParticles = SKAction.removeFromParent()
        let seq = SKAction.sequence([wait, removeParticles])
        particles.run(seq)
        
        /* Seal death! */
        
        
        /* Create our hero death action */
        let sealDeath = SKAction.run({
            /* Remove seal node from the scene */
            node.removeFromParent()
        })
       
        
        self.run(sealDeath)
        
        
     
    }
    
    /* checkPenguin function - checks when a penguin has come to a stop */
    func checkPenguin() {
        guard let cameraTarget = cameraTarget else {
            return
        }
        
        /* check penguin has come to rest */
        if cameraTarget.physicsBody!.joints.count == 0 && cameraTarget.physicsBody!.velocity.length() < 0.18 {
            resetCamera()
        }
        
        if cameraTarget.position.y < -200{
            cameraTarget.removeFromParent()
            resetCamera()
        }
        
    }
    
    

    
    /* resetCamera function - when a penguin comes to rest or goes off the screen reset the camera! */
    func resetCamera() {
        /* Reset camera */
        let cameraReset = SKAction.move(to: CGPoint(x:0, y:camera!.position.y), duration: 1.5)
        let cameraDelay = SKAction.wait(forDuration: 0.5)
        let cameraSequence = SKAction.sequence([cameraDelay,cameraReset])
        cameraNode.run(cameraSequence)
        cameraTarget = nil
    }


    func setupCatapult(){
        /* Pint joint */
        var pinLocation = catapultArm.position
        pinLocation.x += -10
        pinLocation.y += -70
        let catapultJoint = SKPhysicsJointPin.joint(
            withBodyA: catapult.physicsBody!,
            bodyB: catapultArm.physicsBody!,
            anchor: pinLocation)
        physicsWorld.add(catapultJoint)

        /* Spring joint catapult arm and cantilever node */
        var anchorAPosition = catapultArm.position
        anchorAPosition.x += 0
        anchorAPosition.y += 50
        let catapultSpringJoint = SKPhysicsJointSpring.joint (withBodyA: catapultArm.physicsBody!, bodyB: cantileverNode.physicsBody!, anchorA: anchorAPosition, anchorB: cantileverNode.position)
        physicsWorld.add(catapultSpringJoint)
        catapultSpringJoint.frequency = 6
        catapultSpringJoint.damping = 0.5

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        // Make a Penguin
//        let penguin = Penguin()
//        
//        // Add the penguin to this scene
//        addChild(penguin)
//        
//        /* move penguin to the catapult bucket area */
//        penguin.position.x = catapultArm.position.x + 32
//        penguin.position.y = catapultArm.position.y + 50
//        
//        /* Impulse vector */
//        let launchImpulse = CGVector(dx: 200, dy: 0)
//        
//        /* Apply impulse to penguin */
//        
//        penguin.physicsBody?.applyImpulse(launchImpulse)
//        
//        cameraTarget = penguin
        /* Called when a touch begins */
        
        let touch = touches.first!                  // Get the first touch
        let location = touch.location(in: self)     // Find the location of that touch in this view
        let nodeAtPoint = atPoint(location)         // Find the node at that location
        if nodeAtPoint.name == "catapultArm" {      // If the touched node is named "catapultArm" do...
            touchNode.position = location
            touchJoint = SKPhysicsJointSpring.joint(
                withBodyA: touchNode.physicsBody!,
                bodyB: catapultArm.physicsBody!,
                anchorA: location,
                anchorB: location)
            physicsWorld.add(touchJoint!)
            
            let penguin = Penguin()
            addChild(penguin)
            penguin.position.x += catapultArm.position.x + 20
            penguin.position.y += catapultArm.position.y + 50
            penguin.physicsBody?.usesPreciseCollisionDetection = true
            penguinJoint = SKPhysicsJointPin.joint(withBodyA: catapultArm.physicsBody!,
                                                   bodyB: penguin.physicsBody!,
                                                   anchor: penguin.position)
            
            physicsWorld.add(penguinJoint!)
            cameraTarget = penguin
            
        }
        
    
    }
    
    /* override the touchesMoved function - allows the catapult arm to be drawn back */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        touchNode.position = location
    }
    
    /* Don't quite understand this method - but I assume it works based on if the touch ends to stop holding back the catapult*/
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchJoint = touchJoint {
            physicsWorld.remove(touchJoint)
        }
        
        // Check for a touchJoint then remove it
        if let touchJoint = touchJoint {
            physicsWorld.remove(touchJoint)
        }
        
        // Check for a penguin joint then remove it
        if let penguinJoint = penguinJoint {
            physicsWorld.remove(penguinJoint)
        }
        
        // Check if the penguin is the cameraTarget
        guard let penguin = cameraTarget else {
            return
        }
        
        // Generate a vector and a force based on the angle of the arm.
        let force: CGFloat = 350
        let r = catapultArm.zRotation
        let dx = cos(r) * force
        let dy = sin(r) * force
        // Apply an impulse at vector
        let v = CGVector(dx: dx, dy: dy)
        penguin.physicsBody?.applyImpulse(v)
              
        
    }

    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        moveCamera()
        checkPenguin()
    }
    
    /* Make a class method to load levels */
    class func level(_ levelNumber: Int) -> GameScene? {
        guard let scene = GameScene(fileNamed: "Level_\(levelNumber)") else {
            return nil
        }
        scene.scaleMode = .aspectFit
        return scene
        
    }
    
    
    /* Make the camera follow the camera target. */
    func moveCamera() {
        guard let cameraTarget = cameraTarget else {
            return
        }
        let targetX = cameraTarget.position.x
        let x = clamp(value: targetX, lower: 0, upper: 392)
        cameraNode.position.x = x
    }
    
    
    
    
}


