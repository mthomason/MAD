//
//  MTAstNodeNumberValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeNumberValue_h
#define MAD_MADScrimpter_MTAstNodeNumberValue_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeNumberValue : MTAbstractSyntaxTree

//@property (nonatomic, strong, readonly) NSNumber *number;

- (id)initWithNumber:(NSNumber *)number;

@end

#endif
