//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Nina Baculinao on 6/26/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode; // common name for drag&drop joint
    CCPhysicsJoint *_mouseJoint;
}

// The following three methods activate touch handling, process touches and launch penguins

-(void)didLoadFromCCB{
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    
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
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0,0) anchorB:ccp(34, 138) restLength:0.f stiffness: 3000.f damping:150.f];
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


    
    
@end
