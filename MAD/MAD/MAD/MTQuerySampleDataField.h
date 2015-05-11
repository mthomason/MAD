//
//  MTQuerySampleDataField.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuerySampleDataField_h
#define Reports_MTQuerySampleDataField_h

#import "MTQuery.h"

@interface MTQuerySampleDataField : MTQuery

- (NSString *)getSqlWithError:(NSError **)error;

@end

#endif
