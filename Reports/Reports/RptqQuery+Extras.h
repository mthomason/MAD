//
//  RptqQuery+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuery.h"
#import "RptqDatabase.h"
#import "MNSDatabase.h"

@interface RptqQuery (Extras)

+ (NSString *)getSqlForQuery:(RptqQuery *)query;

+ (void)cacheQueryForDatabase:(RptqDatabase *)database progress:(void (^)(NSNumber *percentage))progress completion:(void (^)(BOOL success))completion;

@end