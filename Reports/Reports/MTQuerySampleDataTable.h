//
//  MTQuerySampleDataTable.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuery.h"

@interface MTQuerySampleDataTable : MTQuery

- (NSString *)getSqlWithError:(NSError **)error;

@end
