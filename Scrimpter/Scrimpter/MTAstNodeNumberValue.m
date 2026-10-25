//
//  MTAstNodeNumberValue.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTAstNodeNumberValue.h"
#import "MADValue.h"

@interface MTAstNodeNumberValue ()

@end

@implementation MTAstNodeNumberValue

- (instancetype)initWithNumber:(NSNumber *)number {
    MTPair *pair = [[MTPair alloc] initWithLeft:number andRight:nil];
    self = [super initWithNodeType:SCNodeTypeNumberValue andValues:pair];
    if (self) { }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeNumberValue;
}

- (MADValue *)evaluate {
    return [MADValue value:self.leftNode withType:SCVarableTypeDouble];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"********* MTAstNodeNumberValue *********\n"];
    [description appendFormat:@"%@", self.leftNode];
    [description appendFormat:@"*********"];
    return description;
}

@end
