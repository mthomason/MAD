//
//  MTAbstractSyntaxTree.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"
#import "MTPair.h"
#import "MTAstNodeSymbolAsignNumber.h"
#import "MADValue.h"

@implementation MTAbstractSyntaxTree

- (id)initWithNodeType:(SCNodeType)type andValues:(MTPair *)values {
    self = [super initWithLeftTree:[values left] andRightTree:[values right]];
    if (self) {
        [self setNodetype:type];
    }
    return self;
}

- (MADValue *)evaluate {
    return [MADValue value:nil withType:SCVarableTypeNull];
}

@end
