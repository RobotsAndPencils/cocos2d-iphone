/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2012 Zynga Inc.
 * Copyright (c) 2013 Apportable Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBAnimationManager.h"
#import "CCBSequence.h"
#import "CCBSequenceProperty.h"
#import "CCBReader.h"
#import "CCBKeyframe.h"
#import "OALSimpleAudio.h"
#import <objc/runtime.h>

#import "CCBReader_Private.h"

#import "SKNode+CocosCompatibility.h"
#import "SKTTimingFunctions.h"

static NSInteger ccbAnimationManagerID = 0;

@implementation CCBAnimationManager

@synthesize sequences;
@synthesize autoPlaySequenceId;
@synthesize rootNode;
@synthesize rootContainerSize;
@synthesize owner;
@synthesize delegate;
@synthesize lastCompletedSequenceName;

- (id)init {
    self = [super init];
    if (!self)
        return NULL;

    animationManagerId = ccbAnimationManagerID;
    ccbAnimationManagerID++;

    sequences = [[NSMutableArray alloc] init];
    nodeSequences = [[NSMutableDictionary alloc] init];
    baseValues = [[NSMutableDictionary alloc] init];

    return self;
}

- (CGSize)containerSize:(SKNode *)node {
    if (node)
        return node.contentSize;
    else
        return rootContainerSize;
}

- (void)addNode:(SKNode *)node andSequences:(NSDictionary *)seq {
    NSValue *nodePtr = [NSValue valueWithPointer:(__bridge const void *)(node)];
    [nodeSequences setObject:seq forKey:nodePtr];
}

- (void)moveAnimationsFromNode:(SKNode *)fromNode toNode:(SKNode *)toNode {
    NSValue *fromNodePtr = [NSValue valueWithPointer:(__bridge const void *)(fromNode)];
    NSValue *toNodePtr = [NSValue valueWithPointer:(__bridge const void *)(toNode)];

    // Move base values
    id baseValue = [baseValues objectForKey:fromNodePtr];
    if (baseValue) {
        [baseValues setObject:baseValue forKey:toNodePtr];
        [baseValues removeObjectForKey:fromNodePtr];
    }

    // Move keyframes
    NSDictionary *seqs = [nodeSequences objectForKey:fromNodePtr];
    if (seqs) {
        [nodeSequences setObject:seqs forKey:toNodePtr];
        [nodeSequences removeObjectForKey:fromNodePtr];
    }
}

- (void)setBaseValue:(id)value forNode:(SKNode *)node propertyName:(NSString *)propName {
    NSValue *nodePtr = [NSValue valueWithPointer:(__bridge const void *)(node)];

    NSMutableDictionary *props = [baseValues objectForKey:nodePtr];
    if (!props) {
        props = [NSMutableDictionary dictionary];
        [baseValues setObject:props forKey:nodePtr];
    }

    [props setObject:value forKey:propName];
}

- (id)baseValueForNode:(SKNode *)node propertyName:(NSString *)propName {
    NSValue *nodePtr = [NSValue valueWithPointer:(__bridge const void *)(node)];

    NSMutableDictionary *props = [baseValues objectForKey:nodePtr];
    return [props objectForKey:propName];
}

- (int)sequenceIdForSequenceNamed:(NSString *)name {
    for (CCBSequence *seq in sequences) {
        if ([seq.name isEqualToString:name]) {
            return seq.sequenceId;
        }
    }
    return -1;
}

- (CCBSequence *)sequenceFromSequenceId:(int)seqId {
    for (CCBSequence *seq in sequences) {
        if (seq.sequenceId == seqId)
            return seq;
    }
    return NULL;
}

