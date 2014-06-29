//
//  MTAstNodeBoolValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeBoolValue : MTAbstractSyntaxTree

- (id)initWithBool:(bool)b;

@end
