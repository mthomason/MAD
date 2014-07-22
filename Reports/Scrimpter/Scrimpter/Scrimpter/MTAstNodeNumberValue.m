//
//  MTAstNodeNumberValue.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeNumberValue.h"
#import "MADValue.h"

@interface MTAstNodeNumberValue ()

@property (nonatomic, assign) double number;

@end

@implementation MTAstNodeNumberValue

- (id)initWithNumber:(double)number {
    self = [super initWithNodeType:SCNodeTypeNumberValue andValues:nil];
    if (self) {
        [self setNumber:number];
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
    return SCNodeTypeNumberValue;
}

- (MADValue *)evaluate {
    NSNumber *number = [NSNumber numberWithDouble:[self number]];
    return [MADValue value:number withType:SCVarableTypeDouble];
}

@end
