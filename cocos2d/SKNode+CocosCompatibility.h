//
//  SKNode+CocosCompatability.h
//  PCPlayer
//
//  Created by Cody Rayment on 2014-08-18.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "CCSpriteFrame.h"

@interface SKNode (CocosCompatibility)

@property (nonatomic, strong) id userObject;
@property (nonatomic, assign) CGFloat opacity;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign, readonly) CCPositionType positionType;
@property (nonatomic, assign, readonly) CCSizeType sizeType;
@property (nonatomic, assign, readonly) CCSizeType contentSizeType;
@property (nonatomic, assign, readonly) CCScaleType scaleType;
@property (nonatomic, assign) CGFloat scaleX;
@property (nonatomic, assign) CGFloat scaleY;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat skewX;
@property (nonatomic, assign) CGFloat skewY;
@property (nonatomic, assign) ccBlendFunc blendFunc;
@property (nonatomic, assign, readonly) BOOL flipX;
@property (nonatomic, assign, readonly) BOOL flipY;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) CGPoint anchorPoint;
@property (nonatomic, assign) CGSize size;

@end
