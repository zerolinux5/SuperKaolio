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
#import "SKTUtils.h"
#import "SKTAudio.h"

@interface GameLevelScene()
@property (nonatomic, strong) JSTileMap *map;
@property (nonatomic, strong) Player *player;
@property (nonatomic, assign) NSTimeInterval previousUpdateTime;
@property (nonatomic, strong) TMXLayer *walls;
@property (nonatomic, strong) TMXLayer *hazards;
@property (nonatomic, assign) BOOL gameOver;
@end

@implementation GameLevelScene

-(id)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
    [[SKTAudio sharedInstance] playBackgroundMusic:@"level1.mp3"];
    self.userInteractionEnabled = YES;
    /* Setup your scene here */
    self.backgroundColor = [SKColor colorWithRed:.4 green:.4 blue:.95 alpha:1.0];
    
    self.map = [JSTileMap mapNamed:@"level1.tmx"];
    [self addChild:self.map];
    
    self.walls = [self.map layerNamed:@"walls"];
    
    self.hazards = [self.map layerNamed:@"hazards"];
    
    self.player = [[Player alloc] initWithImageNamed:@"koalio_stand"];
    self.player.position = CGPointMake(100, 50);
    self.player.zPosition = 15;
    [self.map addChild:self.player];
    
  }
  return self;
}

-(CGRect)tileRectFromTileCoords:(CGPoint)tileCoords {
  float levelHeightInPixels = self.map.mapSize.height * self.map.tileSize.height;
  CGPoint origin = CGPointMake(tileCoords.x * self.map.tileSize.width, levelHeightInPixels - ((tileCoords.y + 1) * self.map.tileSize.height));
  return CGRectMake(origin.x, origin.y, self.map.tileSize.width, self.map.tileSize.height);
}

- (NSInteger)tileGIDAtTileCoord:(CGPoint)coord forLayer:(TMXLayer *)layer {
  TMXLayerInfo *layerInfo = layer.layerInfo;
  return [layerInfo tileGidAtCoord:coord];
}

//1
- (void)update:(NSTimeInterval)currentTime
{
  if (self.gameOver) return;
  
  [self setViewpointCenter:self.player.position];
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
  
  [self checkForAndResolveCollisionsForPlayer:self.player forLayer:self.walls];
  [self handleHazardCollisions:self.player];
  [self checkForWin];
}

- (void)checkForAndResolveCollisionsForPlayer:(Player *)player forLayer:(TMXLayer *)layer
{
  NSInteger indices[8] = {7, 1, 3, 5, 0, 2, 6, 8};
  player.onGround = NO;  ////Here
  for (NSUInteger i = 0; i < 8; i++) {
    NSInteger tileIndex = indices[i];
    
    CGRect playerRect = [player collisionBoundingBox];
    CGPoint playerCoord = [layer coordForPoint:player.desiredPosition];
    
    if (playerCoord.y >= self.map.mapSize.height - 1) {
      [self gameOver:0];
      return;
    }
    
    NSInteger tileColumn = tileIndex % 3;
    NSInteger tileRow = tileIndex / 3;
    CGPoint tileCoord = CGPointMake(playerCoord.x + (tileColumn - 1), playerCoord.y + (tileRow - 1));
    
    NSInteger gid = [self tileGIDAtTileCoord:tileCoord forLayer:layer];
    if (gid != 0) {
      CGRect tileRect = [self tileRectFromTileCoords:tileCoord];
      //NSLog(@"GID %ld, Tile Coord %@, Tile Rect %@, player rect %@", (long)gid, NSStringFromCGPoint(tileCoord), NSStringFromCGRect(tileRect), NSStringFromCGRect(playerRect));
      //1
      if (CGRectIntersectsRect(playerRect, tileRect)) {
        CGRect intersection = CGRectIntersection(playerRect, tileRect);
        //2
        if (tileIndex == 7) {
          //tile is directly below Koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y + intersection.size.height);
          player.velocity = CGPointMake(player.velocity.x, 0.0); ////Here
          player.onGround = YES; ////Here
        } else if (tileIndex == 1) {
          //tile is directly above Koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y - intersection.size.height);
        } else if (tileIndex == 3) {
          //tile is left of Koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x + intersection.size.width, player.desiredPosition.y);
        } else if (tileIndex == 5) {
          //tile is right of Koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x - intersection.size.width, player.desiredPosition.y);
          //3
        } else {
          if (intersection.size.width > intersection.size.height) {
            //tile is diagonal, but resolving collision vertically
            //4
            player.velocity = CGPointMake(player.velocity.x, 0.0); ////Here
            float intersectionHeight;
            if (tileIndex > 4) {
              intersectionHeight = intersection.size.height;
              player.onGround = YES; ////Here
            } else {
              intersectionHeight = -intersection.size.height;
            }
            player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y + intersection.size.height );
          } else {
            //tile is diagonal, but resolving horizontally
            float intersectionWidth;
            if (tileIndex == 6 || tileIndex == 0) {
              intersectionWidth = intersection.size.width;
            } else {
              intersectionWidth = -intersection.size.width;
            }
            //5
            player.desiredPosition = CGPointMake(player.desiredPosition.x  + intersectionWidth, player.desiredPosition.y);
          }
        }
      }
    }
  }
  //6
  player.position = player.desiredPosition;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  for (UITouch *touch in touches) {
    CGPoint touchLocation = [touch locationInNode:self];
    if (touchLocation.x > self.size.width / 2.0) {
      self.player.mightAsWellJump = YES;
    } else {
      self.player.forwardMarch = YES;
    }
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    
    float halfWidth = self.size.width / 2.0;
    CGPoint touchLocation = [touch locationInNode:self];
    
    //get previous touch and convert it to node space
    CGPoint previousTouchLocation = [touch previousLocationInNode:self];
    
    if (touchLocation.x > halfWidth && previousTouchLocation.x <= halfWidth) {
      self.player.forwardMarch = NO;
      self.player.mightAsWellJump = YES;
    } else if (previousTouchLocation.x > halfWidth && touchLocation.x <= halfWidth) {
      self.player.forwardMarch = YES;
      self.player.mightAsWellJump = NO;
    }
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  
  for (UITouch *touch in touches) {
    CGPoint touchLocation = [touch locationInNode:self];
    if (touchLocation.x < self.size.width / 2.0) {
      self.player.forwardMarch = NO;
    } else {
      self.player.mightAsWellJump = NO;
    }
  }
}

