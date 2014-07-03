//
//  Player.h
//  SuperKoalio
//
//  Created by Jake Gundersen on 12/27/13.
//  Copyright (c) 2013 Razeware, LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Player : SKSpriteNode
@property (nonatomic, assign) CGPoint velocity;
- (void)update:(NSTimeInterval)delta;
@end