- (SKAction *)actionFromKeyframe0:(CCBKeyframe *)kf0 andKeyframe1:(CCBKeyframe *)kf1 propertyName:(NSString *)name node:(SKNode *)node {
    float duration = kf1.time - kf0.time;

    if ([name isEqualToString:@"rotation"]) {
        return [SKAction rotateToAngle:[kf1.value floatValue] duration:duration];
    } else if ([name isEqualToString:@"opacity"]) {
        return [SKAction fadeAlphaTo:[kf1.value intValue] duration:duration];
    } else if ([name isEqualToString:@"color"]) {
        CCColor *color = kf1.value;
        return [SKAction colorizeWithColor:[color UIColor] colorBlendFactor:1 duration:duration];
    } else if ([name isEqualToString:@"visible"]) {
        if ([kf1.value boolValue]) {
            return [SKAction sequence:@[ [SKAction waitForDuration:duration], [SKAction unhide] ]];
        } else {
            return [SKAction sequence:@[ [SKAction waitForDuration:duration], [SKAction hide] ]];
        }
    } else if ([name isEqualToString:@"spriteFrame"]) {
        return [SKAction sequence:@[ [SKAction waitForDuration:duration], [SKAction setTexture:kf1.value resize:YES] ]];
    } else if ([name isEqualToString:@"position"]) {
        // Get position type
        //int type = [[[self baseValueForNode:node propertyName:name] objectAtIndex:2] intValue];

        id value = kf1.value;

        // Get relative position
        float x = [[value objectAtIndex:0] floatValue];
        float y = [[value objectAtIndex:1] floatValue];

        //CGSize containerSize = [self containerSize:node.parent];

        //CGPoint absPos = [node absolutePositionFromRelative:ccp(x,y) type:type parentSize:containerSize propertyName:name];

        return [SKAction moveTo:CGPointMake(x, y) duration:duration];
    } else if ([name isEqualToString:@"scale"]) {
        // Get position type
        //int type = [[[self baseValueForNode:node propertyName:name] objectAtIndex:2] intValue];

        id value = kf1.value;

        // Get relative scale
        float x = [[value objectAtIndex:0] floatValue];
        float y = [[value objectAtIndex:1] floatValue];

        return [SKAction scaleXTo:x y:y duration:duration];
    } else {
        NSLog(@"CCBReader: Failed to create animation for property: %@", name);
    }
    return NULL;
}

- (void)setAnimatedProperty:(NSString *)name forNode:(SKNode *)node toValue:(id)value tweenDuration:(float)tweenDuration {
    if (tweenDuration > 0) {
        // Create a fake keyframe to generate the action from
        CCBKeyframe *kf1 = [[CCBKeyframe alloc] init];
        kf1.value = value;
        kf1.time = tweenDuration;
        kf1.easingType = kCCBKeyframeEasingLinear;

        // Animate
        SKAction *action = [self actionFromKeyframe0:nil andKeyframe1:kf1 propertyName:name node:node];
        [node runAction:action];
    } else {
        // Just set the value

        if ([name isEqualToString:@"position"]) {
            // Get position type
            //int type = [[[self baseValueForNode:node propertyName:name] objectAtIndex:2] intValue];

            // Get relative position
            float x = [[value objectAtIndex:0] floatValue];
            float y = [[value objectAtIndex:1] floatValue];
#ifdef __CC_PLATFORM_IOS
            [node setValue:[NSValue valueWithCGPoint:ccp(x, y)] forKey:name];
#elif defined(__CC_PLATFORM_MAC)
            [node setValue:[NSValue valueWithPoint:ccp(x, y)] forKey:name];
#endif

            //[node setRelativePosition:ccp(x,y) type:type parentSize:[self containerSize:node.parent] propertyName:name];
        } else if ([name isEqualToString:@"scale"]) {
            // Get scale type
            //int type = [[[self baseValueForNode:node propertyName:name] objectAtIndex:2] intValue];

            // Get relative scale
            float x = [[value objectAtIndex:0] floatValue];
            float y = [[value objectAtIndex:1] floatValue];

            [node setValue:[NSNumber numberWithFloat:x] forKey:[name stringByAppendingString:@"X"]];
            [node setValue:[NSNumber numberWithFloat:y] forKey:[name stringByAppendingString:@"Y"]];

            //[node setRelativeScaleX:x Y:y type:type propertyName:name];
        } else if ([name isEqualToString:@"skew"]) {
            node.skewX = [[value objectAtIndex:0] floatValue];
            node.skewY = [[value objectAtIndex:1] floatValue];
        } else {
            [node setValue:value forKey:name];
        }
    }
}

- (void)setFirstFrameForNode:(SKNode *)node sequenceProperty:(CCBSequenceProperty *)seqProp tweenDuration:(float)tweenDuration {
    NSArray *keyframes = [seqProp keyframes];

    if (keyframes.count == 0) {
        // Use base value (no animation)
        /**
         RNP: We are disabling this. It resets all values to a base value at the start of a timeline. Even if that property isn't being animated in the timeline. We don't want this.
         **/
        // id baseValue = [self baseValueForNode:node propertyName:seqProp.name];
        // NSAssert1(baseValue, @"No baseValue found for property (%@)", seqProp.name);
        // [self setAnimatedProperty:seqProp.name forNode:node toValue:baseValue tweenDuration:tweenDuration];
    } else {
        // Use first keyframe
        CCBKeyframe *keyframe = [keyframes objectAtIndex:0];
        [self setAnimatedProperty:seqProp.name forNode:node toValue:keyframe.value tweenDuration:tweenDuration];
    }
}

