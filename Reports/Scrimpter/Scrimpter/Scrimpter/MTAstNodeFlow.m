//
//  MTAstNodeFlow.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeFlow.h"
#import "MTAstNodeComparson.h"
#import "MADValue.h"

@interface MTAstNodeFlow ()

@property (nonatomic, assign) SCFlowType flowType;
@property (nonatomic, strong, readwrite) MTAbstractSyntaxTree *condition;

@end

@implementation MTAstNodeFlow

- (id)initConditionalWithIfList:(MTAbstractSyntaxTree *)iflist thenList:(MTAbstractSyntaxTree *)thenlist andCondition:(MTAbstractSyntaxTree *)condition {
    self = [super init];
    if (self) {
        [self setFlowType:SCFlowTypeIf];
        [self setLeftNode:iflist];
        [self setRightNode:thenlist];
        [self setCondition:condition];
    }
    return self;
}

- (id)initLoopWithList:(MTAbstractSyntaxTree *)list andCondition:(MTAstNodeComparson *)condition {
    self = [super init];
    if (self) {
        [self setFlowType:SCFlowTypeWhile];
        [self setLeftNode:list];
        [self setCondition:condition];
    }
    return self;
}

- (SCNodeType)nodetype {
    SCNodeType type;
    switch (self.flowType) {
        case SCFlowTypeIf:
            type = SCNodeTypeIf;
            break;
        case SCFlowTypeWhile:
            type = SCNodeTypeWhile;
            break;
        default:
            type = SCNodeTypeIf;
            NSAssert(false, @"Not set at %s", __PRETTY_FUNCTION__);
            break;
    }
    return type;
}

- (MADValue *)evaluate {
    MADValue *result;
    switch (self.flowType) {
        case SCFlowTypeIf: {
            
            MADValue *conditionValue = [[self condition] evaluate];
            BOOL condition = [[conditionValue value] boolValue];
            if (condition) {
                result = [[self leftNode] evaluate];
            } else {
                result = [[self rightNode] evaluate];
            }
            
            break;
        }
        case SCFlowTypeWhile: {
            
            
            MADValue *conditionValue = [[self condition] evaluate];
            BOOL condition = [[conditionValue value] boolValue];
            while (condition) {
                result = [[self leftNode] evaluate];
                conditionValue = [[self condition] evaluate];
                condition = [[conditionValue value] boolValue];
            }
            
            break;
        }
        default:
            NSAssert(false, @"Not set at %s", __PRETTY_FUNCTION__);
            break;
    }
    return result;
}

- (MTAbstractSyntaxTree *)thenList {
    return [self leftNode];
}

- (MTAbstractSyntaxTree *)elseList {
    return [self rightNode];
}

@end
