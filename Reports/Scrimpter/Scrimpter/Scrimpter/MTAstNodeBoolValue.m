//
//  MTAstNodeBoolValue.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeBoolValue.h"
#import "MADValue.h"

@interface MTAstNodeBoolValue ()

@property (nonatomic, assign) bool b;

@end

@implementation MTAstNodeBoolValue

- (id)initWithBool:(bool)b {
    self = [super initWithNodeType:SCNodeTypeBooleanValue andValues:nil];
    if (self) {
        [self setB: b];
    }
    return self;
}

- (MTTree *)rightNode {
    return nil;
}

- (MTTree *)leftNode {
    return nil;
}

- (SCNodeType)nodetype {
    return SCNodeTypeBooleanValue;
}

- (MADValue *)evaluate {
    NSNumber *result = [NSNumber numberWithBool: [self b]];
    return [MADValue value:result withType:SCVarableTypeBoolean];
}

@end
