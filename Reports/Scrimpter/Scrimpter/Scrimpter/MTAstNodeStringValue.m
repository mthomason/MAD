//
//  MTAstNodeStringValue.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeStringValue.h"
#import "MADValue.h"

@interface MTAstNodeStringValue ()

@property (nonatomic, strong) NSString *string;

@end

@implementation MTAstNodeStringValue

- (id)initWithString:(NSString *)string {
    self = [super initWithNodeType:SCNodeTypeStringValue andValues:nil];
    if (self) {
        NSString *s = [NSString stringWithString:string];
        [self setString:s];
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
    return SCNodeTypeStringValue;
}

- (MADValue *)evaluate {
    NSString *result = [NSString stringWithString:[self string]];
    return [MADValue value:result withType:SCVarableTypeString];
}

@end
