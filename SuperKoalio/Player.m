//
//  Player.m
//  SuperKoalio
//
//  Created by Jake Gundersen on 12/27/13.
//  Copyright (c) 2013 Razeware, LLC. All rights reserved.
//

#import "Player.h"
//1
#import "SKTUtils.h"

@implementation Player
//2
- (instancetype)initWithImageNamed:(NSString *)name {
    if (self == [super initWithImageNamed:name]) {
        self.velocity = CGPointMake(0.0, 0.0);
    }
    return self;
}

- (void)update:(NSTimeInterval)delta {
    //3
    CGPoint gravity = CGPointMake(0.0, -450.0);
    //4
    CGPoint gravityStep = CGPointMultiplyScalar(gravity, delta);
    //5
    self.velocity = CGPointAdd(self.velocity, gravityStep);
    CGPoint velocityStep = CGPointMultiplyScalar(self.velocity, delta);
    //6
    self.position = CGPointAdd(self.position, velocityStep);
}

@end