- (void)setViewpointCenter:(CGPoint)position {
  NSInteger x = MAX(position.x, self.size.width / 2);
  NSInteger y = MAX(position.y, self.size.height / 2);
  x = MIN(x, (self.map.mapSize.width * self.map.tileSize.width) - self.size.width / 2);
  y = MIN(y, (self.map.mapSize.height * self.map.tileSize.height) - self.size.height / 2);
  CGPoint actualPosition = CGPointMake(x, y);
  CGPoint centerOfView = CGPointMake(self.size.width/2, self.size.height/2);
  CGPoint viewPoint = CGPointSubtract(centerOfView, actualPosition);
  self.map.position = viewPoint;
}

- (void)handleHazardCollisions:(Player *)player
{
  if (self.gameOver) return;
  
  NSInteger indices[8] = {7, 1, 3, 5, 0, 2, 6, 8};
  
  for (NSUInteger i = 0; i < 8; i++) {
    NSInteger tileIndex = indices[i];
    
    CGRect playerRect = [player collisionBoundingBox];
    CGPoint playerCoord = [self.hazards coordForPoint:player.desiredPosition];
    
    NSInteger tileColumn = tileIndex % 3;
    NSInteger tileRow = tileIndex / 3;
    CGPoint tileCoord = CGPointMake(playerCoord.x + (tileColumn - 1), playerCoord.y + (tileRow - 1));
    
    NSInteger gid = [self tileGIDAtTileCoord:tileCoord forLayer:self.hazards];
    if (gid != 0) {
      CGRect tileRect = [self tileRectFromTileCoords:tileCoord];
      if (CGRectIntersectsRect(playerRect, tileRect)) {
        [self gameOver:0];
      }
    }
  }
}

-(void)gameOver:(BOOL)won {
  self.gameOver = YES;
  [self runAction:[SKAction playSoundFileNamed:@"hurt.wav" waitForCompletion:NO]];
  
  NSString *gameText;
  if (won) {
    gameText = @"You Won!";
  } else {
    gameText = @"You have Died!";
  }
  
  //3
  SKLabelNode *endGameLabel = [SKLabelNode labelNodeWithFontNamed:@"Marker Felt"];
  endGameLabel.text = gameText;
  endGameLabel.fontSize = 40;
  endGameLabel.position = CGPointMake(self.size.width / 2.0, self.size.height / 1.7);
  [self addChild:endGameLabel];
  
  //4
  UIButton *replay = [UIButton buttonWithType:UIButtonTypeCustom];
  replay.tag = 321;
  UIImage *replayImage = [UIImage imageNamed:@"replay"];
  [replay setImage:replayImage forState:UIControlStateNormal];
  [replay addTarget:self action:@selector(replay:) forControlEvents:UIControlEventTouchUpInside];
  replay.frame = CGRectMake(self.size.width / 2.0 - replayImage.size.width / 2.0, self.size.height / 2.0 - replayImage.size.height / 2.0, replayImage.size.width, replayImage.size.height);
  [self.view addSubview:replay];
}

- (void)replay:(id)sender
{
  //5
  [[self.view viewWithTag:321] removeFromSuperview];
  //6
  [self.view presentScene:[[GameLevelScene alloc] initWithSize:self.size]];
}

-(void)checkForWin {
  if (self.player.position.x > 3130.0) {
    [self gameOver:1];
  }
}


@end
