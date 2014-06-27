//
//  Seal.m
//  PeevedPenguins
//
//  Created by Nina Baculinao on 6/25/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Seal.h"

@implementation Seal

//- (id) init {
//    self = [super init];
//    
//    if (self) {
//        CCLOG(@"Seal created");
//    }
//    
//    return self;
//}

-(void)didLoadFromCCB{
    self.physicsBody.collisionType = @"seal";
}
    
@end
