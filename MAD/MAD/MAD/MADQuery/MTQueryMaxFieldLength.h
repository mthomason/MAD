//
//  MTQueryMaxFieldLength.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryMaxFieldLength_h
#define Reports_MTQueryMaxFieldLength_h

#import "MTQuery.h"

@interface MTQueryMaxFieldLength : MTQuery

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error;

@end

#endif