- (void)easeAction:(SKAction *)action easingType:(int)easingType easingOpt:(float)easingOpt {
    if (easingType == kCCBKeyframeEasingLinear) {
        action.timingMode = SKActionTimingLinear;
    } else if (easingType == kCCBKeyframeEasingInstant) {
        [action setTimingFunction:^float(float p) {
            if (p < 1) {
                return 0;
            }
            return 1;
        }];
    } else if (easingType == kCCBKeyframeEasingCubicIn) {
        action.timingMode = SKActionTimingEaseIn;
    } else if (easingType == kCCBKeyframeEasingCubicOut) {
        action.timingMode = SKActionTimingEaseOut;
    } else if (easingType == kCCBKeyframeEasingCubicInOut) {
        action.timingMode = SKActionTimingEaseInEaseOut;
    } else if (easingType == kCCBKeyframeEasingBackIn) {
        action.timingFunction = SKTTimingFunctionBackEaseIn;
    } else if (easingType == kCCBKeyframeEasingBackOut) {
        action.timingFunction = SKTTimingFunctionBackEaseOut;
    } else if (easingType == kCCBKeyframeEasingBackInOut) {
        action.timingFunction = SKTTimingFunctionBackEaseInOut;
    } else if (easingType == kCCBKeyframeEasingBounceIn) {
        action.timingFunction = SKTTimingFunctionBounceEaseIn;
    } else if (easingType == kCCBKeyframeEasingBounceOut) {
        action.timingFunction = SKTTimingFunctionBounceEaseOut;
    } else if (easingType == kCCBKeyframeEasingBounceInOut) {
        action.timingFunction = SKTTimingFunctionBounceEaseInOut;
    } else if (easingType == kCCBKeyframeEasingElasticIn) {
        action.timingFunction = SKTTimingFunctionElasticEaseIn;
    } else if (easingType == kCCBKeyframeEasingElasticOut) {
        action.timingFunction = SKTTimingFunctionElasticEaseOut;
    } else if (easingType == kCCBKeyframeEasingElasticInOut) {
        action.timingFunction = SKTTimingFunctionElasticEaseInOut;
    } else {
        NSLog(@"CCBReader: Unkown easing type %d", easingType);
    }
}

- (void)runActionsForNode:(SKNode *)node sequenceProperty:(CCBSequenceProperty *)seqProp tweenDuration:(float)tweenDuration {
    NSArray *keyframes = [seqProp keyframes];
    int numKeyframes = (int)keyframes.count;

    if (numKeyframes > 1) {
        // Make an animation!
        NSMutableArray *actions = [NSMutableArray array];

        CCBKeyframe *keyframeFirst = [keyframes objectAtIndex:0];
        float timeFirst = keyframeFirst.time + tweenDuration;

        if (timeFirst > 0) {
            [actions addObject:[SKAction waitForDuration:timeFirst]];
        }

        for (int i = 0; i < numKeyframes - 1; i++) {
            CCBKeyframe *kf0 = [keyframes objectAtIndex:i];
            CCBKeyframe *kf1 = [keyframes objectAtIndex:i + 1];

            SKAction *action = [self actionFromKeyframe0:kf0 andKeyframe1:kf1 propertyName:seqProp.name node:node];
            if (action) {
                // Apply easing
                [self easeAction:action easingType:kf0.easingType easingOpt:kf0.easingOpt];

                [actions addObject:action];
            }
        }

        SKAction *seq = [SKAction sequence:actions];
        [node runAction:seq];
    }
}

- (SKAction *)actionForCallbackChannel:(CCBSequenceProperty *)channel {
    float lastKeyframeTime = 0;

    NSMutableArray *actions = [NSMutableArray array];

    for (CCBKeyframe *keyframe in channel.keyframes) {
        float timeSinceLastKeyframe = keyframe.time - lastKeyframeTime;
        lastKeyframeTime = keyframe.time;
        if (timeSinceLastKeyframe > 0) {
            [actions addObject:[SKAction waitForDuration:timeSinceLastKeyframe]];
        }

        NSString *selectorName = [keyframe.value objectAtIndex:0];
        int selectorTarget = [[keyframe.value objectAtIndex:1] intValue];

        // Callback through obj-c
        id target = NULL;
        if (selectorTarget == kCCBTargetTypeDocumentRoot)
            target = self.rootNode;
        else if (selectorTarget == kCCBTargetTypeOwner)
            target = owner;

        SEL selector = NSSelectorFromString(selectorName);

        if (target && selector) {
            [actions addObject:[SKAction performSelector:selector onTarget:target]];
        }
    }

    if (!actions.count) return nil;

    return [SKAction sequence:actions];
}

