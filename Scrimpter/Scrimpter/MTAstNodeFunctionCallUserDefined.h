//
//  MTAstNodeUserFunctionCall.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeFunctionCallUserDefined_h
#define MAD_MADScrimpter_MTAstNodeFunctionCallUserDefined_h

#import "MTAbstractSyntaxTree.h"
#import "MADSymbol.h"

@interface MTAstNodeFunctionCallUserDefined : MTAbstractSyntaxTree

@property (nonatomic, strong) MADSymbol *symbol;

@end

#endif
