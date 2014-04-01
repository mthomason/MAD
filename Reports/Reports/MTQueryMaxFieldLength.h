//
//  MTQueryMaxFieldLength.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuery.h"

@interface MTQueryMaxFieldLength : MTQuery

- (NSString *)getSqlWithError:(NSError **)error;

@end