- (SKAction *)actionForSoundChannel:(CCBSequenceProperty *)channel {
    float lastKeyframeTime = 0;

    NSMutableArray *actions = [NSMutableArray array];

    for (CCBKeyframe *keyframe in channel.keyframes) {
        float timeSinceLastKeyframe = keyframe.time - lastKeyframeTime;
        lastKeyframeTime = keyframe.time;
        if (timeSinceLastKeyframe > 0) {
            [actions addObject:[SKAction waitForDuration:timeSinceLastKeyframe]];
        }

        NSString *soundFile = [keyframe.value objectAtIndex:0];
        float pitch = [[keyframe.value objectAtIndex:1] floatValue];
        float pan = [[keyframe.value objectAtIndex:2] floatValue];
        float gain = [[keyframe.value objectAtIndex:3] floatValue];
        [actions addObject:[SKAction runBlock:^{
            [[OALSimpleAudio sharedInstance] playEffect:soundFile volume:gain pitch:pitch pan:pan loop:NO];
                           }]];
    }

    if (!actions.count) return nil;

    return [SKAction sequence:actions];
}

- (void)runAnimationsForSequenceId:(int)seqId tweenDuration:(float)tweenDuration {
    NSAssert(seqId != -1, @"Sequence id %d couldn't be found", seqId);

    for (NSValue *nodePtr in nodeSequences) {
        SKNode *node = [nodePtr pointerValue];

        NSDictionary *seqs = [nodeSequences objectForKey:nodePtr];
        NSDictionary *seqNodeProps = [seqs objectForKey:[NSNumber numberWithInt:seqId]];

        NSMutableSet *seqNodePropNames = [NSMutableSet set];

        // Reset nodes that have sequence node properties, and run actions on them
        for (NSString *propName in seqNodeProps) {
            CCBSequenceProperty *seqProp = [seqNodeProps objectForKey:propName];
            [seqNodePropNames addObject:propName];

            [self setFirstFrameForNode:node sequenceProperty:seqProp tweenDuration:tweenDuration];
            [self runActionsForNode:node sequenceProperty:seqProp tweenDuration:tweenDuration];
        }

        /** RNP: Don't reset base values! **/
        /*
        // Reset the nodes that may have been changed by other timelines
        NSDictionary* nodeBaseValues = [baseValues objectForKey:nodePtr];
        for (NSString* propName in nodeBaseValues)
        {
            if (![seqNodePropNames containsObject:propName])
            {
                id value = [nodeBaseValues objectForKey:propName];
                
                if (value)
                {
                    [self setAnimatedProperty:propName forNode:node toValue:value tweenDuration:tweenDuration];
                }
            }
        }*/
    }

    // Make callback at end of sequence
    CCBSequence *seq = [self sequenceFromSequenceId:seqId];
    __weak CCBAnimationManager *weakSelf = self;
    SKAction *sequenceCompleteAction = [SKAction runBlock:^{
        [weakSelf sequenceCompleted:seq.sequenceId];
    }];

    SKAction *completeAction = [SKAction sequence:@[ [SKAction waitForDuration:seq.duration + tweenDuration], sequenceCompleteAction ]];
    [rootNode runAction:completeAction];

    // Playback callbacks and sounds
    if (seq.callbackChannel) {
        // Build sound actions for channel
        SKAction *action = [self actionForCallbackChannel:seq.callbackChannel];
        if (action) {
            [self.rootNode runAction:action];
        }
    }

    if (seq.soundChannel) {
        // Build sound actions for channel
        SKAction *action = [self actionForSoundChannel:seq.soundChannel];
        if (action) {
            [self.rootNode runAction:action];
        }
    }

    // Set the running scene
    runningSequence = [self sequenceFromSequenceId:seqId];
}

- (void)runAnimationsForSequenceNamed:(NSString *)name tweenDuration:(float)tweenDuration {
    int seqId = [self sequenceIdForSequenceNamed:name];
    [self runAnimationsForSequenceId:seqId tweenDuration:tweenDuration];
}

- (void)runAnimationsForSequenceNamed:(NSString *)name {
    [self runAnimationsForSequenceNamed:name tweenDuration:0];
}

- (void)sequenceCompleted:(NSInteger)seqId {
    // Play next sequence
    NSPredicate *sequenceIdPredicate = [NSPredicate predicateWithFormat:@"sequenceId == %d", seqId];
    NSArray *sequenceListWithId = [self.sequences filteredArrayUsingPredicate:sequenceIdPredicate];

    if ([sequenceListWithId count] == 0)
        return;
    CCBSequence *completedSequence = [sequenceListWithId firstObject];
    int nextSeqId = completedSequence.chainedSequenceId;
    runningSequence = nil;
    lastCompletedSequenceName = completedSequence.name;

    // Callbacks
    [delegate completedAnimationSequenceNamed:lastCompletedSequenceName];
    if (block)
        block(self);

    // Run next sequence if callbacks did not start a new sequence
    if (nextSeqId != -1) {
        [self runAnimationsForSequenceId:nextSeqId tweenDuration:0];
    }
}

- (NSString *)runningSequenceName {
    return runningSequence.name;
}

- (void)dealloc {
    self.rootNode = NULL;
}

@end
