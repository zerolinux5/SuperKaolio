//
//  GameLevelScene.m
//  SuperKoalio
//
//  Created by Jake Gundersen on 12/27/13.
//  Copyright (c) 2013 Razeware, LLC. All rights reserved.
//

#import "GameLevelScene.h"
#import "JSTileMap.h"
#import "Player.h"

@interface GameLevelScene()
@property (nonatomic, strong) JSTileMap *map;
@property (nonatomic, strong) Player *player;
@property (nonatomic, assign) NSTimeInterval previousUpdateTime;
@end

@implementation GameLevelScene

-(id)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
    /* Setup your scene here */
    self.backgroundColor = [SKColor colorWithRed:.4 green:.4 blue:.95 alpha:1.0];
    
    self.map = [JSTileMap mapNamed:@"level1.tmx"];
    [self addChild:self.map];
    
    self.player = [[Player alloc] initWithImageNamed:@"koalio_stand"];
    self.player.position = CGPointMake(100, 50);
    self.player.zPosition = 15;
    [self.map addChild:self.player];
    
  }
  return self;
}

//1
- (void)update:(NSTimeInterval)currentTime
{
  //2
  NSTimeInterval delta = currentTime - self.previousUpdateTime;
  //3
  if (delta > 0.02) {
    delta = 0.02;
  }
  //4
  self.previousUpdateTime = currentTime;
  //5
  [self.player update:delta];
}


@end
