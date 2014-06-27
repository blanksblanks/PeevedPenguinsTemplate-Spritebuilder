//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Nina Baculinao on 6/26/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Penguin.h"

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode; // common name for drag&drop joint
    CCPhysicsJoint *_mouseJoint;
    // CCNode *_currentPenguin;
    Penguin *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
    // min speed to check if penguin is slow enough for round to end
    CCAction *_followPenguin;
}

static const float MIN_SPEED = 5.f;

// The following three methods activate touch handling, process touches and launch penguins

-(void)didLoadFromCCB{
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    
    // sign up as collision delegate of physics node
    _physicsNode.collisionDelegate = self;
    
    // debug drawing is a COOL feature that visualizes physics bodies and joints
    // saves you lots of time when you encounter issues with physics world setup
    _physicsNode.debugDraw = TRUE;
    // don't forget to declare each object!
    
    // nothing shall collide with our invisible node when we set collisionMask
    // to an empty array
    _pullbackNode.physicsBody.collisionMask = @[];

    // deactivate collisions from invisible node
    _mouseJointNode.physicsBody.collisionMask = @[];

}

// called on every touch in this scene
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
//    [self launchPenguin];
    
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    // when player starts touching catapult arm, start catapult dragging
    // i.e. we will create a springJoint bt mouseJointNode and the catapultArm
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation)){
        // whenever a touch moves, update mouseJointNode to the touch position
        _mouseJointNode.position = touchLocation;
        
        // setup a spring joint between the mouseJointNode and catapult
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness: 3000.f damping:150.f];
        
        // create a penguin from the ccb file
        _currentPenguin = (Penguin*)[CCBReader load:@"Penguin"];
        // (Penguin*) is needed because CCBReader only returns CCNodes
        // If "Penguin" file contains object of type Penguin you have to
        // cast as above
        
        // initially position it on the scoop. 34, 138 is the position in the node
        // initial position is relative to the catapult arm and translate position
        // to world coordinates
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        // convert world coordinates to the node space of _physicsNode because
        // that is where penguin is located
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        // add it to the physics node space
        [_physicsNode addChild:_currentPenguin];
        // we don't want the penguin to rotate in the scoop
        _currentPenguin.physicsBody.allowsRotation = FALSE;
        
        // create joint to keep penguin fixed to scoop until catapult releases
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
    }
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    // whenever touches move, update mouseJointNode position to touch position
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

- (void)releaseCatapult {
    
    if (_mouseJoint != nil){
        // releases the joint and lets the catapult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        // releases the joint and lets the penguin fly
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        
        // after snapping rotation is fine
        _currentPenguin.physicsBody.allowsRotation = TRUE;
        
        // follow the flying penguin
        // CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        // [_contentNode runAction:follow];
        
        // follow the flying penguin
        _followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguin];
        
        // set launched flag to TRUE
        _currentPenguin.launched = TRUE;
    }
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    // when touches end, i.e. when user releases finger, release catapult
    [self releaseCatapult];
}

- (void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
    // when touches are cancelled, i.e. when user drags finger off screen or
    // on something else, release catapult
    [self releaseCatapult];
}

- (void)launchPenguin {
    // loads the Penguin.ccb we have set up in Spritebuilder
    CCNode* penguin = [CCBReader load:@"Penguin"];
    // position the penguin at the bowl of the catapult
    penguin.position = ccpAdd(_catapultArm.position, ccp(16,50));
    
    //add the penguin to the physicsNode of this scene
    //(because it has physics enabled)
    [_physicsNode addChild:penguin];
    
    //manually create & apply a force to launch the penguin
    CGPoint launchDirection = ccp(1,0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
    
    // CCActionFollow implements camera that follows the penguin
    // ensure followed object is in visible area when starting
    self.position = ccp(0,0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];
    // Making contentNode perform action instead of Gameplay scene (self)
    // ensures that the retry button outside contentNode is always visible
    // because now the contentNode is scrolling not the complete Gameplay scene
    // since contentNode is only used to structure scene and has no content size
    // we still use bounding box of self to define world boundaries
}

- (void)retry {
    // reload this level
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)node{
//    CCLOG(@"Something collided with a seal!");
    
    float energy = [pair totalKineticEnergy];
    
    // if energy is large enough, remove the seal
    // first we retrieve the kientic energy of collision between seal and object
    // if energy is large enough we remove the seal
    // When we place the sealremoval handling code within a block using space
    // method of _physicsNode and call addPostStepBlock method, Cocos2D will
    // ensure that the code will only be run once per physics calculation, using
    // the KEY property. Cocos2D will only run one code block per key and frame.
    // So if collision handler is called thrice, we only call seal removal once.
    if (energy > 5000.f) {
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        } key:nodeA];
    }
}
         
-(void)sealRemoved:(CCNode *)seal {
    
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    // make the particle effect clean itself up once it's completed
    explosion.autoRemoveOnFinish = TRUE;
    // place the particle effect on the seal's position
    explosion.position = seal.position;
    // add the particle effect to the same node the seal is on
    [seal.parent addChild:explosion];
    
    //finally, remove the destroyed seal
    [seal removeFromParent];
}

// we use ccPLength function that calculates the square length of our velocity
// basically the x- and y-components of the speed combined
// we also check if penguin has exited level through left or right bound
// if any of this happens we call nextAttempt and return immediately
// to avoid multiple calls
- (void)update:(CCTime)delta
{
    // everything is executed only if the penguin has already launched
    if (_currentPenguin.launched) {
    
        // if speed is below minimum speed, assume this attempt is over
        if (ccpLength(_currentPenguin.physicsBody.velocity) < MIN_SPEED){
            [self nextAttempt];
            return;
        }
    
        int xMin = _currentPenguin.boundingBox.origin.x;
    
        if (xMin < self.boundingBox.origin.x) {
            [self nextAttempt];
            return;
        }
    
        int xMax = xMin + _currentPenguin.boundingBox.size.width;
    
        if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width)) {
            [self nextAttempt];
            return;
        }
    }
}

- (void)nextAttempt {
    _currentPenguin = nil; // reset ref to currentPenguin
    [_contentNode stopAction:_followPenguin]; // stop scrolling action
    
    // new action to scroll back to catapult
    CCActionMoveTo *actionMoveTo = [CCActionMoveTo actionWithDuration:1.f position:ccp(0, 0)];
    [_contentNode runAction:actionMoveTo];
}
    
@end
