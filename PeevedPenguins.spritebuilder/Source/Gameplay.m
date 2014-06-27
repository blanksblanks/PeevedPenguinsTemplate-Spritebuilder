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
}

// called on every touch in this scene
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    [self launchPenguin];
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
