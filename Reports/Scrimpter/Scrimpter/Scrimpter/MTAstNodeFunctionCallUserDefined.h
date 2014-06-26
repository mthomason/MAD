//
//  MTAstNodeUserFunctionCall.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"
#import "MADSymbol.h"

@interface MTAstNodeFunctionCallUserDefined : MTAbstractSyntaxTree

@property (nonatomic, strong) MADSymbol *symbol;

@end